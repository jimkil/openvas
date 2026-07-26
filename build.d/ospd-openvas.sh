#!/usr/bin/env bash
set -Eeuo pipefail

. /build.rc
. /build.d/env.sh

echo "Building ospd-openvas ${ospd_openvas}"
prepare_greenbone_source "ospd-openvas" "$ospd_openvas"

WHEEL_DIR="${BUILD_ROOT}/wheels"
mkdir -p "$WHEEL_DIR"

# Build a wheelhouse containing ospd-openvas and all of its Python dependencies.
python3 -m pip wheel \
    --wheel-dir "$WHEEL_DIR" \
    "$SOURCE_DIR"

OSPD_WHEEL=("$WHEEL_DIR"/ospd_openvas-*.whl)
[[ -f "${OSPD_WHEEL[0]}" ]] || {
    echo "ospd-openvas wheel was not created in ${WHEEL_DIR}" >&2
    exit 1
}

# --ignore-installed ensures dependencies are actually staged even when an apt
# or pip copy happens to exist in the disposable builder image.
python3 -m pip install \
    --break-system-packages \
    --ignore-installed \
    --no-compile \
    --no-index \
    --find-links "$WHEEL_DIR" \
    --root "$DESTDIR" \
    --prefix "$INSTALL_PREFIX" \
    "${OSPD_WHEEL[0]}"

[[ -x "${INSTALL_ROOT}/bin/ospd-openvas" ]] || {
    echo "Staged ospd-openvas executable was not created" >&2
    exit 1
}

cleanup_build_source
echo "ospd-openvas build complete"
