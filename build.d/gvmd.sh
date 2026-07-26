#!/usr/bin/env bash
set -Eeuo pipefail

. /build.rc
. /build.d/env.sh

echo "Building gvmd ${gvmd}"
prepare_greenbone_source "gvmd" "$gvmd"

BUILD_DIR="${SOURCE_DIR}/build"
PGVER="${GVMD_BUILD_PGVER:-15}"
PG_CONFIG_EXECUTABLE="/usr/lib/postgresql/${PGVER}/bin/pg_config"

[[ -x "$PG_CONFIG_EXECUTABLE" ]] || {
    echo "Missing ${PG_CONFIG_EXECUTABLE}; install postgresql-server-dev-${PGVER}" >&2
    exit 1
}

export PATH="/usr/lib/postgresql/${PGVER}/bin:${PATH}"

# Optional whitespace-separated CMake feature flags, for example:
#   GVMD_FEATURE_FLAGS='-DENABLE_OPENVASD=1'
read -r -a FEATURE_FLAGS <<< "${GVMD_FEATURE_FLAGS:-}"

cmake \
    -S "$SOURCE_DIR" \
    -B "$BUILD_DIR" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_BUILD_TYPE=Release \
    -DPG_CONFIG_EXECUTABLE="$PG_CONFIG_EXECUTABLE" \
    -DSYSCONFDIR="$SYSCONFDIR" \
    -DLOCALSTATEDIR="$LOCALSTATEDIR" \
    -DGVM_LOG_DIR="$GVM_LOG_DIR" \
    -DGVMD_RUN_DIR=/run/gvmd \
    -DOPENVAS_DEFAULT_SOCKET=/run/ospd/ospd-openvas.sock \
    -DGVM_FEED_LOCK_PATH=/var/lib/gvm/feed-update.lock \
    -DLOGROTATE_DIR=/etc/logrotate.d \
    "${FEATURE_FLAGS[@]}"

cmake --build "$BUILD_DIR" --parallel "$BUILD_JOBS"
stage_cmake_install "$BUILD_DIR"

cleanup_build_source
echo "gvmd build complete"
