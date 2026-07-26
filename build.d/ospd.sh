#!/usr/bin/env bash
set -Eeuo pipefail

. /build.rc

# ospd is bundled inside the ospd-openvas package for the selected releases.
# Installing the unmaintained standalone ospd repository can overwrite that
# bundled package with an older and incompatible version.
echo "Skipping standalone ospd ${ospd:-unknown}: ospd is bundled with ospd-openvas."
