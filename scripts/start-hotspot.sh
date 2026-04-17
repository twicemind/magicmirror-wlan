#!/bin/bash
#
# Start HotSpot Mode
#
# Startet hostapd + dnsmasq für HotSpot-Betrieb
# SSID: MagicMirror-Setup
# IP Range: 192.168.4.0/24
# Password: magicmirror

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INTERFACE="wlan0"
HOTSPOT_IP="192.168.4.1"
HOTSPOT_SSID="MagicMirror-Setup"
HOTSPOT_PASSWORD="magicmirror"

# Mock Mode
if [[ "${MOCK_MODE}" == "true" ]]; then
    echo "[MOCK] Starting HotSpot on $INTERFACE"
    echo "[MOCK] SSID: $HOTSPOT_SSID"
    echo "[MOCK] IP: $HOTSPOT_IP"
    echo "true" > "$SCRIPT_DIR/../test/mock-hotspot-active.txt"
    exit 0
fi

echo "Starting HotSpot..."
echo "SSID: $HOTSPOT_SSID"
echo "Interface: $INTERFACE"

# Stop existing WLAN connections
echo "Stopping wpa_supplicant..."
systemctl stop wpa_supplicant || true
killall wpa_supplicant 2>/dev/null || true

# Wait a moment
sleep 1

# Configure interface
echo "Configuring interface $INTERFACE..."
ip addr flush dev "$INTERFACE"
ip addr add "${HOTSPOT_IP}/24" dev "$INTERFACE"
ip link set "$INTERFACE" up

# Start dnsmasq (DHCP + DNS)
echo "Starting dnsmasq..."
mkdir -p /var/run/dnsmasq

# Create dnsmasq config
cat > /tmp/dnsmasq-hotspot.conf <<EOF
interface=$INTERFACE
dhcp-range=192.168.4.10,192.168.4.100,24h
dhcp-option=3,$HOTSPOT_IP
dhcp-option=6,$HOTSPOT_IP
server=8.8.8.8
server=1.1.1.1
log-facility=/var/log/dnsmasq-hotspot.log
log-queries
bind-interfaces
EOF

dnsmasq -C /tmp/dnsmasq-hotspot.conf

# Start hostapd (WiFi AP)
echo "Starting hostapd..."

# Create hostapd config
cat > /tmp/hostapd-hotspot.conf <<EOF
interface=$INTERFACE
driver=nl80211
ssid=$HOTSPOT_SSID
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$HOTSPOT_PASSWORD
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF

hostapd -B /tmp/hostapd-hotspot.conf

# Enable IP forwarding (optional für Internet-Sharing via Ethernet)
echo 1 > /proc/sys/net/ipv4/ip_forward

echo "HotSpot started successfully!"
echo "Connect to: $HOTSPOT_SSID"
echo "Password: $HOTSPOT_PASSWORD"
echo "WebUI: http://$HOTSPOT_IP:8765"
