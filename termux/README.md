# CIVOPS-Radar Termux Module

This module contains the core scanning functionality for CIVOPS-Radar, designed to run in the Termux environment on Android devices.

## Files

- `radar_prototype.sh` - Main scanning script
- `install.sh` - One-command installation script
- `README.md` - This documentation

## Quick Start

### Prerequisites

1. **Termux Installation**
   - Install Termux from F-Droid (not Google Play)
   - Update packages: `pkg update && pkg upgrade`

2. **Required Packages**
   ```bash
   pkg install termux-api python sqlite git
   ```

3. **Permissions**
   - Grant location permission for Wi-Fi scanning
   - Grant storage permission for data export

### Installation

```bash
# Clone the repository
git clone https://github.com/your-username/CIVOPS-Radar.git
cd CIVOPS-Radar

# Run the installer
bash termux/install.sh
```

### Usage

```bash
# Navigate to radar directory
cd /data/data/com.termux/files/home/radar

# Start scanning
./radar_prototype.sh scan

# View statistics
./radar_prototype.sh stats

# Export data
./radar_prototype.sh export json

# Start web interface
python server/app.py
```

## Scanner Script (`radar_prototype.sh`)

### Features

- **Passive Scanning**: Uses `termux-wifi-scaninfo` for non-intrusive scanning
- **Configurable Intervals**: Adjustable scan frequency (default: 5 seconds)
- **Signal Analysis**: RSSI-based distance estimation
- **Risk Assessment**: Automated security scoring
- **Data Persistence**: SQLite database storage
- **Graceful Handling**: Manages Android throttling and errors

### Command Line Options

```bash
./radar_prototype.sh [command] [options]

Commands:
  scan     - Start continuous scanning (default)
  export   - Export data (json|csv)
  stats    - Show current statistics
  init     - Initialize database only
```

### Configuration

Edit the script to modify default settings:

```bash
# Configuration section
RADAR_DIR="/data/data/com.termux/files/home/radar"
SCAN_INTERVAL=5  # seconds between scans
MAX_SCANS=1000   # maximum scans to keep
```

### Output

The scanner creates several files:

- `data/scans.db` - SQLite database with scan results
- `scan.log` - Scanner activity log
- `exports/` - Exported data files

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

The scanner uses the log-distance path loss model to estimate distance from signal strength:

```python
def calculate_distance(rssi, frequency=2400):
    if rssi == 0:
        return 999.0
    
    # Free space path loss model
    tx_power = 20  # dBm
    path_loss = tx_power - rssi
    
    if path_loss <= 0:
        return 0.1
    
    # Convert to distance
    distance = 10 ** ((path_loss - 32.45 - 20 * 3.38) / 20)
    return max(0.1, min(999.0, distance))
```

### Risk Scoring

Networks are scored based on multiple factors:

- **Open Networks**: +30 points
- **Hidden SSIDs**: +20 points
- **Weak Encryption**: +5-25 points
- **Suspicious SSIDs**: +10-30 points
- **Signal Fluctuation**: +8-15 points
- **Proximity Risk**: +5-10 points

## Troubleshooting

### Common Issues

#### Scanner Not Working
```bash
# Check Termux:API installation
termux-wifi-scaninfo

# Verify permissions
termux-setup-storage

# Check Wi-Fi status
termux-wifi-scaninfo
```

#### No Networks Detected
- Ensure Wi-Fi is enabled
- Check location permissions
- Verify Termux:API is installed
- Try increasing scan interval

#### Database Errors
```bash
# Check database file
ls -la /data/data/com.termux/files/home/radar/data/

# Recreate database
rm /data/data/com.termux/files/home/radar/data/scans.db
./radar_prototype.sh init
```

#### Performance Issues
- Reduce scan frequency
- Clean old data: `./radar_prototype.sh cleanup`
- Check available storage space

### Debug Mode

Enable debug logging:

```bash
export RADAR_DEBUG=1
./radar_prototype.sh scan
```

### Log Files

- `scan.log` - Scanner activity
- `error.log` - Error messages
- `debug.log` - Debug information (if enabled)

## Security Considerations

### Permissions

The scanner requires:
- **Location Access**: Required for Wi-Fi scanning
- **Storage Access**: For data export
- **No Root Required**: Works within Android security model

### Data Privacy

- All data stored locally
- No cloud synchronization
- No telemetry or analytics
- User controls all data

### Legal Compliance

- **Authorized Use Only**: Scan only networks you own or have permission to test
- **Passive Scanning**: No network disruption or interference
- **Local Storage**: No data transmission to external servers

## Performance Optimization

### Scan Frequency

Adjust scan interval based on needs:

```bash
# High frequency (more data, more battery)
SCAN_INTERVAL=3

# Low frequency (less data, better battery)
SCAN_INTERVAL=10
```

### Database Maintenance

```bash
# Clean old data
sqlite3 /data/data/com.termux/files/home/radar/data/scans.db "DELETE FROM scans WHERE timestamp < datetime('now', '-1 hour');"

# Optimize database
sqlite3 /data/data/com.termux/files/home/radar/data/scans.db "VACUUM;"
```

### Memory Usage

Monitor memory usage:

```bash
# Check memory usage
ps aux | grep radar

# Monitor database size
du -h /data/data/com.termux/files/home/radar/data/scans.db
```

## Advanced Usage

### Custom Scan Scripts

Create custom scanning scripts:

```bash
#!/bin/bash
# Custom scan with specific parameters
export SCAN_INTERVAL=10
export MAX_SCANS=500
./radar_prototype.sh scan
```

### Data Analysis

Query the database directly:

```bash
# Get all networks
sqlite3 /data/data/com.termux/files/home/radar/data/scans.db "SELECT * FROM scans;"

# Get high-risk networks
sqlite3 /data/data/com.termux/files/home/radar/data/scans.db "SELECT * FROM scans WHERE risk_score > 50;"

# Get open networks
sqlite3 /data/data/com.termux/files/home/radar/data/scans.db "SELECT * FROM scans WHERE is_open = 1;"
```

### Export Formats

Export data in different formats:

```bash
# JSON export
./radar_prototype.sh export json

# CSV export
./radar_prototype.sh export csv

# Custom export
sqlite3 -json /data/data/com.termux/files/home/radar/data/scans.db "SELECT * FROM scans;" > custom_export.json
```

## Integration

### Web Interface

Start the web interface:

```bash
cd /data/data/com.termux/files/home/radar
python server/app.py
```

Access at: `http://localhost:5000`

### API Access

Use the REST API for programmatic access:

```bash
# Get latest signals
curl http://localhost:5000/api/signals

# Get statistics
curl http://localhost:5000/api/statistics

# Export data
curl http://localhost:5000/api/export/json
```

## Future Enhancements

### Planned Features

- GPS integration for mapping
- Advanced threat detection
- Machine learning analysis
- Multi-device synchronization
- Real-time alerts

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

- Follow POSIX shell standards
- Use meaningful variable names
- Add comprehensive comments
- Test on multiple devices
- Update documentation

### Testing

```bash
# Test scanner
bash termux/test_scanner.sh

# Test with sample data
python server/test_replay.py

# Run full test suite
bash tests/run_tests.sh
```

## Support

### Getting Help

- **GitHub Issues**: [Project Issues](https://github.com/your-username/CIVOPS-Radar/issues)
- **Documentation**: [Project Docs](https://github.com/your-username/CIVOPS-Radar/docs)
- **Community**: [GitHub Discussions](https://github.com/your-username/CIVOPS-Radar/discussions)

### Reporting Bugs

When reporting bugs, include:

- Android version
- Termux version
- Error messages
- Log files
- Steps to reproduce

### Feature Requests

For feature requests, include:

- Use case description
- Expected behavior
- Implementation suggestions
- Priority level

## License

This module is licensed under the MIT License. See the main project LICENSE file for details.

---

**Happy scanning! 🛰️**
