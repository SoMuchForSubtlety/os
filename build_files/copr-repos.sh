#!/usr/bin/bash

set -ouex pipefail

# Add Bling repo
curl -Lo /etc/yum.repos.d/ublue-os-bling-fedora-"${FEDORA_MAJOR_VERSION}".repo https://copr.fedorainfracloud.org/coprs/ublue-os/bling/repo/fedora-"${FEDORA_MAJOR_VERSION}"/ublue-os-bling-fedora-"${FEDORA_MAJOR_VERSION}".repo

# Add Staging repo
curl -Lo /etc/yum.repos.d/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo https://copr.fedorainfracloud.org/coprs/ublue-os/staging/repo/fedora-"${FEDORA_MAJOR_VERSION}"/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo

# GNOME Triple Buffering
if [[ "${FEDORA_MAJOR_VERSION}" -gt "39" && "${FEDORA_MAJOR_VERSION}" -ne "41" ]]; then
    rpm-ostree override replace \
    --experimental \
    --from repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
        mutter \
        mutter-common
fi

# Fix for ID in fwupd
if [[ "${FEDORA_MAJOR_VERSION}" -gt "39" ]]; then
    rpm-ostree override replace \
        --experimental \
        --from repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
            fwupd \
            fwupd-plugin-flashrom \
            fwupd-plugin-modem-manager \
            fwupd-plugin-uefi-capsule-data
fi

# add copr for morewaita-icon-theme
wget https://copr.fedorainfracloud.org/coprs/dusansimic/themes/repo/fedora-"${FEDORA_MAJOR_VERSION}"/dusansimic-themes-fedora-"${FEDORA_MAJOR_VERSION}".repo \
    -O /etc/yum.repos.d/_copr_dusansimic-themes.repo

# Add Nerd Fonts
curl -Lo /etc/yum.repos.d/_copr_che-nerd-fonts-"${FEDORA_MAJOR_VERSION}".repo https://copr.fedorainfracloud.org/coprs/che/nerd-fonts/repo/fedora-"${FEDORA_MAJOR_VERSION}"/che-nerd-fonts-fedora-"${FEDORA_MAJOR_VERSION}".repo

# Kvmfr module
curl -Lo /etc/yum.repos.d/hikariknight-looking-glass-kvmfr-fedora-"${FEDORA_MAJOR_VERSION}".repo https://copr.fedorainfracloud.org/coprs/hikariknight/looking-glass-kvmfr/repo/fedora-"${FEDORA_MAJOR_VERSION}"/hikariknight-looking-glass-kvmfr-fedora-"${FEDORA_MAJOR_VERSION}".repo

# k9s
curl -Lo /etc/yum.repos.d/luminoso-k9s-"${FEDORA_MAJOR_VERSION}".repo https://copr.fedorainfracloud.org/coprs/luminoso/k9s/repo/fedora-"${FEDORA_MAJOR_VERSION}"/luminoso-k9s-"${FEDORA_MAJOR_VERSION}".repo
