#!/usr/bin/env bash
set -Eeuo pipefail

. /build.d/env.sh

required=(
    "${INSTALL_ROOT}/sbin/gvmd"
    "${INSTALL_ROOT}/sbin/gsad"
    "${INSTALL_ROOT}/sbin/openvas"
    "${INSTALL_ROOT}/bin/openvasd"
    "${INSTALL_ROOT}/bin/scannerctl"
    "${INSTALL_ROOT}/bin/ospd-openvas"
)

for path in "${required[@]}"; do
    [[ -x "$path" ]] || {
        echo "Missing required staged executable: ${path}" >&2
        exit 1
    }
done

# Catch the common error where /artifacts was embedded into generated text
# metadata rather than being used only as DESTDIR.  Limit this to packaging and
# configuration formats to avoid scanning binary files.
while IFS= read -r -d '' file; do
    if grep -qF "$DESTDIR" "$file"; then
        echo "Staging path embedded in generated file: ${file}" >&2
        exit 1
    fi
done < <(
    find "$DESTDIR" -type f \
        \( -name '*.pc' -o -name '*.cmake' -o -name '*.conf' -o -name '*.service' -o -name '*.sh' \) \
        -print0
)

echo "Artifact tree validation successful"
