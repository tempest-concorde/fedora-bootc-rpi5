FROM quay.io/fedora/fedora-bootc:42

# Install packages for headless ARM64 Raspberry Pi 5 system
# Note: targeting ARM64 architecture for Raspberry Pi 5

# Add Tailscale repository
RUN curl -fsSL https://pkgs.tailscale.com/stable/fedora/tailscale.repo -o /etc/yum.repos.d/tailscale.repo

# Install essential packages for headless operation
RUN dnf install -y \
    chrony \
    podman \
    tailscale \
    curl \
    jq \
    NetworkManager-wifi \
    wpa_supplicant \
    iw \
    python3 \
    python3-pip \
    git \
    nano \
    vim \
    htop \
    rsync \
    tar \
    gzip \
    unzip && \
    dnf clean all

# Create directories for node-exporter monitoring
RUN mkdir -p /etc/containers/systemd

# Copy Quadlet configuration files for node-exporter only
COPY node-exporter.container /etc/containers/systemd/

# Copy WiFi configuration script
COPY wifi-setup.sh /usr/local/bin/
COPY tailscale-setup.sh /usr/local/bin/

# Set permissions and enable services
RUN chmod +x /usr/local/bin/wifi-setup.sh && \
    chmod +x /usr/local/bin/tailscale-setup.sh && \
    systemctl enable chronyd && \
    systemctl enable tailscaled && \
    systemctl enable sshd && \
    systemctl enable NetworkManager

# Run bootc container lint
RUN bootc container lint
