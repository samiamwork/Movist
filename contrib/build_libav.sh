#/bin/bash -x
set -e 

GUARD_FILE=build/guard_3
if [[ -e $GUARD_FILE ]]
then
	echo libav is up to date
	exit 0
fi

THESDK="/Developer/SDKs/MacOSX10.6.sdk"
ORIGINAL_PATH="$PATH"

build_libav()
{
(cd libav && \
./configure \
--arch=$THEARC \
--cpu=$THECPU \
--cc=gcc-4.2 \
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
--extra-ldflags="-L$PREFIX/../lib -arch $THEARC -isystem $THESDK -mmacosx-version-min=10.6 -Wl,-syslibroot,$THESDK " \
--extra-cflags="-isystem $PREFIX/../include -arch $THEARC -isystem $THESDK -mmacosx-version-min=10.6 -Wno-deprecated-declarations $THEOPT " \
--enable-protocol=file \
--prefix=$PREFIX \
&& make clean && make && make install-libs && make install-headers)
}

########## INTEL i386 ###########

PREFIX="$(cd build;pwd)/i386"
PATH="$PREFIX/bin:$ORIGINAL_PATH"
THEARC="i386"
THECPU="pentium-m"
THEOPT=""

build_libav

########## INTEL x86_64 ###########

PREFIX="$(cd build;pwd)/x86_64"
PATH="$PREFIX/bin:$ORIGINAL_PATH"
THEARC="x86_64"
THECPU="core2"
THEOPT="-mtune=core2"

build_libav

## Relocate headers

cp -R $PREFIX/include/* $PREFIX/../include

./make_univlib.sh

touch $GUARD_FILE

