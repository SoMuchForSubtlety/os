#!/bin/env bash

set -oeux pipefail

commands=("pulumi" "crd2pulumi" "helm" "talosctl" "flux" "goldwarden" "eksctl")
for command in "${commands[@]}"; do
    $command completion bash > /usr/share/bash-completion/completions/"$command"
    $command completion zsh > /usr/share/zsh/site-functions/_"$command"
done

# bitwarden attempts to create a directory for a config file in /root, but that's a symlink to /var/roothome
mkdir -p "/var/roothome/.config/Bitwarden CLI"
bw completion --shell zsh > /usr/share/zsh/site-functions/_bw
rm -rf "/var/roothome/.config/Bitwarden CLI"
# yq does not use the standard "completion" command
yq shell-completion bash > /usr/share/bash-completion/completions/yq
yq shell-completion zsh > /usr/share/zsh/site-functions/_yq
