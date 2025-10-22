#!/usr/bin/env python3
"""
CIVOPS-Radar: Flask Web Server
Author: CIVOPS-Radar Contributors
License: MIT

Main Flask application for the radar web interface.
Provides real-time Wi-Fi network visualization and data export.
"""

import os
import json
import sqlite3
import math
import time
from datetime import datetime, timedelta
from flask import Flask, render_template, jsonify, request, send_file
from flask_cors import CORS
import threading
import queue

# Configuration
RADAR_DIR = "/data/data/com.termux/files/home/radar"
DB_PATH = os.path.join(RADAR_DIR, "data", "scans.db")
EXPORT_DIR = os.path.join(RADAR_DIR, "exports")

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Global variables for real-time updates
scan_queue = queue.Queue()
last_scan_time = None

class RadarData:
    """Handle radar data operations and calculations"""
    
    def __init__(self, db_path):
        self.db_path = db_path
        self.ensure_database()
    
    def ensure_database(self):
        """Ensure database exists and is properly initialized"""
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Create tables if they don't exist
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
        
        cursor.execute('''
            CREATE INDEX IF NOT EXISTS idx_bssid ON scans(bssid)
        ''')
        cursor.execute('''
            CREATE INDEX IF NOT EXISTS idx_timestamp ON scans(timestamp)
        ''')
        
        conn.commit()
        conn.close()
    
    def get_latest_scans(self, limit=100):
        """Get latest scan results for radar display"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        query = '''
            SELECT 
                bssid, ssid, capabilities, frequency, level, distance, 
                risk_score, is_hidden, is_open, vendor, first_seen, last_seen,
                scan_count, timestamp
            FROM scans s1
            WHERE timestamp = (
                SELECT MAX(timestamp) 
                FROM scans s2 
                WHERE s2.bssid = s1.bssid
            )
            ORDER BY timestamp DESC
            LIMIT ?
        '''
        
        cursor.execute(query, (limit,))
        columns = [description[0] for description in cursor.description]
        results = [dict(zip(columns, row)) for row in cursor.fetchall()]
        
        conn.close()
        return results
    
    def get_scan_statistics(self):
        """Get overall scan statistics"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        stats = {}
        
        # Total networks discovered
        cursor.execute("SELECT COUNT(DISTINCT bssid) FROM scans")
        stats['total_networks'] = cursor.fetchone()[0]
        
        # Currently active networks
        cursor.execute("SELECT COUNT(*) FROM scans WHERE timestamp > datetime('now', '-5 minutes')")
        stats['active_networks'] = cursor.fetchone()[0]
        
        # High risk networks
        cursor.execute("SELECT COUNT(*) FROM scans WHERE risk_score > 50 AND timestamp > datetime('now', '-5 minutes')")
        stats['high_risk_networks'] = cursor.fetchone()[0]
        
        # Open networks
        cursor.execute("SELECT COUNT(*) FROM scans WHERE is_open = 1 AND timestamp > datetime('now', '-5 minutes')")
        stats['open_networks'] = cursor.fetchone()[0]
        
        # Hidden networks
        cursor.execute("SELECT COUNT(*) FROM scans WHERE is_hidden = 1 AND timestamp > datetime('now', '-5 minutes')")
        stats['hidden_networks'] = cursor.fetchone()[0]
        
        conn.close()
        return stats
    
    def calculate_radar_position(self, bssid, level, distance):
        """Calculate radar position for network visualization"""
        # Use BSSID hash for consistent angle
        hash_val = hash(bssid) % 360
        angle = math.radians(hash_val)
        
        # Calculate position based on signal strength
        # Stronger signals appear closer to center
        max_distance = 200  # meters
        normalized_distance = min(distance / max_distance, 1.0)
        radius = (1 - normalized_distance) * 0.8  # 80% of radar radius
        
        x = radius * math.cos(angle)
        y = radius * math.sin(angle)
        
        return {
            'x': x,
            'y': y,
            'angle': hash_val,
            'radius': radius
        }
    
    def export_data(self, format_type='json'):
        """Export scan data in specified format"""
        scans = self.get_latest_scans(limit=1000)
        
        if format_type == 'json':
            return json.dumps(scans, indent=2, default=str)
        elif format_type == 'csv':
            import csv
            import io
            
            output = io.StringIO()
            if scans:
                writer = csv.DictWriter(output, fieldnames=scans[0].keys())
                writer.writeheader()
                writer.writerows(scans)
            return output.getvalue()
        elif format_type == 'kml':
            return self.generate_kml(scans)
        else:
            raise ValueError(f"Unsupported format: {format_type}")
    
    def generate_kml(self, scans):
        """Generate KML file for Google Earth visualization"""
        kml_header = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>
    <name>CIVOPS-Radar Scan Results</name>
    <description>Wi-Fi network scan results</description>
'''
        
        kml_footer = '''
</Document>
</kml>'''
        
        kml_content = kml_header
        
        for scan in scans:
            if scan['ssid'] and scan['ssid'] != '':
                name = scan['ssid']
            else:
                name = f"Hidden Network ({scan['bssid']})"
            
            # Generate random coordinates for visualization
            # In real implementation, this would use GPS coordinates
            lat = 37.7749 + (hash(scan['bssid']) % 1000 - 500) / 100000
            lon = -122.4194 + (hash(scan['bssid']) % 1000 - 500) / 100000
            
            kml_content += f'''
    <Placemark>
        <name>{name}</name>
        <description>
            BSSID: {scan['bssid']}
            Signal: {scan['level']} dBm
            Risk Score: {scan['risk_score']}
            Security: {scan['capabilities']}
        </description>
        <Point>
            <coordinates>{lon},{lat},0</coordinates>
        </Point>
    </Placemark>'''
        
        kml_content += kml_footer
        return kml_content

# Initialize radar data handler
radar_data = RadarData(DB_PATH)

@app.route('/')
def index():
    """Main radar interface"""
    return render_template('radar.html')

@app.route('/api/signals')
def get_signals():
    """Get latest scan signals for radar display"""
    try:
        scans = radar_data.get_latest_scans(limit=50)
        
        # Process scans for radar display
        radar_signals = []
        for scan in scans:
            position = radar_data.calculate_radar_position(
                scan['bssid'], 
                scan['level'], 
                scan['distance']
            )
            
            signal = {
                'bssid': scan['bssid'],
                'ssid': scan['ssid'] or 'Hidden',
                'level': scan['level'],
                'distance': scan['distance'],
                'risk_score': scan['risk_score'],
                'is_hidden': scan['is_hidden'],
                'is_open': scan['is_open'],
                'capabilities': scan['capabilities'],
                'frequency': scan['frequency'],
                'vendor': scan['vendor'],
                'last_seen': scan['last_seen'],
                'scan_count': scan['scan_count'],
                'position': position
            }
            radar_signals.append(signal)
        
        return jsonify({
            'signals': radar_signals,
            'timestamp': datetime.now().isoformat()
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/statistics')
def get_statistics():
    """Get scan statistics"""
    try:
        stats = radar_data.get_scan_statistics()
        return jsonify(stats)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/export/<format_type>')
def export_data(format_type):
    """Export scan data in specified format"""
    try:
        if format_type not in ['json', 'csv', 'kml']:
            return jsonify({'error': 'Unsupported format'}), 400
        
        data = radar_data.export_data(format_type)
        
        # Save to file
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"radar_export_{timestamp}.{format_type}"
        filepath = os.path.join(EXPORT_DIR, filename)
        
        os.makedirs(EXPORT_DIR, exist_ok=True)
        
        with open(filepath, 'w') as f:
            f.write(data)
        
        return send_file(filepath, as_attachment=True, download_name=filename)
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/network/<bssid>')
def get_network_details(bssid):
    """Get detailed information about a specific network"""
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        # Get latest scan for this BSSID
        cursor.execute('''
            SELECT * FROM scans 
            WHERE bssid = ? 
            ORDER BY timestamp DESC 
            LIMIT 1
        ''', (bssid,))
        
        columns = [description[0] for description in cursor.description]
        result = cursor.fetchone()
        
        if result:
            network = dict(zip(columns, result))
            
            # Get historical data
            cursor.execute('''
                SELECT timestamp, level, distance, risk_score
                FROM scans 
                WHERE bssid = ? 
                ORDER BY timestamp DESC 
                LIMIT 20
            ''', (bssid,))
            
            history = []
            for row in cursor.fetchall():
                history.append({
                    'timestamp': row[0],
                    'level': row[1],
                    'distance': row[2],
                    'risk_score': row[3]
                })
            
            network['history'] = history
            
            conn.close()
            return jsonify(network)
        else:
            conn.close()
            return jsonify({'error': 'Network not found'}), 404
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/scan/start')
def start_scan():
    """Start manual scan (if scanner is not running)"""
    try:
        # This would trigger a manual scan
        # For now, just return success
        return jsonify({'status': 'scan_started'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/scan/stop')
def stop_scan():
    """Stop scanning"""
    try:
        # This would stop the scanner
        # For now, just return success
        return jsonify({'status': 'scan_stopped'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal server error'}), 500

def run_server(host='0.0.0.0', port=5000, debug=False):
    """Run the Flask server"""
    print(f"Starting CIVOPS-Radar web server...")
    print(f"Web interface: http://{host}:{port}")
    print(f"Database: {DB_PATH}")
    print("Press Ctrl+C to stop")
    
    app.run(host=host, port=port, debug=debug, threaded=True)

if __name__ == '__main__':
    import argparse
    
    parser = argparse.ArgumentParser(description='CIVOPS-Radar Web Server')
    parser.add_argument('--host', default='0.0.0.0', help='Host to bind to')
    parser.add_argument('--port', type=int, default=5000, help='Port to bind to')
    parser.add_argument('--debug', action='store_true', help='Enable debug mode')
    
    args = parser.parse_args()
    
    run_server(host=args.host, port=args.port, debug=args.debug)
