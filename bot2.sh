#!/bin/bash

# Download URL for the Go binary archive (change as needed)
GO_DOWNLOAD_URL="https://golang.org/dl/go1.20.4.linux-amd64.tar.gz"

# Destination directory where Go will be installed
INSTALL_DIR="/usr/local"

# Download the Go binary archive
echo "Downloading Go..."
wget -P /tmp $GO_DOWNLOAD_URL

# Extract the archive
echo "Extracting archive..."
tar -C $INSTALL_DIR -xzf /tmp/go*.tar.gz

# Add Go binaries to the system's PATH
echo "Configuring environment variables..."
echo "export PATH=\$PATH:$INSTALL_DIR/go/bin" >> ~/.bashrc
source ~/.bashrc

# Cleanup
echo "Cleaning up..."
rm /tmp/go*.tar.gz

echo "Go installation completed!"

# Install Python 3 and pip3
echo "Installing Python 3 and pip3..."
sudo apt update
sudo apt install -y python3 python3-pip

echo "Python 3 and pip3 installation completed!"
