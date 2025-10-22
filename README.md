# CIVOPS-Radar

**Offline-First Recon Radar Tool for Ethical Wi-Fi Scanning**

CIVOPS-Radar is an open-source, privacy-focused alternative to commercial closed-source "civil-ops" scanning tools. Built for Android + Termux, it provides passive Wi-Fi scanning, signal analysis, and radar visualization while maintaining complete offline operation.

## ⚠️ LEGAL DISCLAIMER

**This tool is intended for network diagnostics and authorized wireless environment testing only. Unauthorized use on private or restricted networks is illegal. Users are responsible for ensuring they have proper authorization before scanning any network.**

## Features

- 🔍 **Passive Wi-Fi Scanning** - Uses Termux:API for non-intrusive network detection
- 📡 **Live Radar Visualization** - HTML5 Canvas-based circular radar display
- 📊 **Signal Analysis** - RSSI-based distance estimation and signal strength tracking
- 🛡️ **Risk Assessment** - Automated scoring of detected networks based on security factors
- 💾 **Local Storage** - SQLite database with no cloud dependencies
- 📤 **Export Options** - JSON, CSV, and KML format support
- 🌐 **Offline-First** - Complete operation without internet connection
- 📱 **Cross-Platform** - Works on Android (Termux) and Linux desktop

## Quick Start

### Prerequisites
- Android device with Termux installed
- Termux:API package
- Python 3.8+

### Installation
```bash
# Clone the repository
git clone https://github.com/your-username/CIVOPS-Radar.git
cd CIVOPS-Radar

# Run the one-command installer
bash termux/install.sh
```

### Usage
```bash
# Start the radar system
cd /data/data/com.termux/files/home/radar
python server/app.py

# Access the web interface
# Open browser to: http://localhost:5000
```

## Project Structure

```
CIVOPS-Radar/
├── termux/                 # Termux scanning modules
│   ├── radar_prototype.sh  # Main scanning script
│   ├── install.sh          # One-command setup
│   └── README.md
├── server/                 # Flask web server
│   ├── app.py             # Main Flask application
│   ├── templates/         # HTML templates
│   ├── static/           # CSS, JS, assets
│   └── risk_engine.py    # Risk scoring algorithm
├── native/                # Future Kotlin Android app
├── data/                  # Local data storage
│   ├── scans.db          # SQLite database
│   ├── exports/          # Export files
│   └── samples/          # Sample data
├── docs/                  # Documentation
│   ├── API.md
│   ├── TECH.md
│   └── LEGAL.md
├── LICENSE
└── README.md
```

## Core Modules

### 1. termux-scan
- Bash + Python scanner using `termux-wifi-scaninfo`
- Configurable scan intervals
- Graceful handling of Android throttling
- SQLite data persistence

### 2. radar-hud
- Flask web server with HTML5 Canvas
- Real-time radar visualization
- Signal strength plotting
- Network filtering and search

### 3. risk-engine
- Automated security risk scoring
- Open network detection
- Hidden SSID identification
- Signal fluctuation analysis

### 4. trilateration (v2+)
- Multi-point coordinate estimation
- GPS integration support
- Signal triangulation algorithms

## Development

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Testing
```bash
# Test with sample data
python server/test_replay.py

# Run risk engine tests
python server/test_risk_engine.py
```

## Security & Privacy

- **No Root Required** - Works within Android security model
- **Local Storage Only** - All data stays on device
- **No Telemetry** - Zero network calls or data collection
- **Transparent Code** - Fully auditable source code
- **User Consent** - Clear authorization warnings

## License

MIT License - See [LICENSE](LICENSE) file for details.

## Support

- 📖 Documentation: [docs/](docs/)
- 🐛 Issues: [GitHub Issues](https://github.com/your-username/CIVOPS-Radar/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/your-username/CIVOPS-Radar/discussions)

---

**Built with ❤️ for the security research community**
