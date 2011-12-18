#/bin/bash -x
set -e 
set -v

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
--disable-swscale \
--extra-ldflags="-L$PREFIX/lib -arch $THEARC -isystem $THESDK -mmacosx-version-min=10.6 -Wl,-syslibroot,$THESDK " \
--extra-cflags="-isystem $PREFIX/include -arch $THEARC -isystem $THESDK -mmacosx-version-min=10.6 -Wno-deprecated-declarations $THEOPT " \
--enable-protocol=file \
--prefix=$PREFIX \
&& make clean && make && make install-libs && make install-headers)
}

########## INTEL i386 ###########

PREFIX="$(cd ..;pwd)/i386"
PATH="$PREFIX/bin:$ORIGINAL_PATH"
THEARC="i386"
THECPU="pentium-m"
THEOPT=""

build_libav

########## INTEL x86_64 ###########

PREFIX="$(cd ..;pwd)/x86_64"
PATH="$PREFIX/bin:$ORIGINAL_PATH"
THEARC="x86_64"
THECPU="core2"
THEOPT="-mtune=core2"

build_libav

