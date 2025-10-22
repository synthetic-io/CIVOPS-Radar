# CIVOPS-Radar API Documentation

## Overview

The CIVOPS-Radar API provides RESTful endpoints for accessing Wi-Fi scan data, managing the scanning process, and exporting results. All endpoints return JSON responses and support CORS for web interface integration.

## Base URL

```
http://localhost:5000
```

## Authentication

Currently, no authentication is required. All endpoints are accessible locally. Future versions may include API key authentication for security.

## Endpoints

### 1. Get Latest Scan Signals

**Endpoint**: `GET /api/signals`

**Description**: Retrieves the latest scan results for radar visualization.

**Parameters**:
- `limit` (optional): Maximum number of signals to return (default: 50)

**Response**:
```json
{
  "signals": [
    {
      "bssid": "00:11:22:33:44:55",
      "ssid": "HomeNetwork",
      "level": -45,
      "distance": 12.5,
      "risk_score": 15,
      "is_hidden": false,
      "is_open": false,
      "capabilities": "[WPA2-PSK-CCMP][ESS]",
      "frequency": 2412,
      "vendor": "Cisco",
      "last_seen": "2024-01-15T10:30:00",
      "scan_count": 42,
      "position": {
        "x": 0.3,
        "y": 0.4,
        "angle": 45,
        "radius": 0.7
      }
    }
  ],
  "timestamp": "2024-01-15T10:30:00"
}
```

**Status Codes**:
- `200`: Success
- `500`: Internal server error

### 2. Get Scan Statistics

**Endpoint**: `GET /api/statistics`

**Description**: Retrieves overall scan statistics and metrics.

**Response**:
```json
{
  "total_networks": 156,
  "active_networks": 23,
  "high_risk_networks": 3,
  "open_networks": 5,
  "hidden_networks": 2
}
```

**Status Codes**:
- `200`: Success
- `500`: Internal server error

### 3. Export Scan Data

**Endpoint**: `GET /api/export/<format>`

**Description**: Exports scan data in specified format.

**Parameters**:
- `format`: Export format (`json`, `csv`, `kml`)

**Response**:
- File download with appropriate MIME type
- Filename: `radar_export_YYYYMMDD_HHMMSS.<format>`

**Status Codes**:
- `200`: Success
- `400`: Unsupported format
- `500`: Internal server error

**Example**:
```
GET /api/export/json
Content-Type: application/json
Content-Disposition: attachment; filename="radar_export_20240115_103000.json"
```

### 4. Get Network Details

**Endpoint**: `GET /api/network/<bssid>`

**Description**: Retrieves detailed information about a specific network.

**Parameters**:
- `bssid`: MAC address of the network (e.g., `00:11:22:33:44:55`)

**Response**:
```json
{
  "id": 123,
  "timestamp": "2024-01-15T10:30:00",
  "bssid": "00:11:22:33:44:55",
  "ssid": "HomeNetwork",
  "capabilities": "[WPA2-PSK-CCMP][ESS]",
  "frequency": 2412,
  "level": -45,
  "distance": 12.5,
  "risk_score": 15,
  "is_hidden": false,
  "is_open": false,
  "vendor": "Cisco",
  "first_seen": "2024-01-15T09:00:00",
  "last_seen": "2024-01-15T10:30:00",
  "scan_count": 42,
  "history": [
    {
      "timestamp": "2024-01-15T10:30:00",
      "level": -45,
      "distance": 12.5,
      "risk_score": 15
    },
    {
      "timestamp": "2024-01-15T10:25:00",
      "level": -47,
      "distance": 14.2,
      "risk_score": 15
    }
  ]
}
```

**Status Codes**:
- `200`: Success
- `404`: Network not found
- `500`: Internal server error

### 5. Start Scanning

**Endpoint**: `POST /api/scan/start`

**Description**: Starts the Wi-Fi scanning process.

**Response**:
```json
{
  "status": "scan_started",
  "message": "Scanning started successfully"
}
```

**Status Codes**:
- `200`: Success
- `500`: Internal server error

### 6. Stop Scanning

**Endpoint**: `POST /api/scan/stop`

**Description**: Stops the Wi-Fi scanning process.

**Response**:
```json
{
  "status": "scan_stopped",
  "message": "Scanning stopped successfully"
}
```

**Status Codes**:
- `200`: Success
- `500`: Internal server error

## Data Models

### Network Signal

```typescript
interface NetworkSignal {
  bssid: string;           // MAC address
  ssid: string;            // Network name (empty if hidden)
  level: number;           // Signal strength in dBm
  distance: number;        // Estimated distance in meters
  risk_score: number;      // Risk score (0-100)
  is_hidden: boolean;      // Hidden network flag
  is_open: boolean;        // Open network flag
  capabilities: string;     // Security capabilities
  frequency: number;       // Channel frequency in MHz
  vendor: string;          // Device vendor
  last_seen: string;       // Last seen timestamp
  scan_count: number;      // Number of times detected
  position: {              // Radar position
    x: number;             // X coordinate (-1 to 1)
    y: number;             // Y coordinate (-1 to 1)
    angle: number;         // Angle in degrees
    radius: number;        // Distance from center (0 to 1)
  };
}
```

### Risk Factors

```typescript
interface RiskFactors {
  open_network: number;     // Open network risk (0-30)
  hidden_ssid: number;      // Hidden SSID risk (0-20)
  weak_encryption: number;  // Weak encryption risk (0-25)
  suspicious_ssid: number;  // Suspicious SSID risk (0-30)
  signal_fluctuation: number; // Signal fluctuation risk (0-15)
  proximity_risk: number;   // Proximity risk (0-10)
  vendor_risk: number;      // Vendor risk (0-5)
  beacon_anomaly: number;  // Beacon anomaly risk (0-15)
  channel_conflict: number; // Channel conflict risk (0-10)
  temporal_risk: number;    // Temporal risk (0-5)
}
```

### Scan Statistics

```typescript
interface ScanStatistics {
  total_networks: number;    // Total networks discovered
  active_networks: number;   // Currently active networks
  high_risk_networks: number; // High risk networks
  open_networks: number;     // Open networks
  hidden_networks: number;   // Hidden networks
}
```

## Error Handling

### Error Response Format

```json
{
  "error": "Error message",
  "code": "ERROR_CODE",
  "timestamp": "2024-01-15T10:30:00"
}
```

### Common Error Codes

- `INVALID_FORMAT`: Unsupported export format
- `NETWORK_NOT_FOUND`: Network BSSID not found
- `DATABASE_ERROR`: Database operation failed
- `SCAN_ERROR`: Scanning operation failed
- `PERMISSION_ERROR`: Insufficient permissions

### HTTP Status Codes

- `200`: Success
- `400`: Bad Request
- `404`: Not Found
- `500`: Internal Server Error

## Rate Limiting

Currently, no rate limiting is implemented. Future versions may include rate limiting to prevent abuse.

## CORS Support

All endpoints support CORS for web interface integration:

```http
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: Content-Type
```

## WebSocket Support (Future)

Planned WebSocket endpoints for real-time updates:

```javascript
// Connect to WebSocket
const ws = new WebSocket('ws://localhost:5000/ws/signals');

// Listen for updates
ws.onmessage = function(event) {
  const data = JSON.parse(event.data);
  updateRadarDisplay(data.signals);
};
```

## Examples

### JavaScript/AJAX

```javascript
// Get latest signals
fetch('/api/signals')
  .then(response => response.json())
  .then(data => {
    console.log('Signals:', data.signals);
    updateRadarDisplay(data.signals);
  });

// Export data
fetch('/api/export/json')
  .then(response => response.blob())
  .then(blob => {
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'radar_export.json';
    a.click();
  });

// Get network details
fetch('/api/network/00:11:22:33:44:55')
  .then(response => response.json())
  .then(network => {
    console.log('Network details:', network);
  });
```

### Python

```python
import requests

# Get latest signals
response = requests.get('http://localhost:5000/api/signals')
signals = response.json()['signals']

# Export data
response = requests.get('http://localhost:5000/api/export/csv')
with open('export.csv', 'wb') as f:
    f.write(response.content)

# Get statistics
response = requests.get('http://localhost:5000/api/statistics')
stats = response.json()
print(f"Total networks: {stats['total_networks']}")
```

### cURL

```bash
# Get latest signals
curl -X GET http://localhost:5000/api/signals

# Get statistics
curl -X GET http://localhost:5000/api/statistics

# Export JSON data
curl -X GET http://localhost:5000/api/export/json -o export.json

# Get network details
curl -X GET http://localhost:5000/api/network/00:11:22:33:44:55
```

## Testing

### Test Endpoints

```bash
# Test all endpoints
curl -X GET http://localhost:5000/api/signals
curl -X GET http://localhost:5000/api/statistics
curl -X GET http://localhost:5000/api/export/json
curl -X POST http://localhost:5000/api/scan/start
curl -X POST http://localhost:5000/api/scan/stop
```

### Load Testing

```bash
# Test with multiple requests
for i in {1..10}; do
  curl -X GET http://localhost:5000/api/signals &
done
wait
```

## Security Considerations

- All endpoints are local-only (no external access)
- No authentication required (local use only)
- Input validation on all parameters
- SQL injection prevention
- CORS properly configured

## Future Enhancements

- WebSocket support for real-time updates
- API key authentication
- Rate limiting
- GraphQL support
- Bulk operations
- Advanced filtering
- Real-time alerts

---

**For API support, please open an issue on GitHub or contact the development team.**
