#!/usr/bin/bash
# shellcheck disable=SC1091

set -ouex pipefail

cp -r /ctx/just /tmp/just
cp /ctx/packages.json /tmp/packages.json
cp /ctx/system_files/etc/ublue-update/ublue-update.toml /tmp/ublue-update.toml

rsync -rvK /ctx/system_files/ /

/ctx/build_files/build-fix.sh
/ctx/build_files/firmware.sh
/ctx/build_files/cache_kernel.sh
/ctx/build_files/copr-repos.sh
/ctx/build_files/install-akmods.sh
/ctx/build_files/packages.sh
/ctx/build_files/nvidia.sh
/ctx/build_files/image-info.sh
/ctx/build_files/fetch-install.sh
/ctx/build_files/font-install.sh
/ctx/build_files/systemd.sh
/ctx/build_files/initramfs.sh
/ctx/build_files/bootc.sh
/ctx/build_files/cleanup.sh
/ctx/build_files/image-info.sh
/ctx/build_files/workarounds.sh
# /ctx/build_files/apply-patches.sh
/ctx/build_files/install/install_flux.sh
/ctx/build_files/install/install_pulumi.sh
/ctx/build_files/completions.sh

