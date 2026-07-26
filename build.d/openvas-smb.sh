#!/usr/bin/env bash
set -Eeuo pipefail

. /build.rc
. /build.d/env.sh

echo "Building openvas-smb ${openvas_smb}"
prepare_greenbone_source "openvas-smb" "$openvas_smb"

BUILD_DIR="${SOURCE_DIR}/build"

cmake \
    -S "$SOURCE_DIR" \
    -B "$BUILD_DIR" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_BUILD_TYPE=Release

cmake --build "$BUILD_DIR" --parallel "$BUILD_JOBS"

# openvas-scanner links against openvas-smb during its build.
install_cmake_builder_dependency "$BUILD_DIR"

cleanup_build_source
echo "openvas-smb build complete"
