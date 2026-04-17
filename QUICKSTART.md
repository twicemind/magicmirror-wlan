# Quick Start Guide

Get up and running with MagicMirror WLAN Manager in 5 minutes.

## For Raspberry Pi Users

### 1. Install

```bash
curl -sSL https://raw.githubusercontent.com/twicemind/magicmirror-wlan/main/install.sh | sudo bash
```

### 2. Verify

```bash
# Check services are running
systemctl status network-monitor wlan-webui

# Access WebUI
# Get your Pi's IP:
hostname -I
# Open http://YOUR_IP:8765 in browser
```

### 3. Test HotSpot

```bash
# Disconnect from WiFi to trigger HotSpot
sudo systemctl stop NetworkManager

# Wait 30 seconds
# HotSpot "MagicMirror-Setup" should appear

# Connect with phone:
# - WiFi: MagicMirror-Setup
# - Password: magicmirror
# - Open: http://192.168.4.1:8765
```

### 4. Add MagicMirror Module

Edit `/opt/mm/config/config.js`:

```javascript
{
    module: "MMM-WLANManager",
    position: "fullscreen_below",
    config: {
        updateInterval: 30000,
        apiUrl: "http://localhost:8765"
    }
}
```

Restart MagicMirror:
```bash
docker restart magicmirror
```

## For Local Development

### 1. Clone & Setup

```bash
git clone https://github.com/twicemind/magicmirror-wlan.git
cd magicmirror-wlan
```

### 2. Start Test Environment

```bash
bash test/test-environment.sh
```

This starts:
- WebUI on http://localhost:8765
- Mock network monitor

### 3. Open WebUI

```bash
open http://localhost:8765
```

### 4. Test Scenarios

```bash
# Simulate no internet
echo 'false' > test/mock-internet.txt

# Check status
curl http://localhost:8765/api/status | jq

# Simulate internet back
echo 'true' > test/mock-internet.txt
```

## What You Get

✅ Automatic HotSpot when no internet  
✅ Web interface for WiFi configuration  
✅ QR codes for easy phone setup  
✅ MagicMirror integration with auto-hide  
✅ Fully testable locally  

## Next Steps

- **Production**: See [INSTALLATION.md](INSTALLATION.md) for detailed setup
- **Development**: See [test/README.md](test/README.md) for testing guide
- **API**: See WebUI at http://localhost:8765 for network configuration

## Common Commands

```bash
# Check status
systemctl status network-monitor wlan-webui

# View logs
journalctl -u network-monitor -f

# Restart services
sudo systemctl restart network-monitor wlan-webui

# Access WebUI
http://YOUR_RASPBERRY_IP:8765

# Uninstall
sudo bash uninstall.sh
```

## Support

- **Issues**: [GitHub Issues](https://github.com/twicemind/magicmirror-wlan/issues)
- **Docs**: See [README.md](README.md) for full documentation
