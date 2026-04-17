#!/bin/bash
#
# MagicMirror WLAN Manager - Installation Script
#
# Installation für Raspberry Pi
# Installiert Network Monitor, HotSpot Manager, WebUI und MagicMirror Modul

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/opt/magicmirror-wlan"
SERVICE_DIR="/etc/systemd/system"
USER="pi"  # Default user, can be changed
MM_DIR="/opt/mm"  # MagicMirror directory

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=================================="
echo "MagicMirror WLAN Manager"
echo "Installation Script v1.0.0"
echo "=================================="
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}"
   exit 1
fi

# Detect user if not pi
if ! id "pi" &>/dev/null; then
    echo -e "${YELLOW}User 'pi' not found. Please enter the username to run services:${NC}"
    read -p "Username: " USER
    
    if ! id "$USER" &>/dev/null; then
        echo -e "${RED}User $USER does not exist!${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Installing as user: $USER${NC}"

# 1. Install system dependencies
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: Installing system dependencies"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

apt-get update
apt-get install -y \
    hostapd \
    dnsmasq \
    python3 \
    python3-pip \
    python3-venv \
    wireless-tools \
    net-tools \
    qrencode \
    git

echo -e "${GREEN}✓ System dependencies installed${NC}"

# 2. Stop services that might interfere
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Preparing services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

systemctl stop hostapd || true
systemctl stop dnsmasq || true
systemctl disable hostapd || true
systemctl disable dnsmasq || true

echo -e "${GREEN}✓ Services prepared${NC}"

# 3. Copy files to installation directory
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Installing files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Copy project files
echo "Copying files to $INSTALL_DIR..."
cp -r "$SCRIPT_DIR/scripts" "$INSTALL_DIR/"
cp -r "$SCRIPT_DIR/webui" "$INSTALL_DIR/"
cp -r "$SCRIPT_DIR/config" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/VERSION" "$INSTALL_DIR/"

# Make scripts executable
chmod +x "$INSTALL_DIR/scripts/"*.sh
chmod +x "$INSTALL_DIR/scripts/"*.py

echo -e "${GREEN}✓ Files installed${NC}"

# 4. Setup Python virtual environment for WebUI
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4: Setting up Python environment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$INSTALL_DIR/webui"

# Create venv as user
su - "$USER" -c "cd $INSTALL_DIR/webui && python3 -m venv venv"

# Install Python dependencies as user
su - "$USER" -c "cd $INSTALL_DIR/webui && source venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt"

echo -e "${GREEN}✓ Python environment ready${NC}"

# 5. Setup systemd services
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 5: Installing systemd services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Update service files with correct user and paths
sed "s|/opt/magicmirror-wlan|$INSTALL_DIR|g; s|User=pi|User=$USER|g" \
    "$SCRIPT_DIR/services/network-monitor.service" > "$SERVICE_DIR/network-monitor.service"

sed "s|/opt/magicmirror-wlan|$INSTALL_DIR|g; s|User=pi|User=$USER|g" \
    "$SCRIPT_DIR/services/wlan-webui.service" > "$SERVICE_DIR/wlan-webui.service"

# Reload systemd
systemctl daemon-reload

# Enable and start services
systemctl enable network-monitor.service
systemctl enable wlan-webui.service

systemctl start wlan-webui.service
systemctl start network-monitor.service

echo -e "${GREEN}✓ Services installed and started${NC}"

# 6. Setup MagicMirror module (optional)
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 6: Installing MagicMirror module"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ -d "$MM_DIR" ]]; then
    MM_MODULES_DIR="$MM_DIR/modules"
    
    if [[ ! -d "$MM_MODULES_DIR/MMM-WLANManager" ]]; then
        echo "Installing MMM-WLANManager to $MM_MODULES_DIR..."
        cp -r "$SCRIPT_DIR/magicmirror-module/MMM-WLANManager" "$MM_MODULES_DIR/"
        
        # Install npm dependencies
        cd "$MM_MODULES_DIR/MMM-WLANManager"
        su - "$USER" -c "cd $MM_MODULES_DIR/MMM-WLANManager && npm install"
        
        echo -e "${GREEN}✓ MagicMirror module installed${NC}"
        echo -e "${YELLOW}⚠ Add the module to your MagicMirror config.js (see INSTALLATION.md)${NC}"
    else
        echo -e "${YELLOW}MMM-WLANManager already exists - skipping${NC}"
    fi
else
    echo -e "${YELLOW}MagicMirror not found at $MM_DIR - skipping module installation${NC}"
    echo "You can install the module manually later."
fi

# 7. Create log directory
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 7: Setting up logging"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mkdir -p /var/log/magicmirror-wlan
chown "$USER:$USER" /var/log/magicmirror-wlan

echo -e "${GREEN}✓ Logging configured${NC}"

# 8. Set permissions
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 8: Setting permissions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

chown -R "$USER:$USER" "$INSTALL_DIR"

# Allow user to run network scripts with sudo without password
SUDOERS_FILE="/etc/sudoers.d/$USER-magicmirror-wlan"
cat > "$SUDOERS_FILE" <<EOF
# Allow $USER to manage WLAN without password
$USER ALL=(ALL) NOPASSWD: $INSTALL_DIR/scripts/start-hotspot.sh
$USER ALL=(ALL) NOPASSWD: $INSTALL_DIR/scripts/stop-hotspot.sh
$USER ALL=(ALL) NOPASSWD: $INSTALL_DIR/scripts/configure-wlan.sh
$USER ALL=(ALL) NOPASSWD: /usr/sbin/iwlist
$USER ALL=(ALL) NOPASSWD: /sbin/ip
$USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart wpa_supplicant
EOF

chmod 0440 "$SUDOERS_FILE"

echo -e "${GREEN}✓ Permissions configured${NC}"

# 9. Show status
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Installation Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Service Status:"
systemctl status network-monitor.service --no-pager -l || true
echo ""
systemctl status wlan-webui.service --no-pager -l || true
echo ""

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Installation successful!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "What's Next:"
echo "1. Check service status: systemctl status network-monitor wlan-webui"
echo "2. View logs: journalctl -u network-monitor -f"
echo "3. Access WebUI: http://$(hostname -I | awk '{print $1}'):8765"
echo ""
echo "If you installed the MagicMirror module:"
echo "4. Add MMM-WLANManager to your config.js (see INSTALLATION.md)"
echo "5. Restart MagicMirror"
echo ""
echo "Troubleshooting: See docs/TROUBLESHOOTING.md"
echo ""
