# CIVOPS-Radar Technical Documentation

## Architecture Overview

CIVOPS-Radar is built as a modular, offline-first Wi-Fi scanning and visualization system. The architecture consists of several interconnected components that work together to provide comprehensive network analysis capabilities.

### System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Termux API    │    │   Flask Server  │    │   Web Browser   │
│   (Wi-Fi Scan)  │───▶│   (Backend)     │◀───│   (Frontend)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   SQLite DB     │    │   Risk Engine   │    │   HTML5 Canvas  │
│   (Data Store)  │    │   (Analysis)    │    │   (Visualization)│
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Core Components

### 1. Termux Scanner (`termux/radar_prototype.sh`)

**Purpose**: Passive Wi-Fi network scanning using Android's built-in capabilities.

**Key Features**:
- Uses `termux-wifi-scaninfo` for non-intrusive scanning
- Configurable scan intervals (default: 5 seconds)
- Graceful handling of Android throttling
- SQLite data persistence
- Signal strength analysis
- Distance estimation

**Technical Details**:
- **Language**: Bash + Python
- **Dependencies**: Termux:API, SQLite3, Python 3.8+
- **Permissions**: Location access (required for Wi-Fi scanning)
- **Data Format**: JSON output from Termux:API

**Scan Process**:
1. Call `termux-wifi-scaninfo`
2. Parse JSON output
3. Calculate distance from RSSI
4. Assess risk factors
5. Store in SQLite database
6. Update radar display

### 2. Flask Web Server (`server/app.py`)

**Purpose**: RESTful API and web interface for radar visualization.

**Key Features**:
- Real-time data API endpoints
- WebSocket support for live updates
- Data export functionality
- Network statistics
- Historical data analysis

**API Endpoints**:
- `GET /api/signals` - Latest scan results
- `GET /api/statistics` - Scan statistics
- `GET /api/export/<format>` - Data export
- `GET /api/network/<bssid>` - Network details
- `POST /api/scan/start` - Start scanning
- `POST /api/scan/stop` - Stop scanning

**Technical Details**:
- **Language**: Python 3.8+
- **Framework**: Flask with CORS support
- **Database**: SQLite3 with connection pooling
- **Threading**: Multi-threaded for concurrent requests

### 3. Risk Engine (`server/risk_engine.py`)

**Purpose**: Advanced risk assessment and threat analysis.

**Risk Factors**:
- **Open Networks**: +30 points (high risk)
- **Hidden SSIDs**: +20 points (medium risk)
- **Weak Encryption**: +5-25 points (based on type)
- **Suspicious SSIDs**: +10-30 points (pattern matching)
- **Signal Fluctuation**: +8-15 points (rogue AP detection)
- **Proximity Risk**: +5-10 points (signal strength analysis)
- **Vendor Risk**: +5 points (known vulnerable vendors)
- **Beacon Anomalies**: +10-15 points (unusual frequencies)
- **Temporal Risk**: +5 points (unusual access times)

**Algorithm**:
```python
def calculate_risk_score(network, historical_data):
    factors = RiskFactors()
    
    # Basic security assessment
    factors.open_network = assess_open_network(network)
    factors.hidden_ssid = assess_hidden_ssid(network)
    factors.weak_encryption = assess_encryption_strength(network)
    
    # Advanced threat detection
    if historical_data:
        factors.signal_fluctuation = assess_signal_fluctuation(network, historical_data)
        factors.temporal_risk = assess_temporal_patterns(network, historical_data)
    
    return min(100, sum(factors.values()))
```

### 4. Radar Visualization (`server/templates/radar.html`)

**Purpose**: Real-time radar display using HTML5 Canvas.

**Visualization Features**:
- Circular radar display with range rings
- Network positioning based on signal strength
- Color-coded risk levels
- Interactive network information
- Real-time updates every 3 seconds

**Technical Implementation**:
- **Frontend**: HTML5 Canvas + JavaScript
- **Styling**: TailwindCSS with dark theme
- **Updates**: AJAX polling every 3 seconds
- **Responsive**: Mobile-friendly design

**Radar Positioning Algorithm**:
```javascript
function calculateRadarPosition(bssid, level, distance) {
    // Use BSSID hash for consistent angle
    const hashVal = hash(bssid) % 360;
    const angle = hashVal * Math.PI / 180;
    
    // Calculate position based on signal strength
    const maxDistance = 200; // meters
    const normalizedDistance = Math.min(distance / maxDistance, 1.0);
    const radius = (1 - normalizedDistance) * 0.8; // 80% of radar radius
    
    return {
        x: radius * Math.cos(angle),
        y: radius * Math.sin(angle),
        angle: hashVal,
        radius: radius
    };
}
```

## Database Schema

### Scans Table
```sql
CREATE TABLE scans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    bssid TEXT NOT NULL,
    ssid TEXT,
    capabilities TEXT,
    frequency INTEGER,
    level INTEGER,
    distance REAL,
    risk_score INTEGER DEFAULT 0,
    is_hidden BOOLEAN DEFAULT 0,
    is_open BOOLEAN DEFAULT 0,
    vendor TEXT,
    first_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
    scan_count INTEGER DEFAULT 1
);
```

### Indexes
```sql
CREATE INDEX idx_bssid ON scans(bssid);
CREATE INDEX idx_timestamp ON scans(timestamp);
CREATE INDEX idx_level ON scans(level);
```

## Signal Processing

### Distance Calculation
Uses the log-distance path loss model:

```
Distance = 10^((TxPower - RSSI - 32.45 - 20*log10(frequency)) / 20)
```

Where:
- `TxPower`: Transmit power (default: 20 dBm)
- `RSSI`: Received signal strength indicator
- `frequency`: Channel frequency in MHz
- `32.45`: Free space path loss constant

### Signal Strength Analysis
- **Excellent**: > -30 dBm (very close)
- **Good**: -30 to -50 dBm (close)
- **Fair**: -50 to -70 dBm (moderate)
- **Poor**: -70 to -80 dBm (far)
- **Very Poor**: < -80 dBm (very far)

## Security Considerations

### Data Privacy
- All data stored locally on device
- No cloud synchronization
- No telemetry or analytics
- User controls all data

### Network Security
- Passive scanning only (no packet injection)
- No password cracking attempts
- No network disruption
- Read-only operations

### Code Security
- Open source and auditable
- No hidden functionality
- Regular security updates
- Community review process

## Performance Optimization

### Database Optimization
- Indexed queries for fast lookups
- Automatic cleanup of old data
- Connection pooling
- Query optimization

### Memory Management
- Streaming data processing
- Garbage collection optimization
- Memory leak prevention
- Resource cleanup

### Network Optimization
- Efficient data structures
- Minimal API calls
- Caching strategies
- Compression where appropriate

## Deployment

### Termux Environment
1. Install Termux from F-Droid
2. Install Termux:API
3. Run installation script
4. Grant required permissions

### Linux Desktop
1. Install Python 3.8+
2. Install required packages
3. Run Flask server
4. Access web interface

### Docker (Future)
```dockerfile
FROM python:3.11-slim
COPY . /app
WORKDIR /app
RUN pip install -r requirements.txt
EXPOSE 5000
CMD ["python", "server/app.py"]
```

## Troubleshooting

### Common Issues

#### Scanner Not Working
- Check Termux:API installation
- Verify location permissions
- Ensure Wi-Fi is enabled
- Check for Android throttling

#### Web Interface Not Loading
- Verify Flask server is running
- Check port 5000 is available
- Ensure firewall allows connections
- Verify database exists

#### Performance Issues
- Check available memory
- Monitor CPU usage
- Optimize database queries
- Reduce scan frequency

### Debug Mode
```bash
# Enable debug logging
export RADAR_DEBUG=1
python server/app.py --debug

# Check logs
tail -f /data/data/com.termux/files/home/radar/scan.log
```

## Future Enhancements

### Planned Features
- GPS integration for mapping
- Multi-device synchronization
- Advanced threat detection
- Machine learning analysis
- Mobile app (Kotlin)

### Technical Roadmap
- **v2.0**: GPS mapping and trilateration
- **v3.0**: Machine learning threat detection
- **v4.0**: Native Android app
- **v5.0**: Multi-device mesh network

## Contributing

### Development Setup
1. Fork the repository
2. Create feature branch
3. Make changes
4. Test thoroughly
5. Submit pull request

### Code Standards
- Follow PEP 8 for Python
- Use meaningful variable names
- Add comprehensive comments
- Write unit tests
- Update documentation

### Testing
```bash
# Run tests
python -m pytest tests/

# Test risk engine
python server/test_risk_engine.py

# Test scanner
bash termux/test_scanner.sh
```

## License

This project is licensed under the MIT License. See LICENSE file for details.

---

**For technical support, please open an issue on GitHub or contact the development team.**
