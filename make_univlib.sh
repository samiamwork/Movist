#/bin/sh

SRCROOT="$PWD"
CONTRIB_PATH="$SRCROOT/contrib/"
cd "$CONTRIB_PATH"
mkdir -p lib
cd i386/lib
for aa in `ls *.a` ; do
	lipo -create -arch i386 ${aa} -arch ppc ../../ppc/lib/${aa} -output ../../lib/${aa}
done
