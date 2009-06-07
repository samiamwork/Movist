#/bin/sh
set -e 

SDK_TARGET="10.4"
MACOSX_SDK="/Developer/SDKs/MacOSX10.4u.sdk"
PREFIX="$(cd ..;pwd)/i386"
EXTRA_CFLAGS="-isysroot ${MACOSX_SDK} -DMACOSX_DEPLOYMENT_TARGET=10.4 -mmacosx-version-min=${SDK_TARGET} -isystem $PREFIX/include"
#EXTRA_LDFLAGS="-arch i386 -Wl,-syslibroot,${MACOSX_SDK}"
CFLAGS="-I$PREFIX/include $EXTRA_CFLAGS"
LDFLAGS="-L$PREFIX/lib"

FFMPEG_VERSION=0.5
FFMPEG_REVISION=18971
FFMPEG_SWSCALE_REVISION=29320
FFMPEG_REVISION_PPC=11914
FFMPEG_SWSCALE_REVISION_PPC=25987

PATH="$PREFIX/bin:$PATH"

FFMPEG_CONF_COMMON=
FFMPEG_CONF_COMMON="$FFMPEG_CONF_COMMON --disable-ffserver --disable-ffmpeg --disable-ffplay"
FFMPEG_CONF_COMMON="$FFMPEG_CONF_COMMON --disable-encoders --disable-muxers --disable-network"
FFMPEG_CONF_COMMON="$FFMPEG_CONF_COMMON --enable-gpl --enable-postproc"
FFMPEG_CONF_COMMON="$FFMPEG_CONF_COMMON --enable-pthreads"
FFMPEG_CONF_COMMON="$FFMPEG_CONF_COMMON --enable-libfaad"
FFMPEG_CONF_COMMON="$FFMPEG_CONF_COMMON --enable-ffplay"

########## SOURCE ##########

rm -rf ffmpeg

#ffmpeg 0.5
#if [ ! -e "ffmpeg-$FFMPEG_VERSION.tar.bz2" ]; then
#	curl -L -O http://www.ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.bz2
#fi
#tar xvfj ffmpeg-$FFMPEG_VERSION.tar.bz2
#mv ffmpeg-$FFMPEG_VERSION ffmpeg

svn co svn://svn.mplayerhq.hu/ffmpeg/trunk ffmpeg

#svn co -r $FFMPEG_REVISION svn://svn.mplayerhq.hu/ffmpeg/trunk ffmpeg
#(cd ffmpeg/libswscale && svn up -r $FFMPEG_SWSCALE_REVISION)
#(cd ffmpeg&& patch -p0 < ../Patches/ffmpeg-macosx-intel-mmx.patch)


########## INTEL ###########

FFMPEG_CONF_INTEL="--cpu=pentium-m"
FFMPEG_CFLAGS_INTEL="-mtune=nocona -fstrict-aliasing -frerun-cse-after-loop -fweb -falign-loops=16"
FFMPEG_LDFLAGS_INTEL="-arch i386"

FFMPEG_CONF="$FFMPEG_CONF_COMMON $FFMPEG_CONF_INTEL"
FFMPEG_CFLAGS="$CFLAGS $FFMPEG_CFLAGS_INTEL"
FFMPEG_LDFLAGS="$LDFLAGS $FFMPEG_LDFLAGS_INTEL"

(cd ffmpeg && \
./configure $FFMPEG_CONF --prefix=$PREFIX --extra-cflags="$FFMPEG_CFLAGS" --extra-ldflags="$FFMPEG_LDFLAGS" && \
make clean && make && make install-libs && make install-headers)

##########  PPC  ###########

svn co -r $FFMPEG_REVISION_PPC svn://svn.mplayerhq.hu/ffmpeg/trunk ffmpeg_ppc
(cd ffmpeg_ppc/libswscale && svn up -r $FFMPEG_SWSCALE_REVISION_PPC)

#PREFIX="/Users/moosoy/devel/movist_org/contrib/ppc"
PREFIX="$(cd ..;pwd)/ppc"
EXTRA_CFLAGS="-isysroot ${MACOSX_SDK} -DMACOSX_DEPLOYMENT_TARGET=10.4 -mmacosx-version-min=${SDK_TARGET} -isystem $PREFIX/include"
CFLAGS="-I$PREFIX/include $EXTRA_CFLAGS"
LDFLAGS="-L$PREFIX/lib"

FFMPEG_CONF_COMMON=
FFMPEG_CONF_COMMON="$FFMPEG_CONF_COMMON --disable-ffserver --disable-ffmpeg --disable-ffplay"
FFMPEG_CONF_COMMON="$FFMPEG_CONF_COMMON --disable-encoders --disable-muxers --disable-network"
FFMPEG_CONF_COMMON="$FFMPEG_CONF_COMMON --enable-gpl --enable-pp"
FFMPEG_CONF_COMMON="$FFMPEG_CONF_COMMON --enable-pthreads"
FFMPEG_CONF_COMMON="$FFMPEG_CONF_COMMON --enable-libfaad"

FFMPEG_CONF_PPC="--cross-compile --arch=ppc"
FFMPEG_CFLAGS_PPC="-arch ppc -mcpu=G3 -mtune=G5 -fstrict-aliasing -funroll-loops -falign-loops=16 -mmultiple"
FFMPEG_LDFLAGS_PPC="-arch ppc"

FFMPEG_CONF="$FFMPEG_CONF_COMMON $FFMPEG_CONF_PPC"
FFMPEG_CFLAGS="$CFLAGS $FFMPEG_CFLAGS_PPC"
FFMPEG_LDFLAGS="$LDFLAGS $FFMPEG_LDFLAGS_PPC"

(cd ffmpeg_ppc && \
./configure $FFMPEG_CONF --prefix=$PREFIX --extra-cflags="$FFMPEG_CFLAGS" --extra-ldflags="$FFMPEG_LDFLAGS" && \
make clean && make && make install-libs && make install-headers)
