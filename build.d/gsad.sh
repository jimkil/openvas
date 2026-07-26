#!/usr/bin/env bash
set -Eeuo pipefail

. /build.rc
. /build.d/env.sh

echo "Building gsad ${gsad}"
prepare_greenbone_source "gsad" "$gsad"

[[ -f /ics-gsa/ics-gsad.patch ]] || {
    echo "Missing required patch: /ics-gsa/ics-gsad.patch" >&2
    exit 1
}

cd "$SOURCE_DIR"
patch --batch --forward -p1 < /ics-gsa/ics-gsad.patch

BUILD_DIR="${SOURCE_DIR}/build"

cmake \
    -S "$SOURCE_DIR" \
    -B "$BUILD_DIR" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_BUILD_TYPE=Release \
    -DSYSCONFDIR="$SYSCONFDIR" \
    -DLOCALSTATEDIR="$LOCALSTATEDIR" \
    -DGVM_LOG_DIR="$GVM_LOG_DIR" \
    -DGVMD_RUN_DIR=/run/gvmd \
    -DGSAD_RUN_DIR=/run/gsad \
    -DLOGROTATE_DIR=/etc/logrotate.d

cmake --build "$BUILD_DIR" --parallel "$BUILD_JOBS"
stage_cmake_install "$BUILD_DIR"

cleanup_build_source
echo "gsad build complete"
