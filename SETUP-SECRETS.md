# GitHub Actions Secrets Setup

This document provides instructions for setting up the required GitHub Actions secrets for the Fedora bootc Raspberry Pi 5 project.

## Prerequisites

- GitHub CLI (`gh`) installed and authenticated
- Access to a Quay.io account for container registry
- Tailscale account with auth key generation capability
- SSH key pair for system access
- WiFi network credentials

## Required Secrets

The following secrets must be configured in your GitHub repository:

### Container Registry Secrets

1. **QUAY_USERNAME** - Your Quay.io username
2. **QUAY_TOKEN** - Quay.io access token with push permissions
3. **DOCKER_AUTH_JSON** - Docker/Podman authentication configuration

### SSH Access

4. **SSH_PUBLIC_KEY** - SSH public key for root access to the Raspberry Pi

### Network Configuration

5. **TAILSCALE_AUTH_KEY** - Tailscale authentication key for VPN access
6. **WIFI_SSID_1** - Primary WiFi network name
7. **WIFI_PSK_1** - Primary WiFi network password
8. **WIFI_SSID_2** - Secondary WiFi network name (optional)
9. **WIFI_PSK_2** - Secondary WiFi network password (optional)

### Optional Configuration

10. **TAILSCALE_ENABLE_ROUTING** - Enable Tailscale subnet routing (default: false)

## Setup Instructions

### 1. Container Registry Setup

First, create a Quay.io account and generate an access token:

```bash
# Set your Quay.io username
export QUAY_USERNAME="your-quay-username"

# Set your Quay.io token (generate from quay.io/user/your-username?tab=settings)
export QUAY_TOKEN="your-quay-token"

# Create docker auth JSON
cat > docker-auth.json << EOF
{
  "auths": {
    "quay.io": {
      "auth": "$(echo -n "${QUAY_USERNAME}:${QUAY_TOKEN}" | base64 -w 0)"
    }
  }
}
EOF

# Set secrets
gh secret set QUAY_USERNAME --body "${QUAY_USERNAME}"
gh secret set QUAY_TOKEN --body "${QUAY_TOKEN}"
gh secret set DOCKER_AUTH_JSON --body "$(cat docker-auth.json)"

# Clean up local auth file
rm docker-auth.json
```

### 2. SSH Key Setup

```bash
# Use your existing SSH public key or generate a new one
# To generate a new key:
# ssh-keygen -t ed25519 -f ~/.ssh/rpi5_key -C "rpi5-access"

# Set SSH public key secret
gh secret set SSH_PUBLIC_KEY --body "$(cat ~/.ssh/id_rsa.pub)"

# Or if using a specific key:
# gh secret set SSH_PUBLIC_KEY --body "$(cat ~/.ssh/rpi5_key.pub)"
```

### 3. Tailscale Setup

1. Log into your Tailscale admin console
2. Go to Settings → Keys
3. Generate a new auth key with these settings:
   - Reusable: Yes (recommended for testing)
   - Ephemeral: No (devices persist after key expires)
   - Tags: Add appropriate tags if using ACLs
   - Expiry: Set appropriate expiration

```bash
# Set Tailscale auth key
export TAILSCALE_AUTH_KEY="tskey-auth-your-auth-key-here"
gh secret set TAILSCALE_AUTH_KEY --body "${TAILSCALE_AUTH_KEY}"

# Optional: Enable subnet routing (if you want the Pi to route traffic)
gh secret set TAILSCALE_ENABLE_ROUTING --body "true"
```

### 4. WiFi Configuration

```bash
# Set primary WiFi network (required)
export WIFI_SSID_1="Your-WiFi-Network"
export WIFI_PSK_1="your-wifi-password"

gh secret set WIFI_SSID_1 --body "${WIFI_SSID_1}"
gh secret set WIFI_PSK_1 --body "${WIFI_PSK_1}"

# Set secondary WiFi network (optional)
export WIFI_SSID_2="Guest-Network"
export WIFI_PSK_2="guest-password"

gh secret set WIFI_SSID_2 --body "${WIFI_SSID_2}"
gh secret set WIFI_PSK_2 --body "${WIFI_PSK_2}"
```

### 5. Verify Secrets

```bash
# List all secrets to verify they're set
gh secret list
```

You should see all the required secrets listed.

## Complete Setup Script

Here's a complete script that sets up all secrets (customize the values):

```bash
#!/bin/bash
set -euo pipefail

# Configuration - CUSTOMIZE THESE VALUES
export QUAY_USERNAME="your-quay-username"
export QUAY_TOKEN="your-quay-token"
export SSH_KEY_PATH="$HOME/.ssh/id_rsa.pub"
export TAILSCALE_AUTH_KEY="tskey-auth-your-key-here"
export WIFI_SSID_1="Your-WiFi-Network"
export WIFI_PSK_1="your-wifi-password"
export WIFI_SSID_2="Guest-Network"  # Optional
export WIFI_PSK_2="guest-password"   # Optional

# Create docker auth JSON
cat > /tmp/docker-auth.json << EOF
{
  "auths": {
    "quay.io": {
      "auth": "$(echo -n "${QUAY_USERNAME}:${QUAY_TOKEN}" | base64 -w 0)"
    }
  }
}
EOF

# Set all secrets
gh secret set QUAY_USERNAME --body "${QUAY_USERNAME}"
gh secret set QUAY_TOKEN --body "${QUAY_TOKEN}"
gh secret set DOCKER_AUTH_JSON --body "$(cat /tmp/docker-auth.json)"
gh secret set SSH_PUBLIC_KEY --body "$(cat ${SSH_KEY_PATH})"
gh secret set TAILSCALE_AUTH_KEY --body "${TAILSCALE_AUTH_KEY}"
gh secret set WIFI_SSID_1 --body "${WIFI_SSID_1}"
gh secret set WIFI_PSK_1 --body "${WIFI_PSK_1}"

# Optional secrets
if [ -n "${WIFI_SSID_2:-}" ]; then
    gh secret set WIFI_SSID_2 --body "${WIFI_SSID_2}"
    gh secret set WIFI_PSK_2 --body "${WIFI_PSK_2}"
fi

# Clean up
rm /tmp/docker-auth.json

echo "✅ All GitHub secrets have been configured!"
echo "Run 'gh secret list' to verify."
```

## Security Notes

1. **Tailscale Auth Keys**: Use reusable keys for development, but consider one-time keys for production
2. **SSH Keys**: Use ed25519 keys for better security
3. **WiFi Credentials**: Ensure strong WiFi passwords
4. **Token Rotation**: Regularly rotate Quay.io tokens and Tailscale auth keys
5. **Secret Management**: Never commit secrets to the repository

## Testing

After setting up secrets, trigger a build to test:

```bash
# Trigger a manual workflow run
gh workflow run build.yml

# Or push to main branch to trigger automatic build
git push origin main
```

## Troubleshooting

### Common Issues

1. **Docker Auth JSON Format**: Ensure the JSON is valid and properly base64 encoded
2. **SSH Key Format**: Use the public key content, not the file path
3. **Tailscale Key**: Verify the key hasn't expired and has appropriate permissions
4. **WiFi Credentials**: Ensure special characters are properly handled

### Debug Commands

```bash
# Check if secrets are accessible in workflow
gh workflow run build.yml --field debug=true

# View workflow logs
gh run list --workflow=build.yml
gh run view [run-id] --log
```

## Additional Resources

- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Quay.io Documentation](https://docs.quay.io/)
- [Tailscale Documentation](https://tailscale.com/kb/)
- [NetworkManager WiFi Setup](https://networkmanager.dev/docs/api/latest/)
