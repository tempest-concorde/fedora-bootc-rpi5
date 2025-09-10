#!/bin/bash

# Tailscale setup script for Raspberry Pi 5 bootc system
# This script configures Tailscale VPN connection

set -euo pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

# Check if Tailscale auth key is provided
if [ -z "${TAILSCALE_AUTH_KEY:-}" ]; then
    log "No TAILSCALE_AUTH_KEY provided, skipping Tailscale setup"
    exit 0
fi

log "Setting up Tailscale..."

# Wait for tailscaled service to be ready
log "Waiting for tailscaled service to be ready..."
while ! systemctl is-active --quiet tailscaled; do
    sleep 1
done

# Wait a bit more for the daemon to fully initialize
sleep 5

# Get the hostname for Tailscale
HOSTNAME=$(hostname)
if [ "$HOSTNAME" = "localhost.localdomain" ] || [ "$HOSTNAME" = "localhost" ]; then
    HOSTNAME="rpi5-$(head /dev/urandom | tr -dc a-z0-9 | head -c 8)"
    log "Using generated hostname: $HOSTNAME"
fi

# Join Tailscale network
log "Joining Tailscale network with hostname: $HOSTNAME"
if tailscale up \
    --authkey="$TAILSCALE_AUTH_KEY" \
    --accept-routes \
    --accept-dns=false \
    --hostname="$HOSTNAME" \
    --timeout=60s; then
    
    log "Successfully joined Tailscale network"
    
    # Display Tailscale status
    tailscale status
    
else
    log "Failed to join Tailscale network"
    exit 1
fi

# Enable IP forwarding if needed (for subnet routing)
if [ "${TAILSCALE_ENABLE_ROUTING:-false}" = "true" ]; then
    log "Enabling IP forwarding for subnet routing"
    echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
    echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.conf
    sysctl -p
fi

log "Tailscale setup completed successfully"
