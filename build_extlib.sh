#/bin/bash
set -o errexit

SRCROOT="$PWD"
export CONTRIB_PATH="$SRCROOT/contrib/"

if [ "$1" = "clean" ]; then
	rm -rf $CONTRIB_PATH/build
	exit 0
fi

# build libmatroska
echo Build Matroska libs
make -C $CONTRIB_PATH -f Makefile.matroska

#build yasm (for libav)
echo Build yasm
make -C $CONTRIB_PATH -f Makefile.yasm

# build libav
echo Build libav libs
cd "$CONTRIB_PATH" && sh build_libav.sh
