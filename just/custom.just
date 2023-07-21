# vim: set ft=make :

# Enable Cockpit for web-based system management | https://cockpit-project.org/
cockpit:
    echo 'Enabling Cockpit'
    echo 'PasswordAuthentication yes' | sudo tee /etc/ssh/sshd_config.d/02-enable-passwords.conf
    sudo systemctl try-restart sshd
    sudo systemctl enable --now sshd
    sudo podman container runlabel --name cockpit-ws RUN quay.io/cockpit/ws
    sudo podman container runlabel INSTALL quay.io/cockpit/ws
    sudo systemctl enable cockpit.service
    echo 'Open Cockpit -> http://localhost:9090'

# Install recommended GNOME extensions
gnome-extensions:
    pip install --upgrade gnome-extensions-cli
    gext install tailscale-status@maxgallup.github.com
    gext install pano@elhan.io
    gext install weatheroclock@CleoMenezesJr.github.io

# Install JetBrains Toolbox | https://www.jetbrains.com/toolbox-app/
jetbrains-toolbox:
    #!/usr/bin/env bash
    pushd "$(mktemp -d)"
    echo "Get latest JetBrains Toolbox version"
    # Get the json with latest releases
    curl -sSfL -o releases.json "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release"
    # Extract information
    BUILD_VERSION=$(jq -r '.TBA[0].build' ./releases.json)
    DOWNLOAD_LINK=$(jq -r '.TBA[0].downloads.linux.link' ./releases.json)
    CHECKSUM_LINK=$(jq -r '.TBA[0].downloads.linux.checksumLink' ./releases.json)
    echo "Installing JetBrains Toolbox ${BUILD_VERSION}"
    curl -sSfL -O "${DOWNLOAD_LINK}"
    curl -sSfL "${CHECKSUM_LINK}" | sha256sum -c
    tar zxf jetbrains-toolbox-"${BUILD_VERSION}".tar.gz
    echo "Launching JetBrains Toolbox"
    ./jetbrains-toolbox-"${BUILD_VERSION}"/jetbrains-toolbox

# Switch to the zsh shell
zsh:
    sudo usermod $USER --shell /usr/bin/zsh 
    printf "${USER}'s shell is now %s." "$(cat /etc/passwd | grep ":$UID:" | cut '-d:' '-f7')"

# Enable docker on the system
docker:
    sudo systemctl enable --now docker
    sudo usermod -aG docker $USER
    newgrp docker

# Install dev packages
devdeps:
    sudo rpm-ostree install java-17-openjdk-devel java-17-openjdk-src maven golang
