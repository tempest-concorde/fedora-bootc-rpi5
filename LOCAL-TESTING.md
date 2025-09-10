# Local Testing Guide

This guide provides instructions for testing the Fedora bootc Raspberry Pi 5 system locally using podman on your ARM64 macOS system.

## Prerequisites

- ARM64 macOS system (M1/M2/M3 Mac)
- Podman installed and configured
- Go (for gomplate template processing)

## Quick Start

### 1. Environment Setup

```bash
# Clone the repository
git clone https://github.com/tempest-concorde/fedora-bootc-rpi5.git
cd fedora-bootc-rpi5

# Set required environment variables for testing
export SSH_KEY_PATH="$HOME/.ssh/id_rsa.pub"
export DOCKER_AUTH_PATH="$(pwd)/docker-auth.json"

# Optional environment variables (for full image building)
export TAILSCALE_AUTH_KEY="tskey-auth-your-key-here"
export WIFI_SSID_1="Your-WiFi-Network"
export WIFI_PSK_1="your-wifi-password"
```

### 2. Create Docker Auth File

```bash
# Create a minimal docker auth file for testing
cat > docker-auth.json << 'EOF'
{
  "auths": {}
}
EOF
```

### 3. Container Testing

The GitHub Actions workflow now runs on ARM64 runners and only builds container images. Local testing focuses on container functionality:

```bash
# Build the container locally (GitHub Actions does this automatically)
make container

# Test the container interactively
make test-local
```

## Detailed Testing

### Container Build Test

```bash
# Build with verbose output
podman build --platform=linux/arm64 -t fedora-bootc-rpi5:test .

# Check the built image
podman images | grep fedora-bootc-rpi5

# Inspect the image layers
podman history fedora-bootc-rpi5:test
```

### Container Runtime Test

```bash
# Run container and check installed packages
podman run --rm --platform=linux/arm64 fedora-bootc-rpi5:test rpm -qa | grep -E "(tailscale|NetworkManager)"

# Check system services configuration
podman run --rm --platform=linux/arm64 fedora-bootc-rpi5:test systemctl list-unit-files --state=enabled

# Test script permissions
podman run --rm --platform=linux/arm64 fedora-bootc-rpi5:test ls -la /usr/local/bin/
```

### Bootc Lint Test

```bash
# Run bootc container lint
podman run --rm --platform=linux/arm64 fedora-bootc-rpi5:test bootc container lint
```

### Configuration Generation Test

```bash
# Install gomplate
go install github.com/hairyhenderson/gomplate/v3/cmd/gomplate@latest

# Generate config.toml (requires environment variables to be set)
make toml

# Check generated configuration
cat config.toml
```

### Network Stack Test

```bash
# Test NetworkManager installation
podman run --rm --platform=linux/arm64 fedora-bootc-rpi5:test \
    bash -c "rpm -q NetworkManager-wifi wpa_supplicant"

# Test Tailscale installation
podman run --rm --platform=linux/arm64 fedora-bootc-rpi5:test \
    bash -c "tailscale version"
```

### Script Testing

```bash
# Test WiFi setup script syntax
podman run --rm --platform=linux/arm64 fedora-bootc-rpi5:test \
    bash -n /usr/local/bin/wifi-setup.sh

# Test Tailscale setup script syntax
podman run --rm --platform=linux/arm64 fedora-bootc-rpi5:test \
    bash -n /usr/local/bin/tailscale-setup.sh
```

### Node Exporter Test

```bash
# Test that node-exporter container config exists
podman run --rm --platform=linux/arm64 fedora-bootc-rpi5:test \
    test -f /etc/containers/systemd/node-exporter.container

# Check node-exporter configuration
podman run --rm --platform=linux/arm64 fedora-bootc-rpi5:test \
    cat /etc/containers/systemd/node-exporter.container
```

## Local Image Building (with Secret Injection)

The new workflow separates container building (automated via GitHub Actions) from image building (local with secrets):

### Set Environment Variables

```bash
# Required for local image building
export SSH_KEY_PATH="$HOME/.ssh/id_rsa.pub"
export DOCKER_AUTH_PATH="$(pwd)/docker-auth.json"
export TAILSCALE_AUTH_KEY="tskey-auth-your-key-here"
export WIFI_SSID_1="Your-WiFi-Network"
export WIFI_PSK_1="your-wifi-password"
# Optional secondary network
export WIFI_SSID_2="Guest-Network"
export WIFI_PSK_2="guest-password"
```

### Build Images with Secrets

```bash
# Create Raspberry Pi 5 disk image with secrets embedded
make rpi5-img

# Create ISO with secrets embedded
make iso

# Create QCOW2 for testing with secrets embedded
make qcow

# Build all image types
make build-images
```

### What Changed

**Before**: GitHub Actions built container images AND disk images/ISOs
**Now**: 
- GitHub Actions (ARM64 runners) build ONLY container images
- Local bootc image builder creates disk images/ISOs with secrets injected at build time
- Secrets are embedded during the bootc image building process, not in the container

## Advanced Testing

### Multi-Architecture Build Test

```bash
# The container is now ARM64 only, optimized for Raspberry Pi 5
podman run --rm --platform=linux/arm64 fedora-bootc-rpi5:test uname -m
# Should output: aarch64
```

### Image Size Optimization Test

```bash
# Check image size (should be smaller without Prometheus/Grafana)
podman images fedora-bootc-rpi5:test --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# Check layer sizes
podman history --format "table {{.CreatedBy}}\t{{.Size}}" fedora-bootc-rpi5:test
```

### Development Workflow

```bash
# Full development test cycle
make clean
make lint
make dev-build
make dev-test

# Show current configuration
make show-config
```

## Testing the ARM64 GitHub Actions Build

The GitHub Actions now runs on `ubuntu-24.04-arm64` runners:

```yaml
runs-on: ubuntu-24.04-arm64  # Native ARM64 runners
```

You can test this by:

1. Push to a branch or create a PR
2. GitHub Actions will build the container on native ARM64
3. The build will be faster and more efficient than cross-compilation

## Continuous Testing

### Pre-commit Testing Script

Create `.git/hooks/pre-push`:

```bash
#!/bin/bash
set -e

echo "Running pre-push tests..."

# Lint check
make lint

# Container build test
make container

# Basic runtime test
make test-local <<< "exit"

echo "All tests passed!"
```

Make it executable:
```bash
chmod +x .git/hooks/pre-push
```

## Troubleshooting

### Common Issues

1. **Architecture Mismatch**
   ```bash
   # Verify you're building for ARM64
   podman build --platform=linux/arm64 --progress=plain .
   ```

2. **Missing Node Exporter**
   ```bash
   # Check that only node-exporter is configured (no Prometheus/Grafana)
   podman run --rm --platform=linux/arm64 fedora-bootc-rpi5:test \
       ls -la /etc/containers/systemd/
   # Should only show node-exporter.container
   ```

3. **Permission Errors**
   ```bash
   # Check script permissions in container
   podman run --rm --platform=linux/arm64 fedora-bootc-rpi5:test \
       find /usr/local/bin -name "*.sh" -exec ls -la {} \;
   ```

### Debug Commands

```bash
# Interactive debugging session
podman run --rm -it --platform=linux/arm64 fedora-bootc-rpi5:test /bin/bash

# Check system services
podman run --rm --platform=linux/arm64 fedora-bootc-rpi5:test \
    systemctl list-unit-files --type=service

# Check installed files
podman run --rm --platform=linux/arm64 fedora-bootc-rpi5:test \
    find /usr/local/bin /etc/containers/systemd -type f
```

## Performance Testing

```bash
# Time the build process (should be faster on ARM64 with less monitoring)
time make container

# Check resource usage during build
podman system df

# Memory usage test
podman run --rm --platform=linux/arm64 --memory=512m fedora-bootc-rpi5:test \
    bash -c "free -h && df -h"
```

## Cleanup

```bash
# Clean up all test artifacts
make clean

# Remove test images
podman rmi fedora-bootc-rpi5:test 2>/dev/null || true

# Clean up Docker auth file
rm -f docker-auth.json
```

## Summary of Changes

1. **GitHub Actions**: Now uses ARM64 runners (`ubuntu-24.04-arm64`)
2. **Container Only**: GitHub Actions builds only the container image
3. **Local Image Building**: Use `make iso`, `make rpi5-img` locally with secrets
4. **Monitoring**: Removed Prometheus/Grafana, kept only Node Exporter
5. **Secret Injection**: Secrets are injected during bootc image build, not in container