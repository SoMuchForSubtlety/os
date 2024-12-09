ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG AKMODS_FLAVOR="${AKMODS_FLAVOR:-main}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-${BASE_IMAGE_NAME}-${IMAGE_FLAVOR}}"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-40}"
ARG NVIDIA_TYPE="${NVIDIA_TYPE:-}"
ARG KERNEL="${KERNEL:-6.11.4-200.fc40.x86_64}"
ARG IMAGE_TAG="${IMAGE_TAG:-latest}"
ARG SHA_HEAD_SHORT="${SHA_HEAD_SHORT}"
ARG TARGET_BASE="${TARGET_BASE:-os}"

# FROM's for Mounting
ARG KMOD_SOURCE_COMMON="ghcr.io/ublue-os/akmods:${AKMODS_FLAVOR}-${FEDORA_MAJOR_VERSION}"
ARG NVIDIA_CACHE="ghcr.io/ublue-os/akmods-nvidia:${AKMODS_FLAVOR}-${FEDORA_MAJOR_VERSION}"
ARG KERNEL_CACHE="ghcr.io/ublue-os/${AKMODS_FLAVOR}-kernel:${KERNEL}"
FROM ${KMOD_SOURCE_COMMON} AS akmods
FROM ${NVIDIA_CACHE} AS nvidia_cache
FROM ${KERNEL_CACHE} AS kernel_cache

FROM scratch AS ctx
COPY / /

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS base

ARG IMAGE_NAME="${IMAGE_NAME}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR}"
ARG AKMODS_FLAVOR="${AKMODS_FLAVOR}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG NVIDIA_TYPE="${NVIDIA_TYPE:-}"
ARG KERNEL="${KERNEL:-6.10.10-200.fc40.x86_64}"
ARG IMAGE_TAG="${IMAGE_TAG:-latest}"
ARG SHA_HEAD_SHORT="${SHA_HEAD_SHORT}"
ARG TARGET_BASE="${TARGET_BASE:-os}"

# packages that write to /opt during install
# RUN /tmp/optfix.sh
# RUN cat /etc/yum.repos.d/google-chrome.repo
# RUN rpm-ostree install $(curl -s https://api.github.com/repos/MuhammedKalkan/OpenLens/releases/latest | jq -r '.assets[] | select(.name | test("^OpenLens.*x86_64.rpm$")).browser_download_url')

# fix symlinks pointing to /opt
# RUN rm /usr/bin/open-lens
# RUN ln -s /usr/lib/opt/OpenLens/open-lens /usr/bin/open-lens
COPY --from=cgr.dev/chainguard/dive:latest /usr/bin/dive /usr/bin/dive
COPY --from=cgr.dev/chainguard/helm:latest /usr/bin/helm /usr/bin/helm
COPY --from=cgr.dev/chainguard/ko:latest /usr/bin/ko /usr/bin/ko

RUN --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=bind,from=akmods,source=/rpms,target=/tmp/akmods \
    --mount=type=bind,from=nvidia_cache,source=/rpms,target=/tmp/akmods-rpms \
    --mount=type=bind,from=kernel_cache,source=/tmp/rpms,target=/tmp/kernel-rpms \
    rpm-ostree cliwrap install-to-root / && \
    mkdir -p /var/lib/alternatives && \
    /ctx/build_files/build-base.sh  && \
    mv /var/lib/alternatives /staged-alternatives && \
    /ctx/build_files/clean-stage.sh && \
    ostree container commit && \
    mkdir -p /var/lib && mv /staged-alternatives /var/lib/alternatives && \
    mkdir -p /var/tmp && \
    chmod -R 1777 /var/tmp

RUN ostree container commit
