#!/bin/bash
# CIVOPS-Radar: Mobile Installation Script
# Author: CIVOPS-Radar Contributors
# License: MIT
#
# This script installs CIVOPS-Radar on Android devices via Termux
# Optimized for mobile deployment and GitHub access

set -euo pipefail

# Configuration
RADAR_DIR="/data/data/com.termux/files/home/radar"
GITHUB_REPO="https://github.com/synthetic-io/CIVOPS-Radar.git"
PYTHON_VERSION="3.11"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Error handling
error_exit() {
    log "${RED}ERROR: $1${NC}"
    exit 1
}

# Success message
success() {
    log "${GREEN}✓ $1${NC}"
}

# Warning message
warning() {
    log "${YELLOW}⚠ $1${NC}"
}

# Info message
info() {
    log "${BLUE}ℹ $1${NC}"
}

# Check if running in Termux
check_termux() {
    if [[ ! -d "/data/data/com.termux" ]]; then
        error_exit "This installer must be run in Termux environment"
    fi
    success "Termux environment detected"
}

# Update Termux packages
update_termux() {
    info "Updating Termux packages..."
    pkg update -y
    pkg upgrade -y
    success "Termux packages updated"
}

# Install required packages
install_packages() {
    info "Installing required packages..."
    
    # Core packages
    pkg install -y python python-pip sqlite git curl wget jq
    
    # Termux:API for Wi-Fi scanning
    pkg install -y termux-api
    
    # Additional utilities
    pkg install -y nano vim
    
    success "Required packages installed"
}

# Install Python dependencies
install_python_deps() {
    info "Installing Python dependencies..."
    
    # Upgrade pip first
    pip install --upgrade pip
    
    # Install from requirements.txt if available
    if [[ -f "requirements.txt" ]]; then
        pip install -r requirements.txt
    else
        # Install core dependencies
        pip install flask flask-cors pandas numpy requests beautifulsoup4
    fi
    
    success "Python dependencies installed"
}

# Setup Termux:API permissions
setup_permissions() {
    info "Setting up Termux:API permissions..."
    
    # Grant location permission (required for Wi-Fi scanning)
    termux-setup-storage
    
    warning "Please grant the following permissions in Android Settings:"
    warning "  - Location (for Wi-Fi scanning)"
    warning "  - Storage (for data export)"
    warning "  - Camera (for QR code scanning)"
    
    success "Permission setup initiated"
}

# Clone from GitHub
clone_repository() {
    info "Cloning CIVOPS-Radar from GitHub..."
    
    # Remove existing directory if it exists
    if [[ -d "$RADAR_DIR" ]]; then
        rm -rf "$RADAR_DIR"
    fi
    
    # Clone repository
    git clone "$GITHUB_REPO" "$RADAR_DIR"
    
    success "Repository cloned successfully"
}

# Setup radar directory structure
setup_directories() {
    info "Setting up radar directories..."
    
    cd "$RADAR_DIR"
    mkdir -p data/{exports,samples}
    mkdir -p server/{templates,static}
    mkdir -p docs
    
    success "Directory structure created"
}

# Initialize database
init_database() {
    info "Initializing SQLite database..."
    
    cd "$RADAR_DIR"
    
    # Run the scanner script in init mode
    chmod +x termux/radar_prototype.sh
    ./termux/radar_prototype.sh init
    
    success "Database initialized"
}

# Create mobile startup scripts
create_mobile_scripts() {
    info "Creating mobile startup scripts..."
    
    cd "$RADAR_DIR"
    
    # Create mobile start script
    cat > start_mobile.sh << 'EOF'
#!/bin/bash
# CIVOPS-Radar Mobile Startup Script

cd /data/data/com.termux/files/home/radar

echo "🛰️ Starting CIVOPS-Radar Mobile..."
echo "📱 Web interface: http://localhost:5000"
echo "📊 Demo interface: http://localhost:5000/demo"
echo "Press Ctrl+C to stop"

# Start the web server
python server/app.py --host 0.0.0.0 --port 5000 &
SERVER_PID=$!

# Start the scanner
./termux/radar_prototype.sh scan &
SCANNER_PID=$!

# Wait for user interrupt
trap 'kill $SERVER_PID $SCANNER_PID; echo "🛑 CIVOPS-Radar stopped"; exit 0' INT
wait
EOF

    chmod +x start_mobile.sh
    
    # Create quick start script
    cat > quick_start.sh << 'EOF'
#!/bin/bash
# Quick start for mobile users

cd /data/data/com.termux/files/home/radar

echo "🚀 Quick Start CIVOPS-Radar"
echo "1. Starting web server..."
python server/app.py --host 0.0.0.0 --port 5000 &
echo "2. Web interface ready at: http://localhost:5000"
echo "3. Open browser and navigate to the URL above"
echo "4. Press Ctrl+C to stop"
wait
EOF

    chmod +x quick_start.sh
    
    # Create update script
    cat > update_radar.sh << 'EOF'
#!/bin/bash
# Update CIVOPS-Radar from GitHub

cd /data/data/com.termux/files/home/radar

echo "🔄 Updating CIVOPS-Radar..."
git pull origin main

echo "📦 Reinstalling dependencies..."
pip install -r requirements.txt

echo "✅ Update complete!"
echo "Run ./start_mobile.sh to restart"
EOF

    chmod +x update_radar.sh
    
    success "Mobile scripts created"
}

# Create mobile-friendly documentation
create_mobile_docs() {
    info "Creating mobile documentation..."
    
    cd "$RADAR_DIR"
    
    cat > MOBILE_README.md << 'EOF'
# CIVOPS-Radar Mobile Installation

## Quick Start

1. **Install Termux** from F-Droid (not Google Play)
2. **Run this installer**:
   ```bash
   curl -sSL https://raw.githubusercontent.com/your-username/CIVOPS-Radar/main/termux/mobile_install.sh | bash
   ```
3. **Start the radar**:
   ```bash
   cd ~/radar
   ./start_mobile.sh
   ```
4. **Open browser** to: `http://localhost:5000`

## Mobile Commands

- `./start_mobile.sh` - Start full radar system
- `./quick_start.sh` - Quick web interface only
- `./update_radar.sh` - Update from GitHub
- `./termux/radar_prototype.sh scan` - Scanner only

## Mobile Features

- 📱 **Mobile-optimized interface**
- 🛰️ **Live radar visualization**
- 📊 **Real-time statistics**
- 📤 **Data export**
- 🔒 **Offline operation**

## Troubleshooting

### No Networks Detected
- Check location permissions
- Ensure Wi-Fi is enabled
- Try increasing scan interval

### Web Interface Not Loading
- Check if port 5000 is available
- Restart with `./quick_start.sh`
- Check firewall settings

### Update Issues
- Run `./update_radar.sh`
- Check internet connection
- Verify GitHub access

## Support

- 📖 Documentation: [GitHub](https://github.com/your-username/CIVOPS-Radar)
- 🐛 Issues: [GitHub Issues](https://github.com/your-username/CIVOPS-Radar/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/your-username/CIVOPS-Radar/discussions)

---

**Happy scanning! 🛰️**
EOF

    success "Mobile documentation created"
}

# Create QR code for easy access
create_qr_code() {
    info "Creating QR code for easy access..."
    
    cd "$RADAR_DIR"
    
    # Create a simple QR code generator (if qrencode is available)
    if command -v qrencode &> /dev/null; then
        echo "http://localhost:5000" | qrencode -o radar_qr.png
        success "QR code created: radar_qr.png"
    else
        info "Install qrencode for QR code generation: pkg install qrencode"
    fi
}

# Display mobile installation summary
show_mobile_summary() {
    log ""
    log "${PURPLE}=== CIVOPS-Radar Mobile Installation Complete ===${NC}"
    log ""
    log "${GREEN}Mobile Installation Summary:${NC}"
    log "  • Radar directory: $RADAR_DIR"
    log "  • Web interface: http://localhost:5000"
    log "  • Demo interface: http://localhost:5000/demo"
    log ""
    log "${GREEN}Mobile Commands:${NC}"
    log "  cd $RADAR_DIR"
    log "  ./start_mobile.sh          # Start full system"
    log "  ./quick_start.sh           # Quick web interface"
    log "  ./update_radar.sh          # Update from GitHub"
    log ""
    log "${GREEN}Mobile Access:${NC}"
    log "  • Open browser to: http://localhost:5000"
    log "  • Use demo interface for testing"
    log "  • Export data for analysis"
    log ""
    log "${YELLOW}Mobile Notes:${NC}"
    log "  • Grant location permission for scanning"
    log "  • Use F-Droid version of Termux"
    log "  • Keep device charged during scanning"
    log ""
    log "${GREEN}Ready for mobile scanning! 📱🛰️${NC}"
}

# Main mobile installation function
main() {
    log "${PURPLE}=== CIVOPS-Radar Mobile Installation ===${NC}"
    log "Installing CIVOPS-Radar for mobile deployment..."
    log ""
    
    # Pre-flight checks
    check_termux
    
    # Installation steps
    update_termux
    install_packages
    install_python_deps
    setup_permissions
    clone_repository
    setup_directories
    init_database
    create_mobile_scripts
    create_mobile_docs
    create_qr_code
    
    # Show summary
    show_mobile_summary
}

# Run main function
main "$@"
