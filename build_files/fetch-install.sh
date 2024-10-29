#!/usr/bin/bash

set -ouex pipefail

# install bw cli
curl -Lo /tmp/bw-linux.zip "https://vault.bitwarden.com/download/?app=cli&platform=linux"
unzip -d /usr/bin /tmp/bw-linux.zip bw
chmod +x /usr/bin/bw

# install ksh
curl -Lo ./ksh "https://github.com/samox73/ksh/releases/latest/download/ksh" && \
    chmod +x ./ksh && \
    mv ./ksh /usr/bin/ksh

# install kind
curl -Lo ./kind "https://github.com/kubernetes-sigs/kind/releases/latest/download/kind-$(uname)-amd64" && \
    chmod +x ./kind && \
    mv ./kind /usr/bin/kind

# Install kns/kctx and add completions for Bash
wget https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx -O /usr/bin/kubectx && \
    wget https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens -O /usr/bin/kubens && \
    chmod +x /usr/bin/kubectx /usr/bin/kubens
# install talosctl
curl -Lo ./talosctl "https://github.com/siderolabs/talos/releases/latest/download/talosctl-linux-amd64" && \
    chmod +x ./talosctl && \
    mv ./talosctl /usr/bin/talosctl
# install sops
curl -Lo ./sops $(curl -s https://api.github.com/repos/getsops/sops/releases/latest | jq -r '.assets[] | select(.name | test("linux.amd64$")).browser_download_url') && \
    chmod +x ./sops && \
    mv ./sops /usr/bin/sops
# install yq
curl -Lo ./yq "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" && \
    chmod +x ./yq && \
    mv ./yq /usr/bin/yq
# install crd2pulumi
curl -Lo ./crd2pulumi $(curl -s https://api.github.com/repos/pulumi/crd2pulumi/releases/latest | jq -r '.assets[] | select(.name | test("linux-amd64")).browser_download_url') && \
    tar xf crd2pulumi --wildcards crd2pulumi && \
    chmod +x ./crd2pulumi && \
    mv ./crd2pulumi /usr/bin/crd2pulumi
# install eksctl
curl -s -L "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" | tar -xzf - && \
    mv ./eksctl /usr/bin/eksctl

wget https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -O /tmp/docker-compose && \
    install -c -m 0755 /tmp/docker-compose /usr/bin

# Topgrade Install
pip install --prefix=/usr topgrade

# Install ublue-update -- breaks with packages.json disable staging to use bling.
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo
rpm-ostree install ublue-update

# Consolidate Just Files
find /tmp/just -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >> /usr/share/ublue-os/just/60-custom.just

# Move over ublue-update config
mv -f /tmp/ublue-update.toml /usr/etc/ublue-update/ublue-update.toml
