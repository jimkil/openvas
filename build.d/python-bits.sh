#!/bin/bash
set -Eeuo pipefail
# Source this for the latest release versions
. build.rc

echo "Building OSPd-openvas"   
cd /build
wget --no-verbose https://github.com/greenbone/ospd-openvas/archive/$ospd_openvas.tar.gz
tar -zxf $ospd_openvas.tar.gz
cd /build/*/

/opt/venv/bin/python -m pip install --no-cache-dir  .

cd /build
rm -rf *

echo "pip install GVM-tools"
/opt/venv/bin/python -m pip install --no-cache-dir gvm-tools==$gvm_tools

echo "pip install of new greenbone-feed-sync"
/opt/venv/bin/python -m pip install  --no-cache-dir greenbone-feed-sync 

rm -rf \
        /root/.cache/pip \
        /tmp/* \
        /var/tmp/*