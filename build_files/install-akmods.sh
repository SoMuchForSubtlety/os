#!/bin/bash

set -ouex pipefail

# if [[ -n "${NVIDIA_TYPE:-}" ]]; then
#     curl -L -o /etc/yum.repos.d/fedora-coreos-pool.repo \
#         https://raw.githubusercontent.com/coreos/fedora-coreos-config/testing-devel/fedora-coreos-pool.repo
# fi

# Nvidia for gts/stable - nvidia
if [[ "${NVIDIA_TYPE}" == "nvidia" ]]; then
    curl -Lo /tmp/nvidia-install.sh https://raw.githubusercontent.com/ublue-os/hwe/main/nvidia-install.sh && \
    chmod +x /tmp/nvidia-install.sh && \
    IMAGE_NAME="${BASE_IMAGE_NAME}" RPMFUSION_MIRROR="" /tmp/nvidia-install.sh
    rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
fi

# rpmfusion dependent kmods
rpm-ostree install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
rpm-ostree install \
    broadcom-wl /tmp/akmods/kmods/*wl*.rpm \
    v4l2loopback /tmp/akmods/kmods/*v4l2loopback*.rpm
rpm-ostree uninstall rpmfusion-free-release rpmfusion-nonfree-release

curl -Lo /etc/yum.repos.d/negativo17-fedora-multimedia.repo https://negativo17.org/repos/fedora-multimedia.repo
sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo

rpm-ostree install \
    /tmp/akmods/kmods/*xone*.rpm \
    /tmp/akmods/kmods/*openrazer*.rpm

sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo

sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo
if [[ "${FEDORA_MAJOR_VERSION}" -ge "39" ]]; then
    rpm-ostree install \
        /tmp/akmods/kmods/*kvmfr*.rpm
fi
