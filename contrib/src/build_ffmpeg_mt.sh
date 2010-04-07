#/bin/sh
set -e 
set -v

SDK_TARGET="10.4"
MACOSX_SDK="/Developer/SDKs/MacOSX10.4u.sdk"

FFMPEG_CONF_COMMON=
FFMPEG_CONF_COMMON="$FFMPEG_CONF_COMMON --disable-ffserver --disable-ffmpeg --disable-ffplay"
FFMPEG_CONF_COMMON="$FFMPEG_CONF_COMMON --disable-encoders --disable-muxers --disable-network"
FFMPEG_CONF_COMMON="$FFMPEG_CONF_COMMON --disable-ffprobe --disable-avdevice"
FFMPEG_CONF_COMMON="$FFMPEG_CONF_COMMON --disable-debug --disable-doc"
FFMPEG_CONF_COMMON="$FFMPEG_CONF_COMMON --enable-gpl --enable-postproc"
#FFMPEG_CONF_COMMON="$FFMPEG_CONF_COMMON --enable-libfaad"
#FFMPEG_CONF_COMMON="$FFMPEG_CONF_COMMON --enable-hardcoded-tables"
#FFMPEG_CONF_COMMON="$FFMPEG_CONF_COMMON --enable-runtime-cpudetect"
FFMPEG_CONF_COMMON="$FFMPEG_CONF_COMMON --disable-swscale"
FFMPEG_CONF_COMMON="$FFMPEG_CONF_COMMON --enable-pthreads"
FFMPEG_CONF_COMMON="$FFMPEG_CONF_COMMON --cc=gcc-4.0"

########## SOURCE ##########

if [ -d "ffmpeg-mt" ]; then 
	echo "ffmpeg-mt"
	#(cd ffmpeg-mt && git pull)
else
	git clone git://gitorious.org/~astrange/ffmpeg/ffmpeg-mt.git
	#git clone git://git.ffmpeg.org/libswscale/ ffmpeg-mt/libswscale
	(cd ffmpeg-mt && patch -p1 < ../Patches/ffmpegmt-disablelibswscale-disablepic.patch)
fi

########## INTEL ###########

PREFIX="$(cd ..;pwd)/i386"
EXTRA_CFLAGS="-isysroot ${MACOSX_SDK} -DMACOSX_DEPLOYMENT_TARGET=${SDK_TARGET} -mmacosx-version-min=${SDK_TARGET} -isystem $PREFIX/include"
CFLAGS="-I${MACOSX_SDK}/usr/include -I$PREFIX/include $EXTRA_CFLAGS"
LDFLAGS="-L$PREFIX/lib"
PATH="$PREFIX/bin:$PATH"

FFMPEG_CONF_INTEL="--cpu=pentium-m"
FFMPEG_CFLAGS_INTEL="-mtune=nocona -fstrict-aliasing -frerun-cse-after-loop -fweb -falign-loops=16"
FFMPEG_LDFLAGS_INTEL="-arch i386"

FFMPEG_CONF="$FFMPEG_CONF_COMMON $FFMPEG_CONF_INTEL"
FFMPEG_CFLAGS="$CFLAGS $FFMPEG_CFLAGS_INTEL"
FFMPEG_LDFLAGS="$LDFLAGS $FFMPEG_LDFLAGS_INTEL"

(cd ffmpeg-mt && \
./configure $FFMPEG_CONF --prefix=$PREFIX --extra-cflags="$FFMPEG_CFLAGS" --extra-ldflags="$FFMPEG_LDFLAGS" && \
make clean && make && make install-libs && make install-headers)

##########  PPC  ###########

PREFIX="$(cd ..;pwd)/ppc"
EXTRA_CFLAGS="-isysroot ${MACOSX_SDK} -DMACOSX_DEPLOYMENT_TARGET=10.4 -mmacosx-version-min=${SDK_TARGET} -isystem $PREFIX/include"
CFLAGS="-I$PREFIX/include $EXTRA_CFLAGS"
LDFLAGS="-L$PREFIX/lib"

FFMPEG_CONF_PPC="--enable-cross-compile --arch=ppc --target-os=darwin"
FFMPEG_CFLAGS_PPC="-arch ppc -mcpu=G3 -mtune=G5 -fstrict-aliasing -funroll-loops -falign-loops=16 -mmultiple"
FFMPEG_LDFLAGS_PPC="-arch ppc"

FFMPEG_CONF="$FFMPEG_CONF_COMMON $FFMPEG_CONF_PPC"
FFMPEG_CFLAGS="$CFLAGS $FFMPEG_CFLAGS_PPC"
FFMPEG_LDFLAGS="$LDFLAGS $FFMPEG_LDFLAGS_PPC"

(cd ffmpeg-mt && \
./configure $FFMPEG_CONF --prefix=$PREFIX --extra-cflags="$FFMPEG_CFLAGS" --extra-ldflags="$FFMPEG_LDFLAGS" && \
make clean && make && make install-libs && make install-headers)
