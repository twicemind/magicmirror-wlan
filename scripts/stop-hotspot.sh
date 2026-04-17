#!/bin/bash
#
# Stop HotSpot Mode
#
# Stoppt hostapd + dnsmasq und aktiviert normalen WLAN Client Mode

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INTERFACE="wlan0"

# Mock Mode
if [[ "${MOCK_MODE}" == "true" ]]; then
    echo "[MOCK] Stopping HotSpot"
    echo "false" > "$SCRIPT_DIR/../test/mock-hotspot-active.txt"
    exit 0
fi

echo "Stopping HotSpot..."

# Stop hostapd
echo "Stopping hostapd..."
killall hostapd 2>/dev/null || true

# Stop dnsmasq
echo "Stopping dnsmasq..."
killall dnsmasq 2>/dev/null || true

# Flush IP configuration
echo "Flushing interface $INTERFACE..."
ip addr flush dev "$INTERFACE"
ip link set "$INTERFACE" down

# Wait a moment
sleep 1

# Restart wpa_supplicant for normal WLAN mode
echo "Restarting wpa_supplicant..."
systemctl start wpa_supplicant || true

# Bring interface up
ip link set "$INTERFACE" up

# Request DHCP
echo "Requesting DHCP..."
dhcpcd "$INTERFACE" || true

echo "HotSpot stopped - switching to client mode"
