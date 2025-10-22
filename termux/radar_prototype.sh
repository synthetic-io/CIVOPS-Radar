#!/bin/bash
# CIVOPS-Radar: Main Wi-Fi Scanning Script
# Author: CIVOPS-Radar Contributors
# License: MIT
# 
# This script performs passive Wi-Fi scanning using Termux:API
# and stores results in SQLite database for radar visualization.

set -euo pipefail

# Configuration
RADAR_DIR="/data/data/com.termux/files/home/radar"
DB_PATH="${RADAR_DIR}/data/scans.db"
SCAN_INTERVAL=5  # seconds between scans
MAX_SCANS=1000   # maximum scans to keep in database
LOG_FILE="${RADAR_DIR}/scan.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log "${RED}ERROR: $1${NC}"
    exit 1
}

# Check if running in Termux
check_termux() {
    if [[ ! -d "/data/data/com.termux" ]]; then
        error_exit "This script must be run in Termux environment"
    fi
}

# Check Termux:API installation
check_termux_api() {
    if ! command -v termux-wifi-scaninfo &> /dev/null; then
        error_exit "Termux:API not installed. Run: pkg install termux-api"
    fi
}

# Create radar directory structure
setup_directories() {
    log "${BLUE}Setting up radar directories...${NC}"
    mkdir -p "$RADAR_DIR"/{data,exports,samples,server}
    mkdir -p "$RADAR_DIR"/server/{templates,static}
}

# Initialize SQLite database
init_database() {
    log "${BLUE}Initializing SQLite database...${NC}"
    
    sqlite3 "$DB_PATH" << 'EOF'
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

CREATE INDEX IF NOT EXISTS idx_bssid ON scans(bssid);
CREATE INDEX IF NOT EXISTS idx_timestamp ON scans(timestamp);
CREATE INDEX IF NOT EXISTS idx_level ON scans(level);

-- Create view for latest scan results
CREATE VIEW IF NOT EXISTS latest_scans AS
SELECT 
    bssid,
    ssid,
    capabilities,
    frequency,
    level,
    distance,
    risk_score,
    is_hidden,
    is_open,
    vendor,
    first_seen,
    last_seen,
    scan_count,
    timestamp
FROM scans s1
WHERE timestamp = (
    SELECT MAX(timestamp) 
    FROM scans s2 
    WHERE s2.bssid = s1.bssid
);
EOF
}

# Perform single Wi-Fi scan
perform_scan() {
    local scan_output
    local scan_count=0
    
    log "${YELLOW}Performing Wi-Fi scan...${NC}"
    
    # Use termux-wifi-scaninfo to get scan results
    if ! scan_output=$(termux-wifi-scaninfo 2>/dev/null); then
        log "${RED}Failed to get scan results. This may be due to Android throttling.${NC}"
        return 1
    fi
    
    # Check if scan output is empty
    if [[ -z "$scan_output" ]]; then
        log "${YELLOW}No networks detected in scan.${NC}"
        return 1
    fi
    
    # Process scan results with Python
    python3 -c "
import json
import sqlite3
import sys
from datetime import datetime

def calculate_distance(rssi, frequency=2400):
    '''Calculate approximate distance from RSSI using log-distance model'''
    if rssi == 0:
        return 999.0
    
    # Free space path loss model (simplified)
    # FSPL = 20*log10(d) + 20*log10(f) + 32.45
    # Where d is distance in meters, f is frequency in MHz
    
    # Typical values for 2.4GHz
    tx_power = 20  # dBm
    path_loss = tx_power - rssi
    
    if path_loss <= 0:
        return 0.1
    
    # Convert to distance (simplified calculation)
    distance = 10 ** ((path_loss - 32.45 - 20 * 3.38) / 20)
    return max(0.1, min(999.0, distance))

def calculate_risk_score(ssid, capabilities, level, is_hidden):
    '''Calculate risk score based on network characteristics'''
    score = 0
    
    # Open network (no security)
    if 'WPA' not in capabilities and 'WEP' not in capabilities:
        score += 30
    
    # Hidden SSID
    if is_hidden:
        score += 20
    
    # Weak signal (potential rogue AP)
    if level < -80:
        score += 10
    
    # Very strong signal (potential close proximity)
    if level > -30:
        score += 5
    
    return min(100, max(0, score))

def process_scan_data(scan_json):
    conn = sqlite3.connect('$DB_PATH')
    cursor = conn.cursor()
    
    try:
        scan_data = json.loads(scan_json)
        current_time = datetime.now().isoformat()
        
        for network in scan_data:
            bssid = network.get('bssid', '')
            ssid = network.get('ssid', '')
            capabilities = network.get('capabilities', '')
            frequency = network.get('frequency', 0)
            level = network.get('level', -100)
            
            # Determine if network is hidden or open
            is_hidden = ssid == '' or ssid == '<unknown ssid>'
            is_open = 'WPA' not in capabilities and 'WEP' not in capabilities
            
            # Calculate distance and risk score
            distance = calculate_distance(level, frequency)
            risk_score = calculate_risk_score(ssid, capabilities, level, is_hidden)
            
            # Check if BSSID already exists
            cursor.execute('SELECT id, scan_count FROM scans WHERE bssid = ? ORDER BY timestamp DESC LIMIT 1', (bssid,))
            existing = cursor.fetchone()
            
            if existing:
                # Update existing record
                cursor.execute('''
                    UPDATE scans 
                    SET timestamp = ?, level = ?, distance = ?, risk_score = ?, 
                        last_seen = ?, scan_count = scan_count + 1
                    WHERE bssid = ?
                ''', (current_time, level, distance, risk_score, current_time, bssid))
            else:
                # Insert new record
                cursor.execute('''
                    INSERT INTO scans (bssid, ssid, capabilities, frequency, level, 
                                    distance, risk_score, is_hidden, is_open, 
                                    first_seen, last_seen, scan_count)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
                ''', (bssid, ssid, capabilities, frequency, level, distance, 
                      risk_score, is_hidden, is_open, current_time, current_time))
        
        conn.commit()
        print(f'Processed {len(scan_data)} networks')
        
    except json.JSONDecodeError as e:
        print(f'JSON decode error: {e}')
    except Exception as e:
        print(f'Error processing scan data: {e}')
    finally:
        conn.close()

# Process the scan data
process_scan_data('$scan_output')
" || {
        log "${RED}Failed to process scan data${NC}"
        return 1
    }
    
    log "${GREEN}Scan completed successfully${NC}"
    return 0
}

# Clean old scans to prevent database bloat
cleanup_old_scans() {
    log "${BLUE}Cleaning up old scans...${NC}"
    sqlite3 "$DB_PATH" "DELETE FROM scans WHERE timestamp < datetime('now', '-1 hour') AND scan_count > 10;"
    sqlite3 "$DB_PATH" "VACUUM;"
}

# Display current scan statistics
show_stats() {
    local total_networks
    local active_networks
    local high_risk_networks
    
    total_networks=$(sqlite3 "$DB_PATH" "SELECT COUNT(DISTINCT bssid) FROM scans;")
    active_networks=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM latest_scans;")
    high_risk_networks=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM latest_scans WHERE risk_score > 50;")
    
    log "${GREEN}=== Scan Statistics ===${NC}"
    log "Total networks discovered: $total_networks"
    log "Currently active: $active_networks"
    log "High risk networks: $high_risk_networks"
}

# Main scanning loop
scan_loop() {
    local scan_count=0
    
    log "${GREEN}Starting CIVOPS-Radar scanning loop...${NC}"
    log "Scan interval: ${SCAN_INTERVAL} seconds"
    log "Press Ctrl+C to stop"
    
    while true; do
        scan_count=$((scan_count + 1))
        log "${BLUE}=== Scan #$scan_count ===${NC}"
        
        if perform_scan; then
            show_stats
        else
            log "${YELLOW}Scan failed, retrying in ${SCAN_INTERVAL} seconds...${NC}"
        fi
        
        # Cleanup every 10 scans
        if ((scan_count % 10 == 0)); then
            cleanup_old_scans
        fi
        
        sleep "$SCAN_INTERVAL"
    done
}

# Export scan data
export_data() {
    local format="${1:-json}"
    local output_file="${RADAR_DIR}/exports/scan_export_$(date +%Y%m%d_%H%M%S).${format}"
    
    case "$format" in
        json)
            sqlite3 -json "$DB_PATH" "SELECT * FROM latest_scans;" > "$output_file"
            ;;
        csv)
            sqlite3 -header -csv "$DB_PATH" "SELECT * FROM latest_scans;" > "$output_file"
            ;;
        *)
            log "${RED}Unsupported format: $format${NC}"
            return 1
            ;;
    esac
    
    log "${GREEN}Data exported to: $output_file${NC}"
}

# Main function
main() {
    log "${GREEN}=== CIVOPS-Radar Scanner ===${NC}"
    log "Initializing Wi-Fi scanning system..."
    
    # Pre-flight checks
    check_termux
    check_termux_api
    
    # Setup
    setup_directories
    init_database
    
    # Handle command line arguments
    case "${1:-scan}" in
        scan)
            scan_loop
            ;;
        export)
            export_data "${2:-json}"
            ;;
        stats)
            show_stats
            ;;
        init)
            log "${GREEN}Database initialized successfully${NC}"
            ;;
        *)
            echo "Usage: $0 {scan|export|stats|init}"
            echo "  scan   - Start continuous scanning (default)"
            echo "  export - Export data (json|csv)"
            echo "  stats  - Show current statistics"
            echo "  init   - Initialize database only"
            exit 1
            ;;
    esac
}

# Trap Ctrl+C for graceful shutdown
trap 'log "${YELLOW}Shutting down CIVOPS-Radar...${NC}"; exit 0' INT

# Run main function
main "$@"
