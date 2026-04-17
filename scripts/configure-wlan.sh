#!/bin/bash
#
# Configure WLAN
#
# Fügt WLAN-Konfiguration zu wpa_supplicant.conf hinzu
# Usage: configure-wlan.sh <ssid> <password> [encryption]

set -e

SSID="$1"
PASSWORD="$2"
ENCRYPTION="${3:-WPA-PSK}"  # Default: WPA-PSK
WPA_CONF="/etc/wpa_supplicant/wpa_supplicant.conf"

# Mock Mode
if [[ "${MOCK_MODE}" == "true" ]]; then
    MOCK_WPA_CONF="$(dirname "$0")/../test/mock-wpa_supplicant.conf"
    mkdir -p "$(dirname "$MOCK_WPA_CONF")"
    WPA_CONF="$MOCK_WPA_CONF"
    echo "[MOCK] Configuring WLAN: $SSID"
fi

# Validation
if [[ -z "$SSID" || -z "$PASSWORD" ]]; then
    echo "Usage: $0 <ssid> <password> [encryption]"
    exit 1
fi

if [[ ${#PASSWORD} -lt 8 ]]; then
    echo "Error: Password must be at least 8 characters"
    exit 1
fi

echo "Configuring WLAN..."
echo "SSID: $SSID"
echo "Encryption: $ENCRYPTION"

# Create backup
if [[ -f "$WPA_CONF" ]]; then
    cp "$WPA_CONF" "${WPA_CONF}.backup.$(date +%Y%m%d-%H%M%S)"
fi

# Generate WPA PSK
if [[ "$ENCRYPTION" == "WPA-PSK" || "$ENCRYPTION" == "WPA2-PSK" ]]; then
    # Use wpa_passphrase to generate config
    WPA_CONFIG=$(wpa_passphrase "$SSID" "$PASSWORD")
else
    # Open network (no encryption)
    WPA_CONFIG="network={
    ssid=\"$SSID\"
    key_mgmt=NONE
}"
fi

# Add to wpa_supplicant.conf if not already present
if ! grep -q "ssid=\"$SSID\"" "$WPA_CONF" 2>/dev/null; then
    echo "" >> "$WPA_CONF"
    echo "$WPA_CONFIG" >> "$WPA_CONF"
    echo "WLAN configuration added to $WPA_CONF"
else
    echo "WLAN $SSID already configured - skipping"
fi

# Set highest priority (connect to this network first)
# This will be handled by wpa_supplicant priority field in production

if [[ "${MOCK_MODE}" != "true" ]]; then
    # Restart wpa_supplicant to apply changes
    echo "Restarting wpa_supplicant..."
    systemctl restart wpa_supplicant || wpa_cli -i wlan0 reconfigure
    
    # Wait for connection
    echo "Waiting for connection (up to 15 seconds)..."
    for i in {1..15}; do
        if iwgetid -r &>/dev/null; then
            CONNECTED_SSID=$(iwgetid -r)
            echo "Connected to: $CONNECTED_SSID"
            
            # Get IP
            sleep 2
            IP=$(ip -4 addr show wlan0 | grep inet | awk '{print $2}' | cut -d/ -f1)
            if [[ -n "$IP" ]]; then
                echo "IP Address: $IP"
            fi
            
            exit 0
        fi
        sleep 1
    done
    
    echo "Warning: Connection not established within timeout"
    echo "Check logs: journalctl -u wpa_supplicant -n 50"
fi

echo "WLAN configured successfully"
