#!/usr/bin/env bash
set -Eeuo pipefail

. /build.rc
. /build.d/env.sh

echo "Building gvm-libs ${gvm_libs}"
prepare_greenbone_source "gvm-libs" "$gvm_libs"

BUILD_DIR="${SOURCE_DIR}/build"
CMAKE_ARGS=(
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX"
    -DCMAKE_BUILD_TYPE=Release
    -DSYSCONFDIR="$SYSCONFDIR"
    -DLOCALSTATEDIR="$LOCALSTATEDIR"
    -DBUILD_TESTS=OFF
)

# Preserve the former ARMv7 large-file workaround without modifying upstream
# CMakeLists.txt in-place.
if [[ "$(dpkg --print-architecture)" == "armhf" ]]; then
    CMAKE_ARGS+=("-DCMAKE_C_FLAGS=-D_FILE_OFFSET_BITS=64")
fi

cmake -S "$SOURCE_DIR" -B "$BUILD_DIR" "${CMAKE_ARGS[@]}"
cmake --build "$BUILD_DIR" --parallel "$BUILD_JOBS"

# gvmd, pg-gvm, gsad, and openvas-scanner require these libraries while building.
install_cmake_builder_dependency "$BUILD_DIR"

cleanup_build_source
echo "gvm-libs build complete"
