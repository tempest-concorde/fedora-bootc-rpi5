# fedora-bootc-rpi5

Headless Fedora bootc system optimized for ARM64 Raspberry Pi 5 with Tailscale VPN and WiFi management.

## Overview

This project creates a bootc-based headless system that automatically configures networking via WiFi and Tailscale VPN. The system includes:

- Headless operation (SSH access only)
- Automatic WiFi configuration via kickstart
- Tailscale VPN integration
- ARM64 optimized for Raspberry Pi 5
- Node Exporter monitoring
- Remote management capabilities

## Features

- **Headless Operation**: No GUI, SSH access only
- **WiFi Configuration**: Automatic setup of multiple WiFi networks via kickstart
- **Tailscale VPN**: Secure remote access and networking
- **ARM64 Optimized**: Built specifically for Raspberry Pi 5
- **Node Exporter Monitoring**: Built-in system metrics collection via Node Exporter
- **Network Management**: NetworkManager for robust network handling
- **Container Support**: Podman for containerized workloads

## Hardware Requirements

- Raspberry Pi 5 (ARM64)
- MicroSD card (32GB+ recommended)
- WiFi connectivity (onboard WiFi supported)
- Ethernet connection (optional, for initial setup)

## Configuration

### Environment Variables

Set these environment variables before building:

```shell
export SSH_KEY_PATH=$HOME/.ssh/id_rsa.pub
export DOCKER_AUTH_PATH=`pwd`/docker-auth.json
export TAILSCALE_AUTH_KEY=your-tailscale-auth-key
export WIFI_SSID_1=your-wifi-network
export WIFI_PSK_1=your-wifi-password
export WIFI_SSID_2=optional-second-network
export WIFI_PSK_2=optional-second-password
```

### WiFi Networks

The system supports configuring multiple WiFi networks during installation. Set the environment variables as shown above, and the kickstart will automatically configure NetworkManager connections.

### Tailscale Setup

1. Create an auth key in your Tailscale admin console
2. Set the `TAILSCALE_AUTH_KEY` environment variable
3. The system will automatically join your Tailnet during first boot

## Building

### Build Container Image (via GitHub Actions)

The container image is automatically built and pushed to Quay.io via GitHub Actions on ARM64 runners when you push to main or create releases.

### Create Raspberry Pi 5 Images Locally (with Secret Injection)

**Prerequisites**: Set up your environment variables with secrets:

```shell
export SSH_KEY_PATH=$HOME/.ssh/id_rsa.pub
export DOCKER_AUTH_PATH=`pwd`/docker-auth.json
export TAILSCALE_AUTH_KEY=your-tailscale-auth-key
export WIFI_SSID_1=your-wifi-network
export WIFI_PSK_1=your-wifi-password
# Optional secondary network
export WIFI_SSID_2=guest-network
export WIFI_PSK_2=guest-password
```

**Create Raspberry Pi 5 disk image:**
```shell
make rpi5-img
```

**Create ISO for USB boot:**
```shell
make iso
```

**Create QCOW2 for testing:**
```shell
make qcow
```

These commands use bootc image builder locally to create images with your secrets embedded at build time.

## Deployment

### SD Card Installation

1. Flash the generated image to a microSD card
2. Insert into Raspberry Pi 5
3. Boot and wait for WiFi/Tailscale configuration
4. SSH access will be available via configured networks

### USB Boot Installation

1. Create bootable USB with ISO
2. Boot Raspberry Pi 5 from USB
3. Follow installation prompts
4. System will reboot with configured networking

## System Access

### SSH Access

- **Method**: SSH key-based authentication only
- **User**: `root` (no additional users created)
- **Networks**: Available via WiFi and Tailscale
- **Key**: Configured during build with `SSH_KEY_PATH`

### Network Access

- **Local WiFi**: Configured networks from kickstart
- **Tailscale**: Automatic VPN access to your Tailnet
- **Monitoring**: Node Exporter metrics on port 9100

## Monitoring

The system includes Node Exporter for system metrics collection:

- **Node Exporter**: http://[device-ip]:9100/metrics
- **System Metrics**: Hardware and system metrics in Prometheus format

## Services

- `chronyd.service`: NTP time synchronization
- `tailscaled.service`: Tailscale VPN daemon
- `sshd.service`: SSH daemon
- `NetworkManager.service`: Network management
- Node Exporter container via Quadlet

## WiFi Management

WiFi connections are configured during installation via kickstart. Additional networks can be added post-installation using:

```shell
nmcli device wifi connect SSID password PASSWORD
```

## Tailscale Management

Tailscale is automatically configured during first boot. Manual management:

```shell
# Check status
tailscale status

# Add/remove from network
tailscale up --authkey=NEW_KEY
tailscale down
```

## Development

### Testing Locally

Use podman to test the container on ARM64 macOS:

```shell
# Build the container
podman build --platform=linux/arm64 -t fedora-bootc-rpi5:latest .

# Test run
podman run --rm -it --platform=linux/arm64 fedora-bootc-rpi5:latest /bin/bash
```

## GitHub Actions Secrets

The following secrets need to be configured in your GitHub repository:

- `TAILSCALE_AUTH_KEY`: Tailscale authentication key
- `DOCKER_AUTH_JSON`: Registry authentication for container pulls
- `SSH_PUBLIC_KEY`: SSH public key for root access
- `WIFI_SSID_1`: Primary WiFi network name
- `WIFI_PSK_1`: Primary WiFi network password
- `WIFI_SSID_2`: Secondary WiFi network name (optional)
- `WIFI_PSK_2`: Secondary WiFi network password (optional)

## Notes

1. **ARM64 Only**: This system is built specifically for ARM64 Raspberry Pi 5
2. **Headless**: No GUI components - SSH access required for administration
3. **Network Dependent**: Ensure WiFi credentials are correct for remote access
4. **Monitoring**: Grafana dashboard provides comprehensive system monitoring
5. **Updates**: System supports atomic updates via bootc
6. **Security**: SSH key-based authentication only, no password access
7. **Storage**: Optimized for SD card usage patterns
8. **Power**: Designed for 24/7 operation with proper power supply
