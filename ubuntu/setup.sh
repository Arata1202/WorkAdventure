#!/bin/bash

ARCH="$(dpkg --print-architecture)"

# Ubuntu
sudo apt update
sudo apt install -y ca-certificates curl gnupg make
sudo install -m 0755 -d /etc/apt/keyrings

# Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# LiveKit CLI
curl -sSL https://get.livekit.io/cli | bash

# MinIO Client
case "$ARCH" in
  amd64)
    curl --progress-bar -L https://dl.min.io/client/mc/release/linux-amd64/mc \
    -o /usr/local/bin/mc
    ;;
  arm64)
    curl --progress-bar -L https://dl.min.io/client/mc/release/linux-arm64/mc \
    -o /usr/local/bin/mc
    ;;
  *)
    echo "Error: unsupported architecture: $ARCH"
    exit 1
    ;;
esac
sudo chmod +x /usr/local/bin/mc

# Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
echo \
  "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker ubuntu
newgrp docker
