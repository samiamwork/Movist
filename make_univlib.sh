#/bin/sh

SRCROOT="$PWD"
CONTRIB_PATH="$SRCROOT/contrib/"
cd "$CONTRIB_PATH"
mkdir -p lib
cd i386/lib
for aa in `ls *.a` ; do
	if [ -e "../../ppc/lib/$aa" -a -e "../../x86_64/lib/$aa" ]; then
		lipo -create -arch i386 ${aa} -arch ppc ../../ppc/lib/${aa} -arch x86_64 ../../x86_64/lib/${aa} -output ../../lib/${aa}
	elif [ -e "../../ppc/lib/$aa" ]; then
		lipo -create -arch i386 ${aa} -arch ppc ../../ppc/lib/${aa} -output ../../lib/${aa}
	else
		cp $aa ../../lib/$aa
	fi
done
