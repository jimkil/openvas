#!/usr/bin/env bash
set -Eeuo pipefail

. /build.rc
. /build.d/env.sh

echo "Installing build prerequisites"

mapfile -t PACKAGES < <(
    sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' \
        /build.d/package-list-build
)

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    "${PACKAGES[@]}"
rm -rf /var/lib/apt/lists/*

# Install rustup once in a cacheable prerequisite layer.  The exact toolchain is
# selected later from openvas-scanner/rust-toolchain.toml.
if ! command -v rustup >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 --fail --silent --show-error \
        https://sh.rustup.rs -o /tmp/rustup-init.sh
    sh /tmp/rustup-init.sh -y --profile minimal --default-toolchain none
    rm -f /tmp/rustup-init.sh
fi
