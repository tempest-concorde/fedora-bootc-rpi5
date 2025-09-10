#!/bin/bash

# WiFi setup script for Raspberry Pi 5 bootc system
# This script configures WiFi networks using NetworkManager

set -euo pipefail

WIFI_CONFIG_DIR="/etc/NetworkManager/system-connections"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

setup_wifi_connection() {
    local ssid="$1"
    local psk="$2"
    local priority="${3:-0}"
    
    log "Setting up WiFi connection for SSID: $ssid"
    
    # Create NetworkManager connection file
    cat > "${WIFI_CONFIG_DIR}/${ssid}.nmconnection" << EOF
[connection]
id=${ssid}
uuid=$(uuidgen)
type=wifi
autoconnect=true
autoconnect-priority=${priority}

[wifi]
mode=infrastructure
ssid=${ssid}

[wifi-security]
auth-alg=open
key-mgmt=wpa-psk
psk=${psk}

[ipv4]
method=auto

[ipv6]
method=auto
addr-gen-mode=stable-privacy
EOF

    # Set proper permissions
    chmod 600 "${WIFI_CONFIG_DIR}/${ssid}.nmconnection"
    log "WiFi connection configured for SSID: $ssid"
}

# Wait for NetworkManager to be ready
log "Waiting for NetworkManager to be ready..."
while ! systemctl is-active --quiet NetworkManager; do
    sleep 1
done

# Create system connections directory if it doesn't exist
mkdir -p "$WIFI_CONFIG_DIR"

# Configure WiFi networks from environment variables
if [ -n "${WIFI_SSID_1:-}" ] && [ -n "${WIFI_PSK_1:-}" ]; then
    setup_wifi_connection "$WIFI_SSID_1" "$WIFI_PSK_1" 10
fi

if [ -n "${WIFI_SSID_2:-}" ] && [ -n "${WIFI_PSK_2:-}" ]; then
    setup_wifi_connection "$WIFI_SSID_2" "$WIFI_PSK_2" 5
fi

# Reload NetworkManager to pick up new connections
log "Reloading NetworkManager configuration..."
nmcli connection reload

# Enable WiFi if it's disabled
nmcli radio wifi on

log "WiFi setup completed successfully"
