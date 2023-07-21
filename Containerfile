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
COPY usr /usr
COPY just /tmp/just
COPY etc/yum.repos.d/ /etc/yum.repos.d/
COPY packages.json /tmp/packages.json
COPY build.sh /tmp/build.sh
COPY image-info.sh /tmp/image-info.sh
COPY workarounds.sh /tmp/workarounds.sh
COPY optfix.sh /tmp/optfix.sh
COPY completions.sh /tmp/completions.sh
COPY apply-patches.sh /tmp/apply-patches.sh
COPY patches patches/ /tmp/patches/

# Copy ublue-update.toml to tmp first, to avoid being overwritten.
COPY usr/etc/ublue-update/ublue-update.toml /tmp/ublue-update.toml

# Add ublue kmods, add needed negativo17 repo and then immediately disable due to incompatibility with RPMFusion
COPY --from=ghcr.io/ublue-os/akmods:${AKMODS_FLAVOR}-${FEDORA_MAJOR_VERSION} /rpms /tmp/akmods-rpms
RUN sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo && \
    wget https://negativo17.org/repos/fedora-multimedia.repo -O /etc/yum.repos.d/negativo17-fedora-multimedia.repo && \
    if [[ "${FEDORA_MAJOR_VERSION}" -ge "39" ]]; then \
        rpm-ostree install \
            /tmp/akmods-rpms/kmods/*xpadneo*.rpm \
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
# see https://github.com/fedora-silverblue/issue-tracker/issues/408
RUN sed -i 's/enabled=0/enabled=1/g' /etc/yum.repos.d/google-chrome.repo
RUN sed -i 's/gpgcheck=1/gpgcheck=0/g' /etc/yum.repos.d/google-chrome.repo
RUN rpm-ostree install google-chrome-stable
# fix symlinks pointing to /opt
RUN rm /usr/bin/open-lens
RUN ln -s /usr/lib/opt/OpenLens/open-lens /usr/bin/open-lens
RUN rm /usr/bin/google-chrome-stable
RUN ln -s /usr/lib/opt/google/chrome/google-chrome /usr/bin/google-chrome-stable

# add copr for morewaita-icon-theme
RUN wget https://copr.fedorainfracloud.org/coprs/dusansimic/themes/repo/fedora-"${FEDORA_MAJOR_VERSION}"/dusansimic-themes-fedora-"${FEDORA_MAJOR_VERSION}".repo \
    -O /etc/yum.repos.d/_copr_dusansimic-themes.repo
# add nerd fonts repo
RUN wget https://copr.fedorainfracloud.org/coprs/che/nerd-fonts/repo/fedora-"${FEDORA_MAJOR_VERSION}"/che-nerd-fonts-fedora-"${FEDORA_MAJOR_VERSION}".repo \
    -O /etc/yum.repos.d/_copr_che-nerd-fonts-"${FEDORA_MAJOR_VERSION}".repo

RUN wget https://copr.fedorainfracloud.org/coprs/ublue-os/staging/repo/fedora-"${FEDORA_MAJOR_VERSION}"/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo -O /etc/yum.repos.d/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    /tmp/build.sh && \
    /tmp/image-info.sh && \
    pip install --prefix=/usr yafti && \
    pip install --prefix=/usr topgrade && \
    rpm-ostree install ublue-update && \
    mkdir -p /usr/etc/flatpak/remotes.d && \
    wget -q https://dl.flathub.org/repo/flathub.flatpakrepo -P /usr/etc/flatpak/remotes.d && \
    cp /tmp/ublue-update.toml /usr/etc/ublue-update/ublue-update.toml && \
    systemctl enable rpm-ostree-countme.service && \
    systemctl enable tailscaled.service && \
    systemctl enable dconf-update.service && \
    systemctl enable ublue-update.timer && \
    systemctl enable ublue-system-setup.service && \
    systemctl enable ublue-system-flatpak-manager.service && \
    systemctl --global enable ublue-user-flatpak-manager.service && \
    systemctl --global enable ublue-user-setup.service && \
    fc-cache -f /usr/share/fonts/ubuntu && \
    fc-cache -f /usr/share/fonts/inter && \
    find /tmp/just -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >> /usr/share/ublue-os/just/60-custom.just && \
    rm -f /etc/yum.repos.d/tailscale.repo && \
    rm -f /etc/yum.repos.d/charm.repo && \
    rm -f /etc/yum.repos.d/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    rm -f /etc/yum.repos.d/gh-cli.repo && \
    rm -f /etc/yum.repos.d/vscode.repo && \
    rm -f /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:phracek:PyCharm.repo && \
    rm -f /etc/yum.repos.d/fedora-cisco-openh264.repo && \
    rm -f /etc/yum.repos.d/docker-ce.repo && \
    rm -f /etc/yum.repos.d/_copr_dusansimic-themes.repo && \
    rm -f /etc/yum.repos.d/_copr_che-nerd-fonts-"${FEDORA_MAJOR_VERSION}" && \
    echo "Hidden=true" >> /usr/share/applications/fish.desktop && \
    echo "Hidden=true" >> /usr/share/applications/htop.desktop && \
    echo "Hidden=true" >> /usr/share/applications/nvtop.desktop && \
    echo "Hidden=true" >> /usr/share/applications/gnome-system-monitor.desktop && \
    sed -i 's/#DefaultTimeoutStopSec.*/DefaultTimeoutStopSec=15s/' /etc/systemd/user.conf && \
    sed -i 's/#DefaultTimeoutStopSec.*/DefaultTimeoutStopSec=15s/' /etc/systemd/system.conf

# apply patches
RUN /tmp/apply-patches.sh

# manually add symlinks for alternatives, see https://github.com/coreos/rpm-ostree/issues/1614
RUN /tmp/workarounds.sh

COPY --from=cgr.dev/chainguard/dive:latest /usr/bin/dive /usr/bin/dive
COPY --from=cgr.dev/chainguard/flux:latest /usr/bin/flux /usr/bin/flux
COPY --from=cgr.dev/chainguard/helm:latest /usr/bin/helm /usr/bin/helm
COPY --from=cgr.dev/chainguard/ko:latest /usr/bin/ko /usr/bin/ko
COPY --from=cgr.dev/chainguard/pulumi:latest /usr/bin/pulumi /usr/bin/pulumi
COPY --from=cgr.dev/chainguard/pulumi:latest /usr/bin/pulumi-language-nodejs /usr/bin/pulumi-language-nodejs

# install bw cli
RUN curl -Lo /tmp/bw-linux.zip "https://vault.bitwarden.com/download/?app=cli&platform=linux"
RUN unzip -d /usr/bin /tmp/bw-linux.zip bw
RUN chmod +x /usr/bin/bw

# install ksh
RUN curl -Lo ./ksh "https://github.com/samox73/ksh/releases/latest/download/ksh" && \
    chmod +x ./ksh && \
    mv ./ksh /usr/bin/ksh

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
# install yq
RUN curl -Lo ./yq "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" && \
    chmod +x ./yq && \
    mv ./yq /usr/bin/yq
# install crd2pulumi
RUN curl -Lo ./crd2pulumi $(curl -s https://api.github.com/repos/pulumi/crd2pulumi/releases/latest | jq -r '.assets[] | select(.name | test("linux-amd64")).browser_download_url') && \
    tar xf crd2pulumi --wildcards crd2pulumi && \
    chmod +x ./crd2pulumi && \
    mv ./crd2pulumi /usr/bin/crd2pulumi
# install eksctl
RUN curl -s -L "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" | tar -xzf - && \
    mv ./eksctl /usr/bin/eksctl
# install goldwarden
RUN rpm-ostree install $(curl -s https://api.github.com/repos/quexten/goldwarden/releases/latest | jq -r '.assets[] | select(.name | test("^goldwarden.*x86_64.rpm$")).browser_download_url')

# shell completions
RUN /tmp/completions.sh

# Set up services
RUN systemctl enable docker.socket && \
    systemctl enable podman.socket && \
    systemctl enable swtpm-workaround.service && \
    systemctl disable pmie.service && \
    systemctl disable pmlogger.service

RUN wget https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -O /tmp/docker-compose && \
    install -c -m 0755 /tmp/docker-compose /usr/bin

RUN rm -rf /tmp/* /var/*
RUN ostree container commit
