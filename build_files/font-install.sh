#!/usr/bin/bash

set -ouex pipefail

if [[ "${BASE_IMAGE_NAME}" =~ "kinoite" ]]; then
    curl --output-dir /tmp -LO https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip
    mkdir -p /usr/share/fonts/fira-nf
    unzip /tmp/FiraCode.zip -d /usr/share/fonts/fira-nf
    fc-cache -f /usr/share/fonts/fira-nf
fi

fc-cache -f /usr/share/fonts/ubuntu 
fc-cache -f /usr/share/fonts/inter
# GitHub Monaspace
DOWNLOAD_URL=$(curl https://api.github.com/repos/githubnext/monaspace/releases/latest | jq -r '.assets[] | select(.name| test(".*.zip$")).browser_download_url')
curl -Lo /tmp/monaspace-font.zip "$DOWNLOAD_URL"

unzip -qo /tmp/monaspace-font.zip -d /tmp/monaspace-font
mkdir -p /usr/share/fonts/monaspace
mv /tmp/monaspace-font/monaspace-v*/fonts/variable/* /usr/share/fonts/monaspace/
rm -rf /tmp/monaspace-font*

fc-cache -f /usr/share/fonts/monaspace
