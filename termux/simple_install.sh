#!/bin/bash
# CIVOPS-Radar: Simple Installation Script
# Avoids OpenSSL configuration issues

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🛰️ CIVOPS-Radar Simple Installation${NC}"
echo ""

# Check if running in Termux
if [[ ! -d "/data/data/com.termux" ]]; then
    echo -e "${RED}❌ This installer must be run in Termux environment${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Termux environment detected${NC}"

# Create radar directory
RADAR_DIR="/data/data/com.termux/files/home/radar"
mkdir -p "$RADAR_DIR"
cd "$RADAR_DIR"

echo -e "${BLUE}📁 Setting up radar directory...${NC}"

# Clone repository
echo -e "${BLUE}📥 Cloning CIVOPS-Radar...${NC}"
git clone https://github.com/synthetic-io/CIVOPS-Radar.git temp_radar
cp -r temp_radar/* .
rm -rf temp_radar

# Install minimal dependencies
echo -e "${BLUE}📦 Installing minimal dependencies...${NC}"
pkg install -y python sqlite git

# Install Python dependencies
echo -e "${BLUE}🐍 Installing Python dependencies...${NC}"
pip install flask flask-cors

# Setup permissions
echo -e "${BLUE}🔐 Setting up permissions...${NC}"
termux-setup-storage

# Create database
echo -e "${BLUE}💾 Creating database...${NC}"
mkdir -p data
sqlite3 data/scans.db << 'EOF'
CREATE TABLE IF NOT EXISTS scans (
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
EOF

# Create startup script
echo -e "${BLUE}🚀 Creating startup script...${NC}"
cat > start_radar.sh << 'EOF'
#!/bin/bash
cd /data/data/com.termux/files/home/radar
echo "🛰️ Starting CIVOPS-Radar..."
echo "📱 Web interface: http://localhost:5000"
echo "Press Ctrl+C to stop"
python server/app.py --host 0.0.0.0 --port 5000
EOF

chmod +x start_radar.sh

# Create demo data
echo -e "${BLUE}📊 Creating demo data...${NC}"
cat > data/samples/demo_networks.json << 'EOF'
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
    "ssid": "FreeWiFi",
    "capabilities": "[ESS]",
    "frequency": 2437,
    "level": -60
  },
  {
    "bssid": "00:11:22:33:44:57",
    "ssid": "Hidden",
    "capabilities": "[WPA2-PSK-CCMP][ESS]",
    "frequency": 2462,
    "level": -70
  }
]
EOF

echo ""
echo -e "${GREEN}✅ CIVOPS-Radar installed successfully!${NC}"
echo ""
echo -e "${BLUE}🚀 To start the radar:${NC}"
echo "cd ~/radar"
echo "./start_radar.sh"
echo ""
echo -e "${BLUE}📱 Then open browser to:${NC}"
echo "http://localhost:5000"
echo ""
echo -e "${GREEN}🎉 Ready to scan! 🛰️${NC}"
