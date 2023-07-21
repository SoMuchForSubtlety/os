#!/usr/bin/env bash

set -oue pipefail

for i in /tmp/patches/*.patch; do patch -d/ -p0 < "$i"; done