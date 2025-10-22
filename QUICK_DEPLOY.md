# 🚀 CIVOPS-Radar Quick Deployment Guide

## 📱 Mobile Deployment (Your Phone)

### Step 1: Create GitHub Repository

1. **Go to GitHub.com** and create a new repository:
   - Name: `CIVOPS-Radar`
   - Description: `Offline-first Wi-Fi scanning and radar visualization tool`
   - Visibility: Public
   - Don't initialize with README (we already have one)

2. **Copy your repository URL** (you'll need this)

### Step 2: Deploy to GitHub

```bash
# Run the automated setup script
./setup_github.sh
```

**OR manually:**

```bash
# Add your GitHub repository
git remote add origin https://github.com/synthetic-io/CIVOPS-Radar.git

# Push to GitHub
git push -u origin main
```

### Step 3: Install on Your Phone

1. **Install Termux** from F-Droid (not Google Play)
2. **Open Termux** and run:

```bash
# One-command installation
curl -sSL https://raw.githubusercontent.com/synthetic-io/CIVOPS-Radar/main/termux/mobile_install.sh | bash
```

3. **Start the radar system**:

```bash
cd ~/radar
./start_mobile.sh
```

4. **Open browser** to: `http://localhost:5000`

## 🎯 Quick Commands

### On Your Computer (Deployment)
```bash
cd /Users/c3/CIVOPS
./setup_github.sh
```

### On Your Phone (Installation)
```bash
# Install CIVOPS-Radar
curl -sSL https://raw.githubusercontent.com/synthetic-io/CIVOPS-Radar/main/termux/mobile_install.sh | bash

# Start the system
cd ~/radar
./start_mobile.sh
```

### Mobile Commands
```bash
cd ~/radar

# Quick start (web interface only)
./quick_start.sh

# Full system (scanner + web)
./start_mobile.sh

# Update from GitHub
./update_radar.sh
```

## 🌐 Access Points

- **Main Interface**: `http://localhost:5000`
- **Demo Interface**: `http://localhost:5000/demo`
- **API Endpoints**: `http://localhost:5000/api/`

## 📱 Mobile Features

- ✅ **One-command installation**
- ✅ **Mobile-optimized interface**
- ✅ **Live radar visualization**
- ✅ **Real-time scanning**
- ✅ **Data export**
- ✅ **Offline operation**

## 🔧 Troubleshooting

### Installation Issues
```bash
# Update Termux
pkg update && pkg upgrade

# Install dependencies
pkg install python sqlite git termux-api

# Grant permissions
termux-setup-storage
```

### Scanner Not Working
- Check location permissions in Android settings
- Ensure Wi-Fi is enabled
- Try: `termux-wifi-scaninfo`

### Web Interface Not Loading
- Check if server is running: `ps aux | grep python`
- Restart: `./quick_start.sh`
- Check port: `netstat -an | grep 5000`

## 📊 What You Get

### 🛰️ **Radar Visualization**
- Circular radar display with range rings
- Real-time network positioning
- Color-coded risk levels
- Interactive network information

### 📡 **Wi-Fi Scanning**
- Passive network detection
- Signal strength analysis
- Distance estimation
- Risk assessment

### 📊 **Data Analysis**
- Network statistics
- Export capabilities (JSON, CSV, KML)
- Historical data
- Risk scoring

### 🔒 **Security Features**
- Local storage only
- No cloud dependencies
- Privacy-focused
- Offline operation

## 🎉 Success!

Once deployed, you'll have:

1. **GitHub Repository** with all code
2. **Mobile Installation** via one command
3. **Web Interface** accessible on your phone
4. **Live Radar** showing nearby networks
5. **Complete Documentation** for future use

## 📞 Support

- **GitHub**: [Your Repository](https://github.com/synthetic-io/CIVOPS-Radar)
- **Issues**: [GitHub Issues](https://github.com/synthetic-io/CIVOPS-Radar/issues)
- **Documentation**: [Project Docs](https://github.com/synthetic-io/CIVOPS-Radar/docs)

---

**Ready to scan! 🛰️📱**
