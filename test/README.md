# Test Environment for MagicMirror WLAN Manager

This directory contains tools for testing the WLAN Manager locally without requiring a Raspberry Pi or actual network configuration.

## Quick Start

```bash
# Start test environment
bash test-environment.sh
```

This will:
1. Create mock data files
2. Start WebUI on http://localhost:8765
3. Optionally start Network Monitor in mock mode

## Mock Files

The test environment uses these files to simulate system state:

### `mock-internet.txt`
Controls whether internet is "available"
- `true` = Internet available
- `false` = No internet (triggers HotSpot)

```bash
echo 'false' > mock-internet.txt  # Simulate no internet
```

### `mock-hotspot-active.txt`
Controls whether HotSpot is "active"
- `true` = HotSpot running
- `false` = HotSpot stopped

```bash
echo 'true' > mock-hotspot-active.txt  # Simulate HotSpot active
```

### `wlan-status.json`
Current network status (auto-updated by network monitor)

```json
{
  "timestamp": "2026-04-17T12:00:00",
  "internet": false,
  "hotspot_active": true,
  "mode": "hotspot",
  "wlan": {
    "connected": false,
    "ssid": null,
    "ip": null
  }
}
```

## Testing Scenarios

### Scenario 1: No Internet (HotSpot Mode)

```bash
# Simulate no internet
echo 'false' > test/mock-internet.txt

# Check status
curl http://localhost:8765/api/status | jq

# Should show:
# {
#   "success": true,
#   "status": {
#     "internet": false,
#     "hotspot_active": true,
#     "mode": "hotspot"
#   }
# }
```

### Scenario 2: Internet Available (Client Mode)

```bash
# Simulate internet available
echo 'true' > test/mock-internet.txt

# HotSpot should stop
echo 'false' > test/mock-hotspot-active.txt

# Check status
curl http://localhost:8765/api/status | jq
```

### Scenario 3: Network Scan

```bash
# Scan for WiFi networks (returns mock data)
curl http://localhost:8765/api/networks | jq

# Returns:
# {
#   "success": true,
#   "networks": [
#     {
#       "ssid": "HomeWiFi",
#       "signal": -45,
#       "encryption": "WPA2",
#       "channel": 6
#     }
#   ]
# }
```

### Scenario 4: Configure WiFi

```bash
# Configure a WiFi network
curl -X POST http://localhost:8765/api/configure \
  -H 'Content-Type: application/json' \
  -d '{
    "ssid": "MyWiFi",
    "password": "secret123",
    "encryption": "WPA2-PSK"
  }' | jq

# In mock mode, this creates test/mock-wpa_supplicant.conf
cat test/mock-wpa_supplicant.conf
```

### Scenario 5: QR Codes

```bash
# Get QR code data
curl http://localhost:8765/api/qr-data | jq

# Returns base64-encoded QR code images
```

## Manual Testing

### WebUI Browser Testing

1. Start test environment:
   ```bash
   bash test/test-environment.sh
   ```

2. Open browser: http://localhost:8765

3. Test interactions:
   - Click "Scan for Networks"
   - Select a network
   - Enter password
   - Click "Connect"

4. Simulate state changes in another terminal:
   ```bash
   # Trigger no internet
   echo 'false' > test/mock-internet.txt
   
   # Wait 30 seconds or refresh page
   # Status should update to show HotSpot mode
   ```

### Network Monitor Testing

```bash
# Start network monitor in mock mode
cd scripts
MOCK_MODE=true python3 network-monitor.py

# In another terminal, simulate changes:
echo 'false' > test/mock-internet.txt

# Monitor should detect and "start HotSpot"
# Check logs and status file
tail -f test/wlan-status.json
```

## Integration Tests

### Test Complete Flow

```bash
# 1. Start environment
bash test/test-environment.sh

# 2. Simulate no internet (triggers HotSpot)
echo 'false' > test/mock-internet.txt
sleep 5

# 3. Check status
curl http://localhost:8765/api/status | jq '.status.hotspot_active'
# Should return: true

# 4. Configure WiFi
curl -X POST http://localhost:8765/api/configure \
  -H 'Content-Type: application/json' \
  -d '{"ssid":"TestWiFi","password":"testpass123","encryption":"WPA2-PSK"}'

# 5. Simulate internet available
echo 'true' > test/mock-internet.txt
sleep 5

# 6. HotSpot should stop
curl http://localhost:8765/api/status | jq '.status.hotspot_active'
# Should return: false
```

## Automated Tests

### Unit Tests (Python)

```bash
cd test
python3 -m pytest test_api.py -v
```

### API Tests

```bash
# Test all endpoints
bash test/test-api.sh
```

## Clean Up

```bash
# Stop all test processes
pkill -f "python.*app.py"
pkill -f "python.*network-monitor.py"

# Remove mock files
rm test/mock-*.txt
rm test/wlan-status.json
```

## Debugging

### View Logs

```bash
# Network monitor log
tail -f test/network-monitor.log

# WebUI log (printed to console)
# If running in background:
tail -f /tmp/magicmirror-wlan-webui.log
```

### Common Issues

**WebUI not starting:**
```bash
# Check if port is already in use
lsof -i:8765

# Kill existing process
kill $(lsof -t -i:8765)
```

**Mock files not working:**
```bash
# Ensure MOCK_MODE is set
export MOCK_MODE=true

# Verify mock files exist
ls -la test/mock-*.txt
```

## Environment Variables

```bash
# Enable mock mode
export MOCK_MODE=true

# Disable mock mode (use real system)
export MOCK_MODE=false
```

## Test Data

Mock network scan returns:
- `HomeWiFi` (WPA2, -45 dBm, strong)
- `Neighbor_5G` (WPA2, -67 dBm, medium)
- `FreeWiFi` (Open, -82 dBm, weak)

Mock HotSpot credentials:
- SSID: `MagicMirror-Setup`
- Password: `magicmirror`
- IP: `192.168.4.1`

## Next Steps

After local testing is successful:
1. Test on actual Raspberry Pi
2. Verify HotSpot functionality
3. Test with real WiFi networks
4. Validate MagicMirror integration
