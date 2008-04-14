#/bin/sh

SRCROOT="$PWD"
export CONTRIB_PATH="$SRCROOT/contrib/"
export CONTRIB_SRC_PATH="$CONTRIB_PATH/src/"

# i386 
BUILDDIR="$CONTRIB_PATH/build/intel"
cd "$CONTRIB_PATH" && sh bootstrap i686-apple-darwin8
mkdir -p "$BUILDDIR"
cd "$BUILDDIR" && make -f "${CONTRIB_SRC_PATH}Makefile"

# ppc 
BUILDDIR="$CONTRIB_PATH/build/ppc"
cd "$CONTRIB_PATH" && sh bootstrap powerpc-apple-darwin8
mkdir -p "$BUILDDIR"
cd "$BUILDDIR" && make -f "${CONTRIB_SRC_PATH}Makefile"

# ffmpeg
#cd $CONTRIB_SRC_PATH/ffmpeg
cd "$CONTRIB_SRC_PATH" && sh build_ffmpeg.sh

# universal
cd "$SRCROOT" && sh make_univlib.sh
