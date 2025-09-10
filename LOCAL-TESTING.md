# Local Testing Guide

This guide provides instructions for testing the Fedora bootc Raspberry Pi 5 system locally using podman on your ARM64 macOS system.

## Prerequisites

- ARM64 macOS system (M1/M2/M3 Mac)
- Podman installed and configured
- Docker Desktop or Colima (optional, for additional testing)
- Go (for gomplate template processing)

## Quick Start

### 1. Environment Setup

```bash
# Clone the repository
git clone https://github.com/tempest-concorde/fedora-bootc-rpi5.git
cd fedora-bootc-rpi5

# Set required environment variables
export SSH_KEY_PATH="$HOME/.ssh/id_rsa.pub"
export DOCKER_AUTH_PATH="$(pwd)/docker-auth.json"

# Optional environment variables
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

### 3. Basic Container Testing

```bash
# Build the container
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

# Generate config.toml
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

## Advanced Testing

### Multi-Architecture Build Test

```bash
# Test x86_64 build (for comparison)
podman build --platform=linux/amd64 -t fedora-bootc-rpi5:x86_64 .

# Compare architectures
podman run --rm --platform=linux/arm64 fedora-bootc-rpi5:test uname -m
podman run --rm --platform=linux/amd64 fedora-bootc-rpi5:x86_64 uname -m
```

### Image Size Optimization Test

```bash
# Check image size
podman images fedora-bootc-rpi5:test --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# Check layer sizes
podman history --format "table {{.CreatedBy}}\t{{.Size}}" fedora-bootc-rpi5:test
```

### Monitoring Stack Test

```bash
# Check monitoring configuration files
podman run --rm --platform=linux/arm64 fedora-bootc-rpi5:test \
    find /etc -name "*.container" -o -name "prometheus.yml" -o -name "grafana.ini"
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

## QEMU Testing (Alternative)

If you want to test the full bootc image:

```bash
# Generate QCOW2 for testing
make qcow

# The generated image will be in output/
ls -la output/

# Note: QEMU testing requires additional setup for ARM64 emulation on macOS
```

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

### Local CI Simulation

```bash
# Simulate the GitHub Actions workflow locally
export REGISTRY=localhost:5000
export IMAGE_NAME=fedora-bootc-rpi5

# Start local registry for testing
podman run -d -p 5000:5000 --name registry registry:2

# Build and push to local registry
make container
podman tag fedora-bootc-rpi5:latest localhost:5000/fedora-bootc-rpi5:latest
podman push localhost:5000/fedora-bootc-rpi5:latest

# Clean up
podman stop registry
podman rm registry
```

## Troubleshooting

### Common Issues

1. **Architecture Mismatch**
   ```bash
   # Verify you're building for ARM64
   podman build --platform=linux/arm64 --progress=plain .
   ```

2. **Permission Errors**
   ```bash
   # Check script permissions in container
   podman run --rm --platform=linux/arm64 fedora-bootc-rpi5:test \
       find /usr/local/bin -name "*.sh" -exec ls -la {} \;
   ```

3. **Missing Dependencies**
   ```bash
   # Verify all packages are installed
   podman run --rm --platform=linux/arm64 fedora-bootc-rpi5:test \
       rpm -qa | sort
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
# Time the build process
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
podman rmi fedora-bootc-rpi5:x86_64 2>/dev/null || true

# Clean up Docker auth file
rm -f docker-auth.json
```

## Integration with IDEs

### VS Code

Add to `.vscode/tasks.json`:

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Build Container",
            "type": "shell",
            "command": "make container",
            "group": "build",
            "problemMatcher": []
        },
        {
            "label": "Test Container",
            "type": "shell",
            "command": "make test-local",
            "group": "test",
            "problemMatcher": []
        }
    ]
}
```

This guide should help you thoroughly test the Raspberry Pi 5 bootc system locally before deploying to actual hardware.
