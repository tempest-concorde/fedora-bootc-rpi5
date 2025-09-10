SHELL := /bin/bash

# Default image registry and name
REGISTRY ?= quay.io/tempest-concorde
IMAGE_NAME ?= fedora-bootc-rpi5
TAG ?= latest
FULL_IMAGE := $(REGISTRY)/$(IMAGE_NAME):$(TAG)

# Required environment variables
SSH_KEY_PATH ?= $(HOME)/.ssh/id_rsa.pub
DOCKER_AUTH_PATH ?= $(PWD)/docker-auth.json

# Optional environment variables for configuration
TAILSCALE_AUTH_KEY ?=
WIFI_SSID_1 ?=
WIFI_PSK_1 ?=
WIFI_SSID_2 ?=
WIFI_PSK_2 ?=
TAILSCALE_ENABLE_ROUTING ?= false

.PHONY: help build container push iso rpi5-img qcow test-local clean deps toml

help: ## Show this help message
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

deps: ## Install dependencies
	@echo "Installing gomplate..."
	@go install github.com/hairyhenderson/gomplate/v3/cmd/gomplate@latest || true

toml: deps ## Generate config.toml from template
	@echo "Generating config.toml..."
	@gomplate -f config.toml.tmpl -o config.toml

container: ## Build the container image
	@echo "Building container image: $(FULL_IMAGE)"
	@podman build --platform=linux/arm64 -t $(FULL_IMAGE) .

push: container ## Push the container image to registry
	@echo "Pushing container image: $(FULL_IMAGE)"
	@podman push $(FULL_IMAGE)

iso: toml check-env ## Create bootable ISO image with secret injection for Raspberry Pi 5
	@echo "Creating ISO image with secret injection for Raspberry Pi 5..."
	@echo "This builds locally with secrets embedded at build time."
	@rm -rf output
	@mkdir -p output
	@podman pull $(FULL_IMAGE)
	@podman pull quay.io/centos-bootc/bootc-image-builder:latest
	@podman run \
		--rm \
		-it \
		--privileged \
		--pull=newer \
		--security-opt label=type:unconfined_t \
		-v $(CURDIR)/config.toml:/config.toml:ro \
		-v $(CURDIR)/output:/output \
		-v /var/lib/containers/storage:/var/lib/containers/storage \
		quay.io/centos-bootc/bootc-image-builder:latest \
		--type iso \
		$(FULL_IMAGE)

rpi5-img: toml check-env ## Create Raspberry Pi 5 disk image with secret injection
	@echo "Creating Raspberry Pi 5 disk image with secret injection..."
	@echo "This builds locally with secrets embedded at build time."
	@rm -rf output
	@mkdir -p output
	@podman pull $(FULL_IMAGE)
	@podman pull quay.io/centos-bootc/bootc-image-builder:latest
	@podman run \
		--rm \
		-it \
		--privileged \
		--pull=newer \
		--security-opt label=type:unconfined_t \
		-v $(CURDIR)/config.toml:/config.toml:ro \
		-v $(CURDIR)/output:/output \
		-v /var/lib/containers/storage:/var/lib/containers/storage \
		quay.io/centos-bootc/bootc-image-builder:latest \
		--type raw \
		$(FULL_IMAGE)

qcow: toml check-env ## Create QCOW2 image for testing with secret injection
	@echo "Creating QCOW2 image with secret injection..."
	@echo "This builds locally with secrets embedded at build time."
	@rm -rf output
	@mkdir -p output
	@podman pull $(FULL_IMAGE)
	@podman pull quay.io/centos-bootc/bootc-image-builder:latest
	@podman run \
		--rm \
		-it \
		--privileged \
		--pull=newer \
		--security-opt label=type:unconfined_t \
		-v $(CURDIR)/config.toml:/config.toml:ro \
		-v $(CURDIR)/output:/output \
		-v /var/lib/containers/storage:/var/lib/containers/storage \
		quay.io/centos-bootc/bootc-image-builder:latest \
		--local \
		--type qcow2 \
		$(FULL_IMAGE)

test-local: container ## Test the container locally
	@echo "Testing container locally on ARM64..."
	@podman run --rm -it --platform=linux/arm64 $(FULL_IMAGE) /bin/bash

lint: ## Lint the Containerfile and configuration
	@echo "Linting Containerfile..."
	@podman build --platform=linux/arm64 -t $(IMAGE_NAME):lint-test .
	@echo "Running bootc container lint..."
	@podman run --rm $(IMAGE_NAME):lint-test bootc container lint

clean: ## Clean up build artifacts
	@echo "Cleaning up..."
	@rm -rf output/
	@rm -f config.toml
	@podman rmi $(FULL_IMAGE) 2>/dev/null || true
	@podman rmi $(IMAGE_NAME):lint-test 2>/dev/null || true

check-env: ## Check required environment variables
	@echo "Checking environment variables..."
	@test -f "$(SSH_KEY_PATH)" || (echo "ERROR: SSH_KEY_PATH file not found: $(SSH_KEY_PATH)" && exit 1)
	@test -f "$(DOCKER_AUTH_PATH)" || (echo "ERROR: DOCKER_AUTH_PATH file not found: $(DOCKER_AUTH_PATH)" && exit 1)
	@echo "Environment check passed"

# Development targets
dev-build: check-env container ## Build for development (with environment checks)

dev-test: dev-build ## Full development test (build + local test)
	@make test-local

# Production targets
release: check-env container push ## Build and push release version

# Local image building (with secret injection)
build-images: iso rpi5-img ## Build all image types locally with secrets

all: clean deps check-env container ## Complete container build pipeline

# Show configuration
show-config: ## Show current configuration
	@echo "Configuration:"
	@echo "  Registry: $(REGISTRY)"
	@echo "  Image: $(IMAGE_NAME)"
	@echo "  Tag: $(TAG)"
	@echo "  Full Image: $(FULL_IMAGE)"
	@echo "  SSH Key: $(SSH_KEY_PATH)"
	@echo "  Docker Auth: $(DOCKER_AUTH_PATH)"
	@echo "  WiFi SSID 1: $(WIFI_SSID_1)"
	@echo "  WiFi SSID 2: $(WIFI_SSID_2)"
	@echo "  Tailscale Routing: $(TAILSCALE_ENABLE_ROUTING)"
