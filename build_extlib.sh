#/bin/bash
set -o errexit

SRCROOT="$PWD"
export CONTRIB_PATH="$SRCROOT/contrib/"

if [ "$1" = "clean" ]; then
	rm -rf $CONTRIB_PATH/build
	exit 0
fi

`git status > /dev/null 2>&1`
if [ $? -ne 0 ]; then
	echo "You're missing your git repo for Movist and it needs the submodule to get libav."
	echo "To work around this you can just download libav, libmatroska and libebml at the"
	echo "same version as the submodules and put then into contrib folder."
	exit 1
fi
git submodule update --init

# build cmake
echo Build CMake
make -C $CONTRIB_PATH -f Makefile.cmake

# build libmatroska
echo Build Matroska libs
pushd .
cd "$CONTRIB_PATH" && sh build_libmatroska.sh
popd

#build yasm (for libav)
echo Build yasm
make -C $CONTRIB_PATH -f Makefile.yasm

# build libav
echo Build libav libs
cd "$CONTRIB_PATH" && sh build_libav.sh
