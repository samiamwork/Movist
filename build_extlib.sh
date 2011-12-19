#/bin/sh
set -o errexit

SRCROOT="$PWD"
export CONTRIB_PATH="$SRCROOT/contrib/"
export CONTRIB_SRC_PATH="$CONTRIB_PATH/src/"

if [ "$1" = "clean" ]; then
	rm -rf $CONTRIB_PATH/build
	exit 0
fi

# build libmatroska
make -C $CONTRIB_PATH -f Makefile.matroska

# build libav
cd "$CONTRIB_SRC_PATH" && sh build_libav.sh

# universal
cd "$SRCROOT" && sh make_univlib.sh
