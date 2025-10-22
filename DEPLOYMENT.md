# CIVOPS-Radar Deployment Guide

## 🚀 GitHub Deployment

### 1. Create GitHub Repository

1. **Go to GitHub** and create a new repository:
   - Repository name: `CIVOPS-Radar`
   - Description: `Offline-first Wi-Fi scanning and radar visualization tool`
   - Visibility: Public (for open source)
   - Initialize with README: No (we already have one)

2. **Get your repository URL**:
   ```
   https://github.com/YOUR_USERNAME/CIVOPS-Radar.git
   ```

### 2. Deploy to GitHub

```bash
# Navigate to your project directory
cd /Users/c3/CIVOPS

# Add all files to Git
git add .

# Commit changes
git commit -m "Initial commit: CIVOPS-Radar v1.0.0"

# Add your GitHub repository as origin
git remote add origin https://github.com/synthetic-io/CIVOPS-Radar.git

# Push to GitHub
git push -u origin main
```

### 3. Update Mobile Installer

After pushing to GitHub, update the mobile installer with your repository URL:

```bash
# Edit the mobile installer
nano termux/mobile_install.sh

# Update this line with your GitHub URL:
GITHUB_REPO="https://github.com/YOUR_USERNAME/CIVOPS-Radar.git"
```

## 📱 Mobile Installation

### Prerequisites

1. **Install Termux** from F-Droid (not Google Play Store)
2. **Grant permissions** when prompted
3. **Update Termux** packages

### One-Command Installation

```bash
# Install CIVOPS-Radar on your phone
curl -sSL https://raw.githubusercontent.com/synthetic-io/CIVOPS-Radar/main/termux/mobile_install.sh | bash
```

### Manual Installation

```bash
# Clone repository
git clone https://github.com/synthetic-io/CIVOPS-Radar.git ~/radar
cd ~/radar

# Run installer
bash termux/install.sh

# Start the system
./start_mobile.sh
```

## 🌐 Web Access

### Local Access
- **Main Interface**: `http://localhost:5000`
- **Demo Interface**: `http://localhost:5000/demo`
- **API Endpoints**: `http://localhost:5000/api/`

### Network Access (Optional)
To access from other devices on your network:

```bash
# Start with network access
python server/app.py --host 0.0.0.0 --port 5000
```

Then access from other devices at: `http://YOUR_PHONE_IP:5000`

## 📊 Mobile Commands

### Quick Start
```bash
cd ~/radar
./quick_start.sh
```

### Full System
```bash
cd ~/radar
./start_mobile.sh
```

### Scanner Only
```bash
cd ~/radar
./termux/radar_prototype.sh scan
```

### Update System
```bash
cd ~/radar
./update_radar.sh
```

## 🔧 Mobile Configuration

### Termux Setup
```bash
# Update packages
pkg update && pkg upgrade

# Install required packages
pkg install python sqlite git termux-api

# Grant permissions
termux-setup-storage
```

### Android Permissions
1. **Location**: Required for Wi-Fi scanning
2. **Storage**: Required for data export
3. **Camera**: Optional for QR code scanning

### Network Configuration
```bash
# Check Wi-Fi status
termux-wifi-scaninfo

# Test API access
curl http://localhost:5000/api/statistics
```

## 🛠️ Development Setup

### Local Development
```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/CIVOPS-Radar.git
cd CIVOPS-Radar

# Install dependencies
pip install -r requirements.txt

# Run development server
python server/app.py --debug
```

### Mobile Development
```bash
# On your phone, update from GitHub
cd ~/radar
git pull origin main

# Restart services
./update_radar.sh
```

## 📱 Mobile Features

### Optimized Interface
- **Responsive Design**: Works on all screen sizes
- **Touch-Friendly**: Optimized for mobile interaction
- **Fast Loading**: Minimal dependencies
- **Offline Operation**: No internet required

### Mobile-Specific Features
- **QR Code Access**: Quick access to web interface
- **Mobile Scripts**: Easy-to-use command shortcuts
- **Auto-Update**: GitHub integration for updates
- **Mobile Documentation**: Tailored for mobile users

## 🔒 Security Considerations

### Mobile Security
- **Local Storage Only**: All data stays on device
- **No Cloud Sync**: Complete privacy protection
- **Permission-Based**: Only requests necessary permissions
- **Offline Operation**: No network dependencies

### Network Security
- **Passive Scanning**: No network disruption
- **Authorized Use Only**: Clear legal warnings
- **Data Encryption**: Local SQLite encryption
- **Secure APIs**: Local-only endpoints

## 🚨 Troubleshooting

### Common Issues

#### Installation Fails
```bash
# Check Termux version
termux-info

# Update packages
pkg update && pkg upgrade

# Reinstall dependencies
pkg install python sqlite git termux-api
```

#### Scanner Not Working
```bash
# Check permissions
termux-wifi-scaninfo

# Grant location permission
termux-setup-storage

# Check Wi-Fi status
termux-wifi-scaninfo
```

#### Web Interface Not Loading
```bash
# Check if server is running
ps aux | grep python

# Restart server
./quick_start.sh

# Check port availability
netstat -an | grep 5000
```

#### Update Issues
```bash
# Check internet connection
ping github.com

# Manual update
git pull origin main
pip install -r requirements.txt
```

### Performance Issues
```bash
# Check memory usage
free -h

# Clean old data
./termux/radar_prototype.sh cleanup

# Reduce scan frequency
# Edit termux/radar_prototype.sh
# Change SCAN_INTERVAL=10
```

## 📈 Monitoring

### System Status
```bash
# Check running processes
ps aux | grep radar

# Check database size
du -h data/scans.db

# View logs
tail -f scan.log
```

### Performance Metrics
```bash
# Network count
sqlite3 data/scans.db "SELECT COUNT(*) FROM scans;"

# Active networks
sqlite3 data/scans.db "SELECT COUNT(*) FROM scans WHERE timestamp > datetime('now', '-5 minutes');"

# High-risk networks
sqlite3 data/scans.db "SELECT COUNT(*) FROM scans WHERE risk_score > 50;"
```

## 🔄 Updates

### Automatic Updates
```bash
# Update from GitHub
./update_radar.sh
```

### Manual Updates
```bash
# Pull latest changes
git pull origin main

# Reinstall dependencies
pip install -r requirements.txt

# Restart services
./start_mobile.sh
```

## 📞 Support

### Getting Help
- **GitHub Issues**: [Report bugs](https://github.com/YOUR_USERNAME/CIVOPS-Radar/issues)
- **GitHub Discussions**: [Ask questions](https://github.com/YOUR_USERNAME/CIVOPS-Radar/discussions)
- **Documentation**: [Read the docs](https://github.com/YOUR_USERNAME/CIVOPS-Radar/docs)

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

**Ready to deploy! 🚀📱**
