#!/usr/bin/env bash
# Shared build and staging environment for Greenbone components.
#
# Runtime paths must never contain /artifacts.  DESTDIR is applied only during
# the install operation so generated binaries and metadata retain their final
# runtime paths.

set -Eeuo pipefail

INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"
DESTDIR="${DESTDIR:-/artifacts}"
BUILD_ROOT="${BUILD_ROOT:-/build}"
BUILD_JOBS="${BUILD_JOBS:-$(nproc)}"

# Preserve the existing immauss/openvas configuration layout.  The runtime
# fs-setup.sh links both /etc/{gvm,openvas} and /usr/local/etc/{gvm,openvas}.
SYSCONFDIR="${SYSCONFDIR:-/usr/local/etc}"
LOCALSTATEDIR="${LOCALSTATEDIR:-/var}"
GVM_LOG_DIR="${GVM_LOG_DIR:-/var/log/gvm}"

# Normalize trailing slashes while retaining absolute paths.
INSTALL_PREFIX="/${INSTALL_PREFIX#/}"
INSTALL_PREFIX="${INSTALL_PREFIX%/}"
DESTDIR="/${DESTDIR#/}"
DESTDIR="${DESTDIR%/}"
BUILD_ROOT="/${BUILD_ROOT#/}"
BUILD_ROOT="${BUILD_ROOT%/}"

INSTALL_ROOT="${DESTDIR}${INSTALL_PREFIX}"

export INSTALL_PREFIX BUILD_ROOT BUILD_JOBS INSTALL_ROOT
export SYSCONFDIR LOCALSTATEDIR GVM_LOG_DIR

# Make components installed into the disposable builder visible to later builds.
export PATH="${INSTALL_PREFIX}/bin:${INSTALL_PREFIX}/sbin:${PATH:-}"
export PKG_CONFIG_PATH="${INSTALL_PREFIX}/lib/pkgconfig:${INSTALL_PREFIX}/lib64/pkgconfig:${INSTALL_PREFIX}/share/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="${INSTALL_PREFIX}/lib:${INSTALL_PREFIX}/lib64:${LD_LIBRARY_PATH:-}"
export CMAKE_PREFIX_PATH="${INSTALL_PREFIX}:${CMAKE_PREFIX_PATH:-}"

# Keep pip deterministic and avoid polluting the builder cache unnecessarily.
export PIP_DISABLE_PIP_VERSION_CHECK=1
export PIP_NO_CACHE_DIR=1

mkdir -p \
    "${INSTALL_ROOT}/bin" \
    "${INSTALL_ROOT}/sbin" \
    "${INSTALL_ROOT}/lib" \
    "${DESTDIR}/etc" \
    "${DESTDIR}/usr/lib/systemd/system"

prepare_greenbone_source() {
    local repository="$1"
    local tag="$2"
    local version="${tag#v}"
    local archive

    [[ -n "$repository" ]] || { echo "Repository name is required" >&2; return 2; }
    [[ -n "$tag" ]] || { echo "Release tag is required for ${repository}" >&2; return 2; }

    rm -rf "$BUILD_ROOT"
    mkdir -p "$BUILD_ROOT"

    archive="${BUILD_ROOT}/${repository}-${version}.tar.gz"
    curl --fail --location --silent --show-error \
        --retry 3 --retry-delay 2 \
        "https://github.com/greenbone/${repository}/archive/refs/tags/${tag}.tar.gz" \
        --output "$archive"

    tar -xzf "$archive" -C "$BUILD_ROOT"
    rm -f "$archive"

    SOURCE_DIR="${BUILD_ROOT}/${repository}-${version}"
    [[ -d "$SOURCE_DIR" ]] || {
        echo "Expected extracted source directory not found: ${SOURCE_DIR}" >&2
        return 1
    }
    export SOURCE_DIR
}

stage_cmake_install() {
    local build_dir="$1"
    DESTDIR="$DESTDIR" cmake --install "$build_dir"
}

# Use this for libraries needed by later build scripts.  The first install makes
# the dependency visible inside the disposable builder; the second produces the
# clean filesystem tree copied into the runtime image.
install_cmake_builder_dependency() {
    local build_dir="$1"

    cmake --install "$build_dir"
    ldconfig
    stage_cmake_install "$build_dir"
}

cleanup_build_source() {
    rm -rf "$BUILD_ROOT"
}
