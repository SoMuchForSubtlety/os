#!/bin/bash

set -euox pipefail

pulumi="pulumi_install.py"

download_pulumi(){
   curl -fsSL https://get.pulumi.com > "$pulumi"
}

# Function to check SHA-256 checksum
check_checksum() {
   echo "1fe472a5915b416299df9a1b490e7e6d573d3c9f41c662ff4322a79bf4bf0550 $pulumi" | sha256sum -c
}

# Install pulumi if checksum matches
install_pulumi() {
    echo "Checksum matches. Installing pulumi..."
    bash $pulumi --install-root /usr
}

# Main script
download_pulumi

if check_checksum; then
    install_pulumi
else
    echo "Checksum does not match. Aborting installation."
    exit 1
fi

