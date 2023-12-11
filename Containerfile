ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG AKMODS_FLAVOR="${AKMODS_FLAVOR:-main}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-$BASE_IMAGE_NAME-$IMAGE_FLAVOR}"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-39}"
ARG TARGET_BASE="${TARGET_BASE:-os}"

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS os

ARG IMAGE_NAME="${IMAGE_NAME}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR}"
ARG AKMODS_FLAVOR="${AKMODS_FLAVOR}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG PACKAGE_LIST="os"

COPY etc /etc
COPY just /tmp/just
COPY usr /usr
COPY just /tmp/just
COPY etc/yum.repos.d/ /etc/yum.repos.d/
COPY packages.json /tmp/packages.json
COPY build.sh /tmp/build.sh
COPY image-info.sh /tmp/image-info.sh
COPY workarounds.sh /tmp/workarounds.sh
COPY optfix.sh /tmp/optfix.sh
# Copy ublue-update.toml to tmp first, to avoid being overwritten.
COPY usr/etc/ublue-update/ublue-update.toml /tmp/ublue-update.toml

# Add ublue kmods, add needed negativo17 repo and then immediately disable due to incompatibility with RPMFusion
COPY --from=ghcr.io/ublue-os/akmods:${AKMODS_FLAVOR}-${FEDORA_MAJOR_VERSION} /rpms /tmp/akmods-rpms
RUN sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo && \
    wget https://negativo17.org/repos/fedora-multimedia.repo -O /etc/yum.repos.d/negativo17-fedora-multimedia.repo && \
    if [[ "${FEDORA_MAJOR_VERSION}" -ge "39" ]]; then \
        rpm-ostree install \
            /tmp/akmods-rpms/kmods/*xpadneo*.rpm \
            /tmp/akmods-rpms/kmods/*xpad-noone*.rpm \
            /tmp/akmods-rpms/kmods/*xone*.rpm \
            /tmp/akmods-rpms/kmods/*openrazer*.rpm \
            /tmp/akmods-rpms/kmods/*v4l2loopback*.rpm \
            /tmp/akmods-rpms/kmods/*wl*.rpm \
    ; fi && \
    # Don't install evdi on asus because of conflicts
    if grep -qv "asus" <<< "${AKMODS_FLAVOR}"; then \
        rpm-ostree install \
            /tmp/akmods-rpms/kmods/*evdi*.rpm \
    ; fi && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo

# packages that write to /opt during install
RUN /tmp/optfix.sh
RUN cat /etc/yum.repos.d/google-chrome.repo
RUN rpm-ostree install $(curl -s https://api.github.com/repos/MuhammedKalkan/OpenLens/releases/latest | jq -r '.assets[] | select(.name | test("^OpenLens.*x86_64.rpm$")).browser_download_url')
# fix desktop file
RUN sed -i 's+Exec=/opt/OpenLens/+Exec=/usr/bin/+g' /usr/share/applications/open-lens.desktop
RUN sed -i 's/enabled=0/enabled=1/g' /etc/yum.repos.d/google-chrome.repo
# see https://github.com/fedora-silverblue/issue-tracker/issues/408
RUN sed -i 's/gpgcheck=1/gpgcheck=0/g' /etc/yum.repos.d/google-chrome.repo
RUN cat /etc/yum.repos.d/google-chrome.repo
RUN rpm-ostree install google-chrome-stable
# fix symlinks pointing to /opt
RUN rm /usr/bin/open-lens
RUN ln -s /usr/lib/opt/OpenLens/open-lens /usr/bin/open-lens
RUN rm /usr/bin/google-chrome-stable
RUN ln -s /usr/lib/opt/google/chrome/google-chrome /usr/bin/google-chrome-stable

# add copr for morewaita-icon-theme
RUN wget https://copr.fedorainfracloud.org/coprs/dusansimic/themes/repo/fedora-"${FEDORA_MAJOR_VERSION}"/dusansimic-themes-fedora-"${FEDORA_MAJOR_VERSION}".repo \
    -O /etc/yum.repos.d/_copr_dusansimic-themes.repo
# nerd fonts repo
RUN wget https://copr.fedorainfracloud.org/coprs/bobslept/nerd-fonts/repo/fedora-"${FEDORA_MAJOR_VERSION}"/bobslept-nerd-fonts-fedora-"${FEDORA_MAJOR_VERSION}".repo \
    -O /etc/yum.repos.d/bobslept-nerd-fonts-fedora-"${FEDORA_MAJOR_VERSION}".repo

RUN wget https://copr.fedorainfracloud.org/coprs/ublue-os/bling/repo/fedora-$(rpm -E %fedora)/ublue-os-bling-fedora-$(rpm -E %fedora).repo -O /etc/yum.repos.d/_copr_ublue-os-bling.repo && \
    wget https://copr.fedorainfracloud.org/coprs/ublue-os/staging/repo/fedora-"${FEDORA_MAJOR_VERSION}"/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo -O /etc/yum.repos.d/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    /tmp/build.sh && \
    /tmp/image-info.sh && \
    pip install --prefix=/usr yafti && \
    mkdir -p /usr/etc/flatpak/remotes.d && \
    wget -q https://dl.flathub.org/repo/flathub.flatpakrepo -P /usr/etc/flatpak/remotes.d && \
    cp /tmp/ublue-update.toml /usr/etc/ublue-update/ublue-update.toml && \
    fc-cache -f /usr/share/fonts/inter && \
    fc-cache -f /usr/share/fonts/intelmono && \
    find /tmp/just -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >> /usr/share/ublue-os/just/60-custom.just && \
    systemctl enable rpm-ostree-countme.service && \
    systemctl enable tailscaled.service && \
    systemctl enable dconf-update.service && \
    systemctl enable ublue-update.timer && \
    systemctl enable ublue-system-setup.service && \
    systemctl enable ublue-system-flatpak-manager.service && \
    systemctl --global enable ublue-user-flatpak-manager.service && \
    systemctl --global enable ublue-user-setup.service && \
    rm -f /etc/yum.repos.d/charm.repo && \
    rm -f /etc/yum.repos.d/_copr_ublue-os-bling.repo && \
    rm -f /etc/yum.repos.d/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    rm -f /usr/share/applications/fish.desktop && \
    rm -f /usr/share/applications/htop.desktop && \
    rm -f /usr/share/applications/nvtop.desktop && \
    # Clean up repos, everything is on the image so we don't need them
    rm -f /etc/yum.repos.d/tailscale.repo && \
    rm -f /etc/yum.repos.d/terra.repo && \
    rm -f /etc/yum.repos.d/gh-cli.repo && \
    rm -f /etc/yum.repos.d/vscode.repo && \
    rm -f /etc/yum.repos.d/hashicorp.repo && \
    rm -f /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:phracek:PyCharm.repo && \
    rm -f /etc/yum.repos.d/fedora-cisco-openh264.repo && \
    rm -f /etc/yum.repos.d/_copr_dusansimic-themes.repo && \
    rm -f /etc/yum.repos.d/docker-ce.repo && \
    rm -f /etc/yum.repos.d/bobslept-nerd-fonts-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    sed -i 's/#DefaultTimeoutStopSec.*/DefaultTimeoutStopSec=15s/' /etc/systemd/user.conf && \
    sed -i 's/#DefaultTimeoutStopSec.*/DefaultTimeoutStopSec=15s/' /etc/systemd/system.conf && \
    mkdir -p /var/tmp && \
    chmod -R 1777 /var/tmp


# manually add symlinks for alternatives, see https://github.com/coreos/rpm-ostree/issues/1614
RUN /tmp/workarounds.sh
# cleanup
RUN rm -rf /tmp/* /var/*

COPY --from=cgr.dev/chainguard/flux:latest /usr/bin/flux /usr/bin/flux
COPY --from=cgr.dev/chainguard/helm:latest /usr/bin/helm /usr/bin/helm
COPY --from=cgr.dev/chainguard/ko:latest /usr/bin/ko /usr/bin/ko
COPY --from=cgr.dev/chainguard/dive:latest /usr/bin/dive /usr/bin/dive
COPY --from=cgr.dev/chainguard/pulumi:latest /usr/bin/pulumi /usr/bin/pulumi
COPY --from=cgr.dev/chainguard/pulumi:latest /usr/bin/pulumi-language-nodejs /usr/bin/pulumi-language-nodejs

# install bw cli
RUN curl -Lo /tmp/bw-linux.zip "https://vault.bitwarden.com/download/?app=cli&platform=linux"
RUN unzip -d /usr/bin /tmp/bw-linux.zip bw
RUN chmod +x /usr/bin/bw

# install kind
RUN curl -Lo ./kind "https://github.com/kubernetes-sigs/kind/releases/latest/download/kind-$(uname)-amd64" && \
    chmod +x ./kind && \
    mv ./kind /usr/bin/kind
# Install kns/kctx and add completions for Bash
RUN wget https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx -O /usr/bin/kubectx && \
    wget https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens -O /usr/bin/kubens && \
    chmod +x /usr/bin/kubectx /usr/bin/kubens
# install talosctl
RUN curl -Lo ./talosctl "https://github.com/siderolabs/talos/releases/latest/download/talosctl-linux-amd64" && \
    chmod +x ./talosctl && \
    mv ./talosctl /usr/bin/talosctl
# install sops
RUN curl -Lo ./sops $(curl -s https://api.github.com/repos/getsops/sops/releases/latest | jq -r '.assets[] | select(.name | test("linux.amd64$")).browser_download_url') && \
    chmod +x ./sops && \
    mv ./sops /usr/bin/sops

# shell completions
RUN pulumi completion bash > /usr/share/bash-completion/completions/pulumi
RUN pulumi completion zsh > /usr/share/zsh/site-functions/_pulumi
RUN helm completion bash > /usr/share/bash-completion/completions/helm
RUN helm completion zsh > /usr/share/zsh/site-functions/_helm
RUN talosctl completion bash > /usr/share/bash-completion/completions/talosctl
RUN talosctl completion zsh > /usr/share/zsh/site-functions/_talosctl
# bitwarden attempts to create a directory for a config file in /root, but that's a symlink to /var/roothome
RUN mkdir -p "/var/roothome/.config/Bitwarden CLI"
run bw completion --shell zsh > /usr/share/zsh/site-functions/_bw
RUN rm -rf "/var/roothome/.config/Bitwarden CLI"

# Set up services
RUN systemctl enable podman.socket && \
    systemctl disable pmie.service && \
    systemctl disable pmlogger.service

RUN wget https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -O /tmp/docker-compose && \
    install -c -m 0755 /tmp/docker-compose /usr/bin

RUN rm -rf /tmp/* /var/*
RUN ostree container commit
