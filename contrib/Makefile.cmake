CMAKE_VERSION:=3.12.1
CMAKE:=cmake-$(CMAKE_VERSION)
CMAKE_ARCHIVE:=$(CMAKE).tar.gz
CMAKE_URL:=https://cmake.org/files/v3.12/$(CMAKE_ARCHIVE)
CURL:=curl -L -O
PREFIX:=$(CURDIR)/build
PRODUCT:=build/bin/cmake

all: $(PRODUCT)

.PHONY: all clean

clean:
	rm -rf "$(PREFIX)"

$(PREFIX):
	mkdir -p $@

build/$(CMAKE_ARCHIVE): | $(PREFIX)
	$(CURL) $(CMAKE_URL)
	mv $(CMAKE_ARCHIVE) build

$(PRODUCT): build/$(CMAKE_ARCHIVE)
	tar -C build -xvf build/$(CMAKE_ARCHIVE)
	mkdir -p "$(PREFIX)/cmakebuild"
	cd "$(PREFIX)/cmakebuild"; $(PREFIX)/$(CMAKE)/configure --prefix=$(PREFIX)
	make -C "$(PREFIX)/cmakebuild"
	make -C "$(PREFIX)/cmakebuild" install

