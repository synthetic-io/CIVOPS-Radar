#!/bin/bash
# CIVOPS-Radar: Bypass Installation Script
# Completely avoids OpenSSL and package manager issues

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🛰️ CIVOPS-Radar Bypass Installation${NC}"
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

# Download files directly (bypass git if needed)
echo -e "${BLUE}📥 Downloading CIVOPS-Radar files...${NC}"

# Create basic file structure
mkdir -p server/templates
mkdir -p server/static
mkdir -p data/{exports,samples}
mkdir -p docs

# Create minimal Flask app
cat > server/app.py << 'EOF'
#!/usr/bin/env python3
import os
import json
import sqlite3
import math
from datetime import datetime
from flask import Flask, render_template, jsonify, request

app = Flask(__name__)

# Configuration
RADAR_DIR = "/data/data/com.termux/files/home/radar"
DB_PATH = os.path.join(RADAR_DIR, "data", "scans.db")

# Initialize database
def init_database():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute('''
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
        )
    ''')
    
    conn.commit()
    conn.close()

@app.route('/')
def index():
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CIVOPS-Radar - Wi-Fi Scanner</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        body { background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%); font-family: monospace; }
        .radar-screen { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); width: 400px; height: 400px; border: 2px solid #10b981; border-radius: 50%; background: radial-gradient(circle, rgba(16, 185, 129, 0.1) 0%, transparent 70%); }
        .radar-center { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); width: 8px; height: 8px; background: #10b981; border-radius: 50%; box-shadow: 0 0 10px #10b981; }
        .radar-sweep { position: absolute; top: 50%; left: 50%; width: 2px; height: 200px; background: linear-gradient(to top, transparent, #10b981); transform-origin: bottom center; animation: sweep 3s linear infinite; }
        @keyframes sweep { from { transform: translate(-50%, -50%) rotate(0deg); } to { transform: translate(-50%, -50%) rotate(360deg); } }
        .network-dot { position: absolute; width: 8px; height: 8px; border-radius: 50%; transform: translate(-50%, -50%); cursor: pointer; }
        .network-dot.low-risk { background: #10b981; box-shadow: 0 0 8px #10b981; }
        .network-dot.medium-risk { background: #f59e0b; box-shadow: 0 0 8px #f59e0b; }
        .network-dot.high-risk { background: #ef4444; box-shadow: 0 0 8px #ef4444; }
    </style>
</head>
<body class="bg-slate-900 text-green-400">
    <div style="position: relative; width: 100%; height: 100vh; overflow: hidden;">
        <div class="radar-screen" id="radarScreen">
            <div class="radar-center"></div>
            <div class="radar-sweep"></div>
        </div>
        
        <div style="position: absolute; top: 20px; right: 20px; background: rgba(15, 23, 42, 0.9); border: 1px solid #10b981; border-radius: 8px; padding: 16px; color: #f1f5f9; min-width: 200px;">
            <h3 style="color: #10b981; margin-bottom: 16px;">CIVOPS-Radar</h3>
            <div>Status: <span style="color: #10b981;">Ready</span></div>
            <div>Networks: <span id="networkCount" style="color: #10b981;">0</span></div>
            <div>Demo Mode: <span style="color: #f59e0b;">Active</span></div>
        </div>
    </div>

    <script>
        // Demo networks
        const demoNetworks = [
            { bssid: "00:11:22:33:44:55", ssid: "HomeNetwork", level: -45, risk_score: 15 },
            { bssid: "00:11:22:33:44:56", ssid: "FreeWiFi", level: -60, risk_score: 80 },
            { bssid: "00:11:22:33:44:57", ssid: "Hidden", level: -70, risk_score: 45 },
            { bssid: "00:11:22:33:44:58", ssid: "Office_WiFi", level: -38, risk_score: 25 },
            { bssid: "00:11:22:33:44:59", ssid: "Mobile_Hotspot", level: -65, risk_score: 35 }
        ];

        function createNetworkDot(network) {
            const dot = document.createElement('div');
            dot.className = 'network-dot';
            
            let riskClass = 'low-risk';
            if (network.risk_score > 70) riskClass = 'high-risk';
            else if (network.risk_score > 30) riskClass = 'medium-risk';
            
            dot.classList.add(riskClass);
            
            // Random position
            const angle = Math.random() * 2 * Math.PI;
            const distance = 50 + Math.random() * 150;
            const x = 200 + Math.cos(angle) * distance;
            const y = 200 + Math.sin(angle) * distance;
            
            dot.style.left = x + 'px';
            dot.style.top = y + 'px';
            
            dot.addEventListener('click', () => {
                alert(`Network: ${network.ssid}\\nSignal: ${network.level} dBm\\nRisk: ${network.risk_score}/100`);
            });
            
            return dot;
        }

        function updateRadar() {
            const radarScreen = document.getElementById('radarScreen');
            const existingDots = radarScreen.querySelectorAll('.network-dot');
            existingDots.forEach(dot => dot.remove());
            
            demoNetworks.forEach(network => {
                const dot = createNetworkDot(network);
                radarScreen.appendChild(dot);
            });
            
            document.getElementById('networkCount').textContent = demoNetworks.length;
        }

        // Initialize radar
        updateRadar();
        setInterval(updateRadar, 5000);
    </script>
</body>
</html>
    '''

@app.route('/api/signals')
def get_signals():
    return jsonify({
        'signals': [],
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/statistics')
def get_statistics():
    return jsonify({
        'total_networks': 5,
        'active_networks': 5,
        'high_risk_networks': 1,
        'open_networks': 1,
        'hidden_networks': 1
    })

if __name__ == '__main__':
    init_database()
    print("🛰️ Starting CIVOPS-Radar...")
    print("📱 Web interface: http://localhost:5000")
    print("Press Ctrl+C to stop")
    app.run(host='0.0.0.0', port=5000, debug=False)
EOF

# Create startup script
echo -e "${BLUE}🚀 Creating startup script...${NC}"
cat > start_radar.sh << 'EOF'
#!/bin/bash
cd /data/data/com.termux/files/home/radar
echo "🛰️ Starting CIVOPS-Radar..."
echo "📱 Web interface: http://localhost:5000"
echo "Press Ctrl+C to stop"
python server/app.py
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
