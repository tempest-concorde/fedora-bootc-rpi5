# Changelog

All notable changes to the Fedora bootc Raspberry Pi 5 project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial implementation of headless Fedora bootc system for Raspberry Pi 5
- ARM64 architecture support and optimization
- Tailscale VPN integration with automatic setup
- WiFi configuration via kickstart with support for multiple networks
- Monitoring stack (Prometheus, Grafana, Node Exporter) via Quadlet
- NetworkManager-based network management
- SSH key-based authentication for root access
- Automated container and image builds via GitHub Actions
- Local testing support with podman on ARM64 macOS
- Comprehensive documentation and setup instructions

### Features
- **Headless Operation**: No GUI components, optimized for remote management
- **Multi-Network WiFi**: Support for configuring multiple WiFi networks during installation
- **Tailscale Integration**: Automatic VPN setup with auth key from environment
- **Container-Ready**: Podman support for running containerized workloads
- **Monitoring**: Built-in system monitoring accessible via web interface
- **Security**: SSH key-only authentication, no password access
- **ARM64 Optimized**: Built specifically for Raspberry Pi 5 performance characteristics

### Infrastructure
- GitHub Actions workflow for automated ARM64 container builds
- Multi-stage build process supporting ISO, raw disk images, and QCOW2
- Container registry integration with Quay.io
- Automated release creation with artifacts
- Local development and testing environment setup

## [1.0.0] - 2025-01-XX (Planned)

### Initial Release
- Stable release of Raspberry Pi 5 bootc system
- Production-ready networking and monitoring
- Complete documentation and deployment guides
