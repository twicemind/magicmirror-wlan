#!/bin/bash
#
# Test Environment for MagicMirror WLAN Manager
#
# Starts local test environment with mocked network functions
# No root or actual network changes required

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=================================="
echo "MagicMirror WLAN Manager"
echo "Test Environment"
echo "=================================="
echo ""

# Setup test directory
TEST_DIR="$SCRIPT_DIR"
mkdir -p "$TEST_DIR"

# Create mock files with defaults
echo "true" > "$TEST_DIR/mock-internet.txt"
echo "false" > "$TEST_DIR/mock-hotspot-active.txt"

# Create initial status file
cat > "$TEST_DIR/wlan-status.json" <<'EOF'
{
  "timestamp": "2026-04-17T12:00:00",
  "internet": true,
  "hotspot_active": false,
  "mode": "client",
  "wlan": {
    "connected": true,
    "ssid": "MockWLAN",
    "ip": "192.168.1.100",
    "interface": "wlan0"
  }
}
EOF

echo "✓ Test files created"
echo ""

# Export MOCK_MODE
export MOCK_MODE=true

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Controls:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Simulate internet status:"
echo "  echo 'true' > $TEST_DIR/mock-internet.txt   # Internet available"
echo "  echo 'false' > $TEST_DIR/mock-internet.txt  # No internet"
echo ""
echo "Simulate hotspot status:"
echo "  echo 'true' > $TEST_DIR/mock-hotspot-active.txt   # HotSpot active"
echo "  echo 'false' > $TEST_DIR/mock-hotspot-active.txt  # HotSpot off"
echo ""
echo "View current status:"
echo "  cat $TEST_DIR/wlan-status.json"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if Python venv exists
if [[ ! -d "$PROJECT_DIR/webui/venv" ]]; then
    echo "Creating Python virtual environment..."
    cd "$PROJECT_DIR/webui"
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    deactivate
    echo "✓ Python environment ready"
    echo ""
fi

# Start WebUI in background
echo "Starting WebUI (port 8765)..."
cd "$PROJECT_DIR/webui"
source venv/bin/activate

# Start in background
MOCK_MODE=true python app.py &
WEBUI_PID=$!

echo "✓ WebUI started (PID: $WEBUI_PID)"

# Wait for WebUI to start
sleep 3

# Check if WebUI is running
if curl -s http://localhost:8765/health > /dev/null; then
    echo "✓ WebUI is responding"
else
    echo "⚠ WebUI might not be ready yet (curl failed)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Environment Running!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Access Points:"
echo "  WebUI: http://localhost:8765"
echo "  API Status: http://localhost:8765/api/status"
echo "  API Networks: http://localhost:8765/api/networks"
echo "  API QR Codes: http://localhost:8765/api/qr-data"
echo ""
echo "Logs:"
echo "  WebUI: $TEST_DIR/network-monitor.log"
echo "  Status: $TEST_DIR/wlan-status.json"
echo ""
echo "To stop: Press Ctrl+C or run:"
echo "  kill $WEBUI_PID"
echo ""
echo "Test Scenarios:"
echo "  1. Simulate no internet:"
echo "     echo 'false' > $TEST_DIR/mock-internet.txt"
echo "     # Then check http://localhost:8765/api/status"
echo ""
echo "  2. Test network scan:"
echo "     curl http://localhost:8765/api/networks | jq"
echo ""
echo "  3. Test WiFi configuration:"
echo "     curl -X POST http://localhost:8765/api/configure \\"
echo "       -H 'Content-Type: application/json' \\"
echo "       -d '{\"ssid\":\"TestWiFi\",\"password\":\"testpass123\",\"encryption\":\"WPA2-PSK\"}'"
echo ""

# Also start network monitor in test mode (optional)
read -p "Start Network Monitor in test mode? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Starting Network Monitor..."
    cd "$PROJECT_DIR/scripts"
    MOCK_MODE=true python3 network-monitor.py &
    MONITOR_PID=$!
    echo "✓ Network Monitor started (PID: $MONITOR_PID)"
    echo ""
    echo "To stop monitor: kill $MONITOR_PID"
fi

echo ""
echo "Press Ctrl+C to stop all services"
echo ""

# Wait for Ctrl+C
trap "echo ''; echo 'Stopping services...'; kill $WEBUI_PID 2>/dev/null; [[ -n \$MONITOR_PID ]] && kill \$MONITOR_PID 2>/dev/null; echo 'Stopped.'; exit 0" INT

wait
