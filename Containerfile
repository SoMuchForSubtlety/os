ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-$BASE_IMAGE_NAME-$IMAGE_FLAVOR}"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-38}"
ARG TARGET_BASE="${TARGET_BASE:-os}"

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS os

ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG PACKAGE_LIST="os"

COPY etc /etc
COPY just /tmp/just
COPY usr /usr
COPY etc/yum.repos.d/ /etc/yum.repos.d/
COPY packages.json /tmp/packages.json
COPY build.sh /tmp/build.sh
COPY workarounds.sh /tmp/workarounds.sh
COPY optfix.sh /tmp/optfix.sh

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


RUN /tmp/workarounds.sh

# add copr for morewaita-icon-theme
RUN wget https://copr.fedorainfracloud.org/coprs/dusansimic/themes/repo/fedora-"${FEDORA_MAJOR_VERSION}"/dusansimic-themes-fedora-"${FEDORA_MAJOR_VERSION}".repo \
    -O /etc/yum.repos.d/_copr_dusansimic-themes.repo
# nerd fonts repo
RUN wget https://copr.fedorainfracloud.org/coprs/bobslept/nerd-fonts/repo/fedora-"${FEDORA_MAJOR_VERSION}"/bobslept-nerd-fonts-fedora-"${FEDORA_MAJOR_VERSION}".repo \
    -O /etc/yum.repos.d/bobslept-nerd-fonts-fedora-"${FEDORA_MAJOR_VERSION}".repo

RUN /tmp/build.sh && \
    pip install --prefix=/usr yafti && \
    systemctl enable rpm-ostree-countme.service && \
    systemctl enable tailscaled.service && \
    systemctl enable dconf-update.service && \
    fc-cache -f /usr/share/fonts/inter && \
    fc-cache -f /usr/share/fonts/intelmono && \
    find /tmp/just -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >> /usr/share/ublue-os/just/60-custom.just && \
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
    rm -f /etc/yum.repos.d/bobslept-nerd-fonts-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
    sed -i 's/#DefaultTimeoutStopSec.*/DefaultTimeoutStopSec=15s/' /etc/systemd/user.conf && \
    sed -i 's/#DefaultTimeoutStopSec.*/DefaultTimeoutStopSec=15s/' /etc/systemd/system.conf && \
    rm -rf /tmp/* /var/* && \
    mkdir -p /var/tmp && \
    chmod -R 1777 /var/tmp

COPY --from=cgr.dev/chainguard/flux:latest /usr/bin/flux /usr/bin/flux
COPY --from=cgr.dev/chainguard/helm:latest /usr/bin/helm /usr/bin/helm
COPY --from=cgr.dev/chainguard/ko:latest /usr/bin/ko /usr/bin/ko
COPY --from=cgr.dev/chainguard/dive:latest /usr/bin/dive /usr/bin/dive
COPY --from=cgr.dev/chainguard/pulumi:latest /usr/bin/pulumi /usr/bin/pulumi
COPY --from=cgr.dev/chainguard/pulumi:latest /usr/bin/pulumi-language-nodejs /usr/bin/pulumi-language-nodejs

# bash completions
RUN pulumi completion bash > /usr/share/bash-completion/completions/pulumi
RUN pulumi completion zsh > /usr/share/zsh/site-functions/_pulumi

RUN curl -Lo /tmp/bw-linux.zip "https://vault.bitwarden.com/download/?app=cli&platform=linux"
RUN unzip -d /usr/bin /tmp/bw-linux.zip bw
RUN chmod +x /usr/bin/bw

RUN curl -Lo ./kind "https://github.com/kubernetes-sigs/kind/releases/latest/download/kind-$(uname)-amd64"
RUN mv ./kind /usr/bin/kind
RUN chmod +x /usr/bin/kind

RUN systemctl enable podman.socket
RUN systemctl disable pmie.service
RUN systemctl disable pmlogger.service

RUN rm -rf /tmp/* /var/*
RUN ostree container commit
