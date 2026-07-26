#!/usr/bin/env bash
set -Eeuo pipefail

. /build.rc
. /build.d/env.sh

echo "Building pg-gvm ${pg_gvm}"
prepare_greenbone_source "pg-gvm" "$pg_gvm"

BASE_PATH="$PATH"
read -r -a PG_VERSIONS <<< "${PG_GVM_VERSIONS:-13 15}"

for PGVER in "${PG_VERSIONS[@]}"; do
    BUILD_DIR="${SOURCE_DIR}/build-pg${PGVER}"
    PG_BIN_DIR="/usr/lib/postgresql/${PGVER}/bin"
    PGCONFIG_BIN="${PG_BIN_DIR}/pg_config"
    PG_SERVER_INCLUDE="/usr/include/postgresql/${PGVER}/server"

    [[ -x "$PGCONFIG_BIN" ]] || {
        echo "Missing ${PGCONFIG_BIN}; install postgresql-server-dev-${PGVER}" >&2
        exit 1
    }
    [[ -d "$PG_SERVER_INCLUDE" ]] || {
        echo "Missing PostgreSQL server headers: ${PG_SERVER_INCLUDE}" >&2
        exit 1
    }

    echo "Building pg-gvm for PostgreSQL ${PGVER}"
    rm -rf "$BUILD_DIR"
    export PATH="${PG_BIN_DIR}:${BASE_PATH}"

    cmake \
        -S "$SOURCE_DIR" \
        -B "$BUILD_DIR" \
        -DCMAKE_BUILD_TYPE=Release \
        -DPGCONFIG="$PGCONFIG_BIN" \
        -DPostgreSQL_TYPE_INCLUDE_DIR="$PG_SERVER_INCLUDE"

    cmake --build "$BUILD_DIR" --parallel "$BUILD_JOBS"
    stage_cmake_install "$BUILD_DIR"
done

export PATH="$BASE_PATH"
cleanup_build_source
echo "pg-gvm build complete"
