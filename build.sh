#!/bin/bash

set -e

OUTDIR=/output

green() {
    echo -ne "\e[32m"
    echo -n "$1"
    echo -e "\e[0m"
}

red() {
    echo -ne "\e[31m"
    echo -n "$1"
    echo -e "\e[0m"
}

task() {
    local OUTPUT
    echo -n "$1..."
    shift
    if OUTPUT=`("$@" 2>&1)`
    then
        green " ok"
        return 0
    else
        red " FAILED"
        echo "$OUTPUT"
        return 1
    fi
}

urlcat() {
    wget -qO- "$1"
}

urlget() {
    wget -O "$2" "`urlcat "$1"`"
}

FREENET_URL=`urlcat https://downloads.freenetproject.org/alpha/freenet-stable-latest.jar.url`
FREENET_BUILD=`echo "$FREENET_URL" | sed -n 's/.*freenet-build0*\([0-9]\+\).*/\1/p'`

echo "Building installer for Freenet build $FREENET_BUILD"

task "Checking if output directory is writable" \
    test -w $OUTDIR

task "Fetching wininstaller sources" \
    wget https://github.com/freenet/wininstaller-innosetup/archive/master.tar.gz
task "Unpacking wininstaller" \
    eval "tar xzf master.tar.gz && rm master.tar.gz && mv wininstaller-innosetup-master installer"

task "Fetching freenet.jar" \
    wget -O freenet.jar "$FREENET_URL"
task "Fetching seednodes.fref" \
    wget -O installer/install_node/seednodes.fref https://downloads.freenetproject.org/alpha/opennet/seednodes.fref

for PLUGIN in JSTUN KeyUtils Library ThawIndexBrowser UPnP
do
    task "Fetching plugin $PLUGIN" \
        urlget "https://downloads.freenetproject.org/alpha/plugins/$PLUGIN.jar.url" "installer/install_node/plugins/$PLUGIN.jar"
done

cd installer
task "Configuring build" \
    sed -ri "s/^#define AppVersion .*$/#define AppVersion \"0.7.5 build $FREENET_BUILD\"/" "FreenetInstall_InnoSetup.iss"
task "Building installer" \
    xvfb-run wine32 "C:\Program Files\InnoSetup\ISCC.exe" "FreenetInstall_InnoSetup.iss"
task "Finishing" \
    mv Output/FreenetInstaller.exe $OUTDIR/FreenetInstaller-$FREENET_BUILD.exe
cd ..
