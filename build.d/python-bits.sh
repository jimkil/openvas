#!/bin/bash
set -Eeuo pipefail
# Source this for the latest release versions
. build.rc

echo "pip install the python bits needed"
python3 -m pip install \
        --break-system-packages \
        --ignore-installed \
        --root=/artifacts \
        --prefix=/usr \
        --no-warn-script-location \
        --report=/tmp/python-install-report.json \
        pip \
        setuptools \
        defusedxml \
        python-gnupg \
        lxml \
        packaging \
        paho-mqtt \
        psutil \
        redis \
        impacket \
        redis==7.1.0 \
        wrapt \
        gvm-tools==$gvm_tools \
        greenbone-feed-sync 



ln -s /usr/local/bin/wmiexec.py /usr/local/bin/impacket-wmiexec



echo "Installing OSPd-openvas"   
mkdir -p /build && cd /build
wget --no-verbose https://github.com/greenbone/ospd-openvas/archive/$ospd_openvas.tar.gz
tar -zxf $ospd_openvas.tar.gz
cd /build/*/
python3 -m pip install \
        --break-system-packages \
        --ignore-installed \
        --root=/artifacts \
        --prefix=/usr \
        --no-warn-script-location  .

cd /build
rm -rf *

rm -rf \
        /root/.cache/pip \
        /tmp/* \
        /var/tmp/*



