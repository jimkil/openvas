#!/usr/bin/env bash
set -Eeuo pipefail

. /build.rc
. /build.d/env.sh

echo "Building openvas-scanner ${openvas}"
prepare_greenbone_source "openvas-scanner" "$openvas"

BUILD_DIR="${SOURCE_DIR}/build"
OPENVAS_BUILD_JOBS="${OPENVAS_BUILD_JOBS:-$BUILD_JOBS}"

cmake \
    -S "$SOURCE_DIR" \
    -B "$BUILD_DIR" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_BUILD_TYPE=Release \
    -DINSTALL_OLD_SYNC_SCRIPT=OFF \
    -DSYSCONFDIR="$SYSCONFDIR" \
    -DLOCALSTATEDIR="$LOCALSTATEDIR" \
    -DGVM_LOG_DIR="$GVM_LOG_DIR" \
    -DOPENVAS_FEED_LOCK_PATH=/var/lib/openvas/feed-update.lock \
    -DOPENVAS_RUN_DIR=/run/ospd

cmake --build "$BUILD_DIR" --parallel "$OPENVAS_BUILD_JOBS"

# The Rust build may need scanner libraries and headers in the active builder.
install_cmake_builder_dependency "$BUILD_DIR"

RUST_DIR="${SOURCE_DIR}/rust"
[[ -d "$RUST_DIR" ]] || {
    echo "Rust source directory not found: ${RUST_DIR}" >&2
    exit 1
}

# Preserve the existing pre-fetched Cargo content workflow.
if [[ -f /rust/crates.tar ]]; then
    tar -xf /rust/crates.tar -C "$RUST_DIR"
fi

# Install rustup only when the builder base does not already provide it.
if ! command -v rustup >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 --fail --silent --show-error \
        https://sh.rustup.rs -o /tmp/rustup-init.sh
    sh /tmp/rustup-init.sh -y --profile minimal --default-toolchain none
    rm -f /tmp/rustup-init.sh
fi

CARGO_ENV="${CARGO_HOME:-$HOME/.cargo}/env"
if [[ -f "$CARGO_ENV" ]]; then
    # shellcheck source=/dev/null
    . "$CARGO_ENV"
fi

command -v rustup >/dev/null 2>&1 || {
    echo "rustup is not available after installation" >&2
    exit 1
}
command -v cargo >/dev/null 2>&1 || {
    echo "cargo is not available after rustup initialization" >&2
    exit 1
}

RUST_TOOLCHAIN="${OPENVAS_RUST_TOOLCHAIN:-}"
if [[ -z "$RUST_TOOLCHAIN" && -f "${RUST_DIR}/rust-toolchain.toml" ]]; then
    RUST_TOOLCHAIN="$(sed -n 's/^[[:space:]]*channel[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "${RUST_DIR}/rust-toolchain.toml" | head -n1)"
fi

if [[ -n "$RUST_TOOLCHAIN" ]]; then
    rustup toolchain install "$RUST_TOOLCHAIN" --profile minimal
    rustup override set "$RUST_TOOLCHAIN" --path "$RUST_DIR"
fi

export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-/cargo-target}"

cd "$RUST_DIR"
cargo build --release

install -Dm755 \
    "${CARGO_TARGET_DIR}/release/openvasd" \
    "${INSTALL_ROOT}/bin/openvasd"

install -Dm755 \
    "${CARGO_TARGET_DIR}/release/scannerctl" \
    "${INSTALL_ROOT}/bin/scannerctl"

install -Dm644 \
    "${SOURCE_DIR}/config/redis-openvas.conf" \
    "${DESTDIR}/etc/redis/redis-openvas.conf"

cleanup_build_source
echo "openvas-scanner and Rust utilities build complete"
