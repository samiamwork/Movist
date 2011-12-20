#/bin/sh
set -o errexit

mkdir -p build/lib
cd build/x86_64/lib
for aa in `ls *.a` ; do
	if [ -e "../../i386/lib/$aa" ]; then
		lipo -create -arch x86_64 ${aa} -arch i386 ../../i386/lib/${aa} -output ../../lib/${aa}
	else
		cp $aa ../../lib/$aa
	fi
done
