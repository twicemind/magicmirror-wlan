# Installation Guide

Complete installation guide for MagicMirror WLAN Manager.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Automatic Installation](#automatic-installation)
3. [Manual Installation](#manual-installation)
4. [MagicMirror Configuration](#magicmirror-configuration)
5. [Post-Installation](#post-installation)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### Hardware
- Raspberry Pi 3, 4, or 5
- WiFi adapter (built-in or USB)
- SD card with Raspberry Pi OS
- Optional: MagicMirror installation

### Software
- Raspberry Pi OS (Bullseye or newer)
- Root/sudo access
- Internet connection (for installation)

### Check Requirements

```bash
# Check OS version
cat /etc/os-release

# Check Python version (should be 3.9+)
python3 --version

# Check WiFi adapter
iwconfig

# Check if running as root
sudo whoami
```

## Automatic Installation

### Method 1: Git Clone + Install

```bash
# Clone repository
git clone https://github.com/twicemind/magicmirror-wlan.git
cd magicmirror-wlan

# Run installation
sudo bash install.sh
```

### Method 2: One-Line Installation

```bash
curl -sSL https://raw.githubusercontent.com/twicemind/magicmirror-wlan/main/install.sh | sudo bash
```

The installer will:
1. Install system dependencies (hostapd, dnsmasq, Python packages)
2. Copy files to `/opt/magicmirror-wlan`
3. Create Python virtual environment
4. Install systemd services
5. Configure permissions
6. Start services automatically

**Installation takes ~5-10 minutes depending on internet speed.**

## Manual Installation

If the automatic installer fails or you prefer manual installation:

### Step 1: Install Dependencies

```bash
sudo apt-get update
sudo apt-get install -y \
    hostapd \
    dnsmasq \
    python3 \
    python3-pip \
    python3-venv \
    wireless-tools \
    net-tools \
    qrencode \
    git
```

### Step 2: Clone Repository

```bash
cd /opt
sudo git clone https://github.com/twicemind/magicmirror-wlan.git
cd magicmirror-wlan
```

### Step 3: Setup Python Environment

```bash
cd /opt/magicmirror-wlan/webui
sudo -u pi python3 -m venv venv
sudo -u pi bash -c "source venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt"
```

### Step 4: Install Systemd Services

```bash
# Copy service files
sudo cp services/network-monitor.service /etc/systemd/system/
sudo cp services/wlan-webui.service /etc/systemd/system/

# If needed, adjust paths in service files
sudo nano /etc/systemd/system/network-monitor.service
sudo nano /etc/systemd/system/wlan-webui.service

# Reload systemd
sudo systemctl daemon-reload

# Enable services
sudo systemctl enable network-monitor.service
sudo systemctl enable wlan-webui.service

# Start services
sudo systemctl start wlan-webui.service
sudo systemctl start network-monitor.service
```

### Step 5: Configure Permissions

```bash
# Set ownership
sudo chown -R pi:pi /opt/magicmirror-wlan

# Make scripts executable
sudo chmod +x /opt/magicmirror-wlan/scripts/*.sh
sudo chmod +x /opt/magicmirror-wlan/scripts/*.py

# Create sudoers file (adjust username if not 'pi')
sudo tee /etc/sudoers.d/pi-magicmirror-wlan <<EOF
pi ALL=(ALL) NOPASSWD: /opt/magicmirror-wlan/scripts/start-hotspot.sh
pi ALL=(ALL) NOPASSWD: /opt/magicmirror-wlan/scripts/stop-hotspot.sh
pi ALL=(ALL) NOPASSWD: /opt/magicmirror-wlan/scripts/configure-wlan.sh
pi ALL=(ALL) NOPASSWD: /usr/sbin/iwlist
pi ALL=(ALL) NOPASSWD: /sbin/ip
pi ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart wpa_supplicant
EOF

sudo chmod 0440 /etc/sudoers.d/pi-magicmirror-wlan
```

### Step 6: Create Log Directory

```bash
sudo mkdir -p /var/log/magicmirror-wlan
sudo chown pi:pi /var/log/magicmirror-wlan
```

## MagicMirror Configuration

### Install MagicMirror Module

If you have MagicMirror installed:

```bash
# Copy module to MagicMirror modules directory
cd /opt/mm/modules
sudo cp -r /opt/magicmirror-wlan/magicmirror-module/MMM-WLANManager .
cd MMM-WLANManager

# Install node dependencies
npm install
```

### Configure MagicMirror

Edit your MagicMirror config file:

```bash
nano /opt/mm/config/config.js
```

Add the module:

```javascript
{
    module: "MMM-WLANManager",
    position: "fullscreen_below",  // Shows on separate page
    config: {
        updateInterval: 30000,      // Check every 30 seconds
        apiUrl: "http://localhost:8765",  // WebUI API
        showWhenOnline: false,      // Hide when internet available
    }
}
```

### Optional: Configure Pages

If using MMM-pages or similar module for page rotation:

```javascript
{
    module: "MMM-pages",
    config: {
        modules: [
            ["clock", "weather", "calendar"],  // Page 0 (normal)
            ["MMM-WLANManager"]                // Page 1 (WiFi setup)
        ],
        fixed: []
    }
}
```

### Restart MagicMirror

```bash
# If using Docker
docker restart magicmirror

# If using PM2
pm2 restart magicmirror

# If using systemd
sudo systemctl restart magicmirror
```

## Post-Installation

### Verify Installation

```bash
# Check services are running
sudo systemctl status network-monitor
sudo systemctl status wlan-webui

# Test WebUI
curl http://localhost:8765/health

# View logs
journalctl -u network-monitor -n 20
journalctl -u wlan-webui -n 20
```

### Access WebUI

Find your Raspberry Pi IP address:

```bash
hostname -I
```

Open browser:
- http://YOUR_RASPBERRY_IP:8765

### Test HotSpot Functionality

```bash
# Simulate no internet (for testing)
sudo systemctl stop network-manager
# OR disconnect ethernet

# Wait ~30 seconds
# HotSpot should start automatically

# Check if HotSpot is active
ps aux | grep hostapd

# On your phone:
# - Connect to WiFi "MagicMirror-Setup"
# - Password: "magicmirror"
# - Open http://192.168.4.1:8765
```

## Customization

### Change HotSpot Credentials

Edit `scripts/start-hotspot.sh`:

```bash
sudo nano /opt/magicmirror-wlan/scripts/start-hotspot.sh

# Change these lines:
HOTSPOT_SSID="YourCustomSSID"
HOTSPOT_PASSWORD="YourSecurePassword"  # Min 8 characters
```

### Change WebUI Port

Edit `webui/app.py`:

```bash
sudo nano /opt/magicmirror-wlan/webui/app.py

# Change:
PORT = 8765  # To your preferred port
```

Then update systemd service and restart:

```bash
sudo systemctl restart wlan-webui
```

## Uninstallation

```bash
cd /opt/magicmirror-wlan
sudo bash uninstall.sh
```

This will:
- Stop and disable services
- Remove systemd service files
- Remove installation directory
- Remove MagicMirror module
- Remove sudoers configuration
- Remove logs

## Troubleshooting

### Services Not Starting

```bash
# Check service status
sudo systemctl status network-monitor --no-pager -l
sudo systemctl status wlan-webui --no-pager -l

# Check logs
sudo journalctl -u network-monitor -n 50
sudo journalctl -u wlan-webui -n 50

# Restart services
sudo systemctl restart network-monitor
sudo systemctl restart wlan-webui
```

### HotSpot Not Working

```bash
# Check if WiFi is blocked
sudo rfkill list all

# Unblock if necessary
sudo rfkill unblock wlan

# Check hostapd configuration
sudo hostapd -dd /tmp/hostapd-hotspot.conf

# Check dnsmasq
sudo dnsmasq -C /tmp/dnsmasq-hotspot.conf --no-daemon
```

### WebUI Not Accessible

```bash
# Check if Python venv is working
cd /opt/magicmirror-wlan/webui
source venv/bin/activate
python --version
pip list

# Test Flask app directly
MOCK_MODE=true python app.py

# Check firewall
sudo iptables -L -n | grep 8765
```

### Permission Errors

```bash
# Fix ownership
sudo chown -R pi:pi /opt/magicmirror-wlan

# Fix script permissions
sudo chmod +x /opt/magicmirror-wlan/scripts/*.sh
sudo chmod +x /opt/magicmirror-wlan/scripts/*.py

# Check sudoers file
sudo visudo -c
sudo cat /etc/sudoers.d/pi-magicmirror-wlan
```

## Upgrade

To upgrade to a newer version:

```bash
cd /opt/magicmirror-wlan

# Backup current config
sudo cp -r config config.backup

# Pull latest changes
sudo git pull

# Restart services
sudo systemctl restart network-monitor
sudo systemctl restart wlan-webui

# Update MagicMirror module if installed
cd /opt/mm/modules/MMM-WLANManager
sudo git pull
npm install
```

## Next Steps

- **Configure WiFi**: Connect to HotSpot and configure your WiFi
- **Customize**: Adjust HotSpot credentials and settings
- **Monitor**: Check logs and service status regularly
- **Integrate**: Add to your MagicMirror setup

## Support

For issues and questions:
- GitHub Issues: https://github.com/twicemind/magicmirror-wlan/issues
- Documentation: /opt/magicmirror-wlan/docs/
