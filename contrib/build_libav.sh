#/bin/bash
set -e 

if [ -z "$MACOSX_DEPLOYMENT_TARGET" ]
then
	echo MACOSX_DEPLOYMENT_TARGET not set
	exit 1
fi

GUARD_FILE=build/guard_4
if [[ -e $GUARD_FILE ]]
then
	echo libav is up to date
	exit 0
fi

if [[ ! -e "libav/configure" ]]
then
	echo init libav submodule
	pushd ..
	git submodule init
	git submodule update
	popd
else
	# Even if we have the files it's possible that
	# we've moved to a new commit for the submodule
	echo update libav submodule
	pushd ..
	git submodule update
	popd
fi

ORIGINAL_PATH="$PATH"

build_libav()
{
(cd libav && \
./configure \
--arch=$THEARC \
--cpu=$THECPU \
--cc=clang \
--enable-decoders \
--disable-vda \
--disable-encoders \
--enable-demuxers \
--disable-muxers \
--enable-parsers \
--disable-avdevice \
--enable-postproc \
--disable-network \
--enable-pthreads \
--enable-gpl \
--disable-avconv \
--disable-ffmpeg \
--disable-avprobe \
--disable-avserver \
--disable-avplay \
--extra-ldflags="-L$PREFIX/../lib -arch $THEARC -mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET" \
--extra-cflags="-isystem $PREFIX/../include -arch $THEARC -mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET -Wno-deprecated-declarations $THEOPT " \
--enable-protocol=file \
--prefix=$PREFIX \
&& make clean && make && make install-libs && make install-headers)
}

########## INTEL i386 ###########

PREFIX="$(cd build;pwd)/i386"
PATH="$(cd build;pwd)/bin:$PREFIX/bin:$ORIGINAL_PATH"
THEARC="i386"
THECPU="pentium-m"
THEOPT=""
export PATH

build_libav

########## INTEL x86_64 ###########

PREFIX="$(cd build;pwd)/x86_64"
PATH="$(cd build;pwd)/bin:$PREFIX/bin:$ORIGINAL_PATH"
THEARC="x86_64"
THECPU="core2"
THEOPT="-mtune=core2"
export PATH

build_libav

## Relocate headers

cp -R $PREFIX/include/* $PREFIX/../include

./make_univlib.sh

touch $GUARD_FILE

