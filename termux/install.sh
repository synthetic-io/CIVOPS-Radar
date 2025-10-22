#!/bin/bash
# CIVOPS-Radar: One-Command Installation Script
# Author: CIVOPS-Radar Contributors
# License: MIT
#
# This script installs all dependencies and sets up CIVOPS-Radar
# for Termux environment on Android devices.

set -euo pipefail

# Configuration
RADAR_DIR="/data/data/com.termux/files/home/radar"
REPO_URL="https://github.com/your-username/CIVOPS-Radar.git"
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
    pkg install -y python python-pip sqlite git curl wget
    
    # Termux:API for Wi-Fi scanning
    pkg install -y termux-api
    
    # Additional utilities
    pkg install -y jq nano vim
    
    success "Required packages installed"
}

# Install Python dependencies
install_python_deps() {
    info "Installing Python dependencies..."
    
    # Upgrade pip first
    pip install --upgrade pip
    
    # Install Flask and related packages
    pip install flask flask-cors
    
    # Install data processing packages
    pip install pandas numpy
    
    # Install additional utilities
    pip install requests beautifulsoup4
    
    success "Python dependencies installed"
}

# Setup Termux:API permissions
setup_permissions() {
    info "Setting up Termux:API permissions..."
    
    # Grant location permission (required for Wi-Fi scanning)
    termux-setup-storage
    
    # Note: User will need to manually grant permissions in Android settings
    warning "Please grant the following permissions in Android Settings:"
    warning "  - Location (for Wi-Fi scanning)"
    warning "  - Storage (for data export)"
    
    success "Permission setup initiated"
}

# Create radar directory structure
setup_directories() {
    info "Creating radar directory structure..."
    
    mkdir -p "$RADAR_DIR"/{data,exports,samples,server}
    mkdir -p "$RADAR_DIR"/server/{templates,static}
    mkdir -p "$RADAR_DIR"/docs
    
    success "Directory structure created"
}

# Copy project files
copy_files() {
    info "Copying project files..."
    
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    
    # Copy server files
    cp -r "$PROJECT_ROOT/server"/* "$RADAR_DIR/server/"
    
    # Copy documentation
    cp -r "$PROJECT_ROOT/docs"/* "$RADAR_DIR/docs/" 2>/dev/null || true
    
    # Copy main scanner script
    cp "$PROJECT_ROOT/termux/radar_prototype.sh" "$RADAR_DIR/"
    chmod +x "$RADAR_DIR/radar_prototype.sh"
    
    success "Project files copied"
}

# Initialize database
init_database() {
    info "Initializing SQLite database..."
    
    cd "$RADAR_DIR"
    
    # Run the scanner script in init mode
    ./radar_prototype.sh init
    
    success "Database initialized"
}

# Create startup scripts
create_startup_scripts() {
    info "Creating startup scripts..."
    
    # Create start script
    cat > "$RADAR_DIR/start_radar.sh" << 'EOF'
#!/bin/bash
# CIVOPS-Radar Startup Script

cd /data/data/com.termux/files/home/radar

echo "Starting CIVOPS-Radar..."
echo "Web interface will be available at: http://localhost:5000"
echo "Press Ctrl+C to stop"

# Start the web server in background
python server/app.py &
SERVER_PID=$!

# Start the scanner
./radar_prototype.sh scan &
SCANNER_PID=$!

# Wait for user interrupt
trap 'kill $SERVER_PID $SCANNER_PID; exit 0' INT
wait
EOF

    chmod +x "$RADAR_DIR/start_radar.sh"
    
    # Create stop script
    cat > "$RADAR_DIR/stop_radar.sh" << 'EOF'
#!/bin/bash
# CIVOPS-Radar Stop Script

echo "Stopping CIVOPS-Radar..."

# Kill any running radar processes
pkill -f "radar_prototype.sh" || true
pkill -f "server/app.py" || true

echo "CIVOPS-Radar stopped"
EOF

    chmod +x "$RADAR_DIR/stop_radar.sh"
    
    success "Startup scripts created"
}

# Create sample data
create_sample_data() {
    info "Creating sample data..."
    
    # Create sample scan data for testing
    cat > "$RADAR_DIR/samples/sample_scan.json" << 'EOF'
[
  {
    "bssid": "00:11:22:33:44:55",
    "ssid": "HomeNetwork",
    "capabilities": "[WPA2-PSK-CCMP][ESS]",
    "frequency": 2412,
    "level": -45
  },
  {
    "bssid": "00:11:22:33:44:56",
    "ssid": "OpenWiFi",
    "capabilities": "[ESS]",
    "frequency": 2437,
    "level": -60
  },
  {
    "bssid": "00:11:22:33:44:57",
    "ssid": "",
    "capabilities": "[WPA2-PSK-CCMP][ESS]",
    "frequency": 2462,
    "level": -70
  }
]
EOF

    success "Sample data created"
}

# Display installation summary
show_summary() {
    log ""
    log "${PURPLE}=== CIVOPS-Radar Installation Complete ===${NC}"
    log ""
    log "${GREEN}Installation Summary:${NC}"
    log "  • Radar directory: $RADAR_DIR"
    log "  • Database: $RADAR_DIR/data/scans.db"
    log "  • Web interface: http://localhost:5000"
    log ""
    log "${GREEN}Quick Start Commands:${NC}"
    log "  cd $RADAR_DIR"
    log "  ./start_radar.sh          # Start full radar system"
    log "  ./radar_prototype.sh scan # Start scanner only"
    log "  ./radar_prototype.sh stats # Show statistics"
    log ""
    log "${GREEN}Web Interface:${NC}"
    log "  • Open browser to: http://localhost:5000"
    log "  • View live radar visualization"
    log "  • Export scan data"
    log ""
    log "${YELLOW}Important Notes:${NC}"
    log "  • Grant location permission for Wi-Fi scanning"
    log "  • This tool is for authorized testing only"
    log "  • All data is stored locally (no cloud)"
    log ""
    log "${GREEN}Happy scanning! 🛰️${NC}"
}

# Main installation function
main() {
    log "${PURPLE}=== CIVOPS-Radar Installation ===${NC}"
    log "Installing offline-first Wi-Fi radar system..."
    log ""
    
    # Pre-flight checks
    check_termux
    
    # Installation steps
    update_termux
    install_packages
    install_python_deps
    setup_permissions
    setup_directories
    copy_files
    init_database
    create_startup_scripts
    create_sample_data
    
    # Show summary
    show_summary
}

# Run main function
main "$@"
