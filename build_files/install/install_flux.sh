#!/bin/bash

set -euox pipefail

flux="flux_install.py"

download_flux(){
   curl -s https://fluxcd.io/install.sh > "$flux"
}

# Function to check SHA-256 checksum
check_checksum() {
   echo "bd7765225b731a1df952456eced0abb5dbbf5e11bc70cf6ab5fddd1476088b7e  $flux" | sha256sum -c
}

# Install flux if checksum matches
install_flux() {
    echo "Checksum matches. Installing flux..."
    bash $flux /usr/bin
}

# Main script
download_flux

if check_checksum; then
    install_flux
else
    echo "Checksum does not match. Aborting installation."
    exit 1
fi

