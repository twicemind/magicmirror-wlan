#!/bin/bash
#
# MagicMirror WLAN Manager - Deinstallation
#
# Entfernt alle Komponenten

set -e

INSTALL_DIR="/opt/magicmirror-wlan"
SERVICE_DIR="/etc/systemd/system"
MM_DIR="/opt/mm"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "=================================="
echo "MagicMirror WLAN Manager"
echo "Uninstallation Script"
echo "=================================="
echo ""

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}"
   exit 1
fi

read -p "Are you sure you want to uninstall MagicMirror WLAN Manager? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Stop and disable services
echo "Stopping services..."
systemctl stop network-monitor.service || true
systemctl stop wlan-webui.service || true
systemctl disable network-monitor.service || true
systemctl disable wlan-webui.service || true

# Remove service files
echo "Removing service files..."
rm -f "$SERVICE_DIR/network-monitor.service"
rm -f "$SERVICE_DIR/wlan-webui.service"

systemctl daemon-reload

# Remove installation directory
echo "Removing installation files..."
rm -rf "$INSTALL_DIR"

# Remove MagicMirror module
if [[ -d "$MM_DIR/modules/MMM-WLANManager" ]]; then
    echo "Removing MagicMirror module..."
    rm -rf "$MM_DIR/modules/MMM-WLANManager"
fi

# Remove sudoers file
SUDOERS_FILES=(/etc/sudoers.d/*-magicmirror-wlan)
if [[ -f "${SUDOERS_FILES[0]}" ]]; then
    echo "Removing sudoers configuration..."
    rm -f "${SUDOERS_FILES[@]}"
fi

# Remove logs
echo "Removing logs..."
rm -rf /var/log/magicmirror-wlan

# Clean up temp files
rm -f /tmp/wlan-status.json
rm -f /tmp/hostapd-hotspot.conf
rm -f /tmp/dnsmasq-hotspot.conf

echo ""
echo -e "${GREEN}✓ Uninstallation complete${NC}"
echo ""
echo "Note: System packages (hostapd, dnsmasq, etc.) were NOT removed."
echo "You can remove them manually if needed:"
echo "  sudo apt-get remove hostapd dnsmasq"
echo ""
