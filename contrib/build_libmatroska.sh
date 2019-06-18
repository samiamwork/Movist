#!/bin/bash
set -e

warn_about_submodules_and_exit() {
    echo "The git submodules necessary for building libmatroska are missing."
    exit 1
}

build_ebml() {
    mkdir -p "$BUILD_DIR/build_libebml"
    cd "$BUILD_DIR/build_libebml"
    $CMAKE -DCMAKE_OSX_ARCHITECTURES='x86_64' -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET" -DDISABLE_PKGCONFIG=YES -DCMAKE_INSTALL_PREFIX="$BUILD_DIR" "$CONTRIB_DIR/libebml"
    make
    make install
    echo `git rev-parse --revs-only --prefix $GIT_PREFIX @:./libebml` > "$BUILD_DIR/ebml.stamp"
}

build_mkv() {
    mkdir -p "$BUILD_DIR/build_libmatroska"
    cd "$BUILD_DIR/build_libmatroska"
    $CMAKE -DCMAKE_OSX_ARCHITECTURES='x86_64' -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET" -DDISABLE_PKGCONFIG=YES -DCMAKE_INSTALL_PREFIX="$BUILD_DIR" "$CONTRIB_DIR/libmatroska"
    make
    make install
    echo `git rev-parse --revs-only --prefix $GIT_PREFIX @:./libmatroska` > "$BUILD_DIR/mkv.stamp"
}

if [ -z "$MACOSX_DEPLOYMENT_TARGET" ]
then
        echo "MACOSX_DEPLOYMENT_TARGET not set"
        exit 1
fi

CONTRIB_DIR=`pwd`
BUILD_DIR="$CONTRIB_DIR/build"

BUILD_EBML=0
BUILD_MKV=0

GIT_PREFIX=`git rev-parse --show-prefix`

CMAKE=${BUILD_DIR}/bin/cmake

EBML_HEAD=`git rev-parse --revs-only --prefix $GIT_PREFIX @:./libebml`
if [ $? -ne 0 ]; then
    warn_about_submodules_and_exit
fi

MKV_HEAD=`git rev-parse --revs-only --prefix $GIT_PREFIX @:./libmatroska`
if [ $? -ne 0 ]; then
    warn_about_submodules_and_exit
fi

EBML_STAMP=""
[ -e "$BUILD_DIR/ebml.stamp" ] && EBML_STAMP=$(<"$BUILD_DIR/ebml.stamp")
if [ $? -ne 0 ] || [ "$EBML_HEAD" != "$EBML_STAMP" ]; then
    BUILD_EBML=1
fi

MKV_STAMP=""
[ -e "$BUILD_DIR/mkv.stamp" ] && MKV_STAMP=$(<"$BUILD_DIR/mkv.stamp")
if [ $? -ne 0 ] || [ "$MKV_HEAD" != "$MVK_STAMP" ] || [ "$BUILD_EBML" -ne 0 ]; then
    BUILD_MKV=1
fi

if [ "$BUILD_EBML" -eq 1 ]; then
    pushd .
    build_ebml
    popd
fi

if [ "$BUILD_MKV" -eq 1 ]; then
    pushd .
    build_mkv
    popd
fi
