#!/usr/bin/bash
set -euox pipefail
container_mgr=(
    docker
    podman
    podman-remote
)
for i in "${container_mgr[@]}"; do
    if [[ $(command -v "$i") ]]; then
        echo "Container Manager: ${i}"
        ID=$(${i} images --filter "reference=localhost/os*-build*" --format "{{.ID}}")
        xargs -I {} "${i}" image rm {} <<< "$ID"
        echo ""
    fi
done
