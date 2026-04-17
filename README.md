# MagicMirror WLAN Manager

🪞 **Automatisches WiFi-Management für MagicMirror auf Raspberry Pi**

Intelligent WLAN configuration system with automatic HotSpot fallback, web-based configuration interface, and QR code setup for MagicMirror installations.

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](VERSION)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Raspberry%20Pi-red.svg)](https://www.raspberrypi.org/)
[![Tests](https://github.com/twicemind/magicmirror-wlan/actions/workflows/test.yml/badge.svg)](https://github.com/twicemind/magicmirror-wlan/actions/workflows/test.yml)
[![Release](https://github.com/twicemind/magicmirror-wlan/actions/workflows/release.yml/badge.svg)](https://github.com/twicemind/magicmirror-wlan/actions/workflows/release.yml)

## Features

✨ **Automatic HotSpot** - Activates when no WiFi is configured or internet unavailable  
🌐 **Web Configuration** - Easy-to-use WebUI for WiFi network selection  
📱 **QR Code Setup** - Scan QR codes for instant HotSpot connection and WebUI access  
🔄 **Auto-Recovery** - Automatically switches between HotSpot and client mode  
🖼️ **MagicMirror Integration** - Shows setup instructions directly on your mirror  
🧪 **Fully Testable** - Complete local testing without Raspberry Pi  

## Quick Start

### Installation on Raspberry Pi

```bash
# Via Git
git clone https://github.com/twicemind/magicmirror-wlan.git
cd magicmirror-wlan
sudo bash install.sh

# Or one-line installation via curl
curl -sSL https://raw.githubusercontent.com/twicemind/magicmirror-wlan/main/install.sh | sudo bash
```

### Local Testing (Development)

```bash
# Clone repository
git clone https://github.com/twicemind/magicmirror-wlan.git
cd magicmirror-wlan

# Start test environment
bash test/test-environment.sh

# Access WebUI
open http://localhost:8765
```

## How It Works

```
┌─────────────────────────────────────────────────┐
│         No Internet Connection?                 │
│                                                 │
│  ┌─────────────────────────────────┐           │
│  │  1. HotSpot starts automatically │           │
│  └──────────────┬──────────────────┘           │
│                 │                               │
│                 ▼                               │
│  ┌─────────────────────────────────┐           │
│  │  2. MagicMirror shows QR codes  │           │
│  │     • Connect to HotSpot WiFi   │           │
│  │     • Open WebUI                │           │
│  └──────────────┬──────────────────┘           │
│                 │                               │
│                 ▼                               │
│  ┌─────────────────────────────────┐           │
│  │  3. User configures WiFi via    │           │
│  │     phone on WebUI              │           │
│  └──────────────┬──────────────────┘           │
│                 │                               │
│                 ▼                               │
│  ┌─────────────────────────────────┐           │
│  │  4. Raspberry connects to WiFi  │           │
│  │     HotSpot stops automatically │           │
│  │     MagicMirror shows normal UI │           │
│  └─────────────────────────────────┘           │
└─────────────────────────────────────────────────┘
```

## Components

### 1. Network Monitor Service
- Monitors internet connectivity every 30 seconds
- Automatically starts/stops HotSpot based on internet availability
- Provides status API for other components

### 2. HotSpot Manager
- Creates WiFi HotSpot using `hostapd` and `dnsmasq`
- Default credentials: SSID `MagicMirror-Setup`, Password `magicmirror`
- IP range: 192.168.4.0/24

### 3. WebUI (Port 8765)
- Web interface for WiFi configuration
- Features:
  - WiFi network scanner
  - Network selection and password entry
  - Status dashboard
  - QR code display

### 4. MagicMirror Module (MMM-WLANManager)
- Displays QR codes when no internet
- Shows setup instructions
- Auto-hides when connection established
- Runs on separate page (fullscreen_below)

## Project Structure

```
magicmirror-wlan/
├── scripts/                    # Core scripts
│   ├── network-monitor.py      # Network monitoring service
│   ├── start-hotspot.sh        # Start HotSpot
│   ├── stop-hotspot.sh         # Stop HotSpot
│   ├── configure-wlan.sh       # Configure WiFi
│   └── check-internet.sh       # Internet connectivity check
├── webui/                      # Web interface
│   ├── app.py                  # Flask application
│   ├── templates/              # HTML templates
│   └── static/                 # CSS, JavaScript
├── magicmirror-module/         # MagicMirror integration
│   └── MMM-WLANManager/        # MagicMirror module
├── services/                   # Systemd service files
├── test/                       # Test environment
├── docs/                       # Documentation
├── install.sh                  # Installation script
└── uninstall.sh                # Removal script
```

## Documentation

- **[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)** - Architecture and design
- **[INSTALLATION.md](INSTALLATION.md)** - Detailed installation guide
- **[test/README.md](test/README.md)** - Testing guide
- **[magicmirror-module/MMM-WLANManager/README.md](magicmirror-module/MMM-WLANManager/README.md)** - Module documentation

## Requirements

### Raspberry Pi
- Raspberry Pi 3, 4, or 5
- Raspberry Pi OS (Debian-based)
- WiFi adapter (built-in or USB)
- Python 3.9+

### Dependencies (auto-installed)
- hostapd
- dnsmasq
- Python 3 + Flask
- qrencode
- wireless-tools

## Configuration

### HotSpot Settings

Edit in [scripts/start-hotspot.sh](scripts/start-hotspot.sh):

```bash
HOTSPOT_SSID="MagicMirror-Setup"
HOTSPOT_PASSWORD="magicmirror"
HOTSPOT_IP="192.168.4.1"
```

### MagicMirror Integration

Add to your `config/config.js`:

```javascript
{
    module: "MMM-WLANManager",
    position: "fullscreen_below",
    config: {
        updateInterval: 30000,  // Check every 30 seconds
        apiUrl: "http://localhost:8765"
    }
}
```

## Testing

### Local Development

```bash
# Start test environment
bash test/test-environment.sh

# Simulate no internet
echo 'false' > test/mock-internet.txt

# Check status
curl http://localhost:8765/api/status | jq
```

See [test/README.md](test/README.md) for complete testing guide.

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/status` | GET | Network status |
| `/api/networks` | GET | Scan WiFi networks |
| `/api/configure` | POST | Configure WiFi |
| `/api/qr-data` | GET | Get QR code images |
| `/health` | GET | Health check |

## Usage

### Manual WebUI Access

1. **HotSpot Mode** (no internet):
   - Connect to WiFi: `MagicMirror-Setup`
   - Password: `magicmirror`
   - Open browser: http://192.168.4.1:8765

2. **Client Mode** (with internet):
   - Find Raspberry Pi IP address
   - Open browser: http://<raspberry-pi-ip>:8765

### Via MagicMirror

1. When internet unavailable, MagicMirror shows setup page
2. Scan QR code to connect to HotSpot
3. Scan second QR code to open WebUI
4. Configure WiFi
5. Mirror returns to normal view when connected

## Service Management

```bash
# Check service status
systemctl status network-monitor
systemctl status wlan-webui

# View logs
journalctl -u network-monitor -f
journalctl -u wlan-webui -f

# Restart services
sudo systemctl restart network-monitor
sudo systemctl restart wlan-webui
```

## Integration with magicmirror-setup

This project can be integrated with [magicmirror-setup](https://github.com/twicemind/magicmirror-setup):

```bash
# In magicmirror-setup directory
git clone https://github.com/twicemind/magicmirror-wlan.git
cd magicmirror-wlan
sudo bash install.sh
```

The WLAN manager will work alongside the existing magicmirror-setup installation.

## Roadmap

### v1.0.0 (Current)
- ✅ Automatic HotSpot with internet detection
- ✅ WebUI for WiFi configuration
- ✅ MagicMirror module with QR codes
- ✅ Full local testing support

### v1.1.0 (Planned)
- [ ] Multiple WiFi configuration (failover)
- [ ] Ethernet detection (disable HotSpot when wired)
- [ ] HTTPS support for WebUI
- [ ] Advanced logging and monitoring

### v1.2.0 (Future)
- [ ] Integration into magicmirror-setup WebUI
- [ ] Auto-update mechanism
- [ ] Mobile app (optional)

## License

MIT License - see [LICENSE](LICENSE) file.

## Author

**twicemind**

- GitHub: [@twicemind](https://github.com/twicemind)

## Acknowledgments

- [MagicMirror²](https://magicmirror.builders/) - The open source modular smart mirror platform
- [hostapd](https://w1.fi/hostapd/) - WiFi access point daemon
- [Flask](https://flask.palletsprojects.com/) - Python web framework

## Related Projects

- [magicmirror-setup](https://github.com/twicemind/magicmirror-setup) - Complete MagicMirror setup and management system

---

**Made with ❤️ for the MagicMirror community**