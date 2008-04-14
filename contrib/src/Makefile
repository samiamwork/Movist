#***************************************************************************
# src/Makefile : Dearchive and compile all files necessary
# ***************************************************************************
# Copyright (C) 2003 - 2007 the VideoLAN team
# $Id: Makefile 24136 2008-01-06 06:25:53Z pdherbemont $
#
# Authors: Christophe Massiot <massiot@via.ecp.fr>
#          Derk-Jan Hartman <hartman at videolan dot org>
#          Eric Petit <titer@m0k.org>
#          Felix Kühne <fkuehne@users.sourceforge.net>
#          Christophe Mutricy <xtophe AT xtelevision.com>
#          Gildas Bazin <gbazin at videolan dot org>
#          Damien Fouilleul <damienf at videolan dot org>
#          Jean-Baptiste Kempf <jb at videolan dot org>
# Modifiers: Chan-gu Lee <maidaro@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
# ***************************************************************************
include $(CONTRIB_PATH)config.mak
include $(CONTRIB_SRC_PATH)packages.mak

# ***************************************************************************
# Set a clean environment
# ***************************************************************************

export MACOSX_DEPLOYMENT_TARGET = $(SDK_TARGET)
export PATH := $(PREFIX)/bin:$(EXTRA_PATH):$(PATH)
export DYLD_LIBRARY_PATH := $(DYLD_LIBRARY_PATH):$(PREFIX)/lib:$(PREFIX)/vlc-lib
export LIBRARY_PATH := $(PREFIX)/lib:$(LIBRARY_PATH)
export CFLAGS = -I$(PREFIX)/include $(EXTRA_CFLAGS) $(EXTRA_CPPFLAGS)
export CPPFLAGS = -I$(PREFIX)/include $(EXTRA_CFLAGS) $(EXTRA_CPPFLAGS)
export CXXFLAGS = $(CPPFLAGS)
export LDFLAGS = -L$(PREFIX)/lib $(EXTRA_LDFLAGS)

FFMPEGCONF=
FFMPEG_CFALGS=
FFMPEG_LDALGS=

# Define ranlib on non-cross compilation setups
ifeq ($(RANLIB),)
	RANLIB=ranlib
endif

# For ffmpeg if not cross compiling
ifneq ($(CC),)
	FFMPEGCONF=--cc="$(CC)"
endif

#
# Special target-dependant options
#
ifdef CROSS_COMPILE
	HOSTCONF=--target=$(HOST) --host=$(HOST) --build=$(BUILD)
	FFMPEGCONF += --cross-compile
	FFMPEG_LDFLAGS = $(EXTRA_LDFLAGS) -mmacosx-version-min=${SDK_TARGET}
ifdef HAVE_DARWIN_OS_ON_INTEL
	FFMPEGCONF += --arch=i386
else
	FFMPEGCONF += --arch=ppc
endif
endif

ifdef HAVE_DARWIN_OS_ON_INTEL
	FFMPEG_CFLAGS += -mtune=nocona -fstrict-aliasing -frerun-cse-after-loop -fweb -falign-loops=16
	FFMPEGCONF += --cpu=pentium-m
else
	FFMPEG_CFLAGS += -mcpu=G3 -mtune=G5 -fstrict-aliasing -funroll-loops -falign-loops=16 -mmultiple
endif

FFMPEGCONF += --disable-vhook --disable-ffserver --disable-ffmpeg --disable-ffplay
FFMPEGCONF += --disable-encoders --disable-muxers --disable-network 
FFMPEGCONF += --enable-gpl --enable-pp --enable-swscaler
FFMPEGCONF += --enable-pthreads
FFMPEGCONF += --enable-libfaad --enable-liba52

DATE=`date +%Y-%m-%d`

FORCE:

# ***************************************************************************
# Useful macros
# ***************************************************************************

define EXTRACT_GZ
	cd $(CONTRIB_SRC_PATH) && \
	(rm -rf $@ || true) && \
	gunzip -c $< | tar xf - --exclude='[*?:<>\|]' && \
	(mv $(patsubst %.tar.gz,%,$(patsubst %.tgz,%,$(notdir $<))) $@ || true) && \
	touch $@
endef

# ***************************************************************************
# liba52
# ***************************************************************************

$(CONTRIB_SRC_PATH)a52dec-$(A52DEC_VERSION).tar.gz:
	cd $(CONTRIB_SRC_PATH) && $(WGET) $(A52DEC_URL)

a52dec: $(CONTRIB_SRC_PATH)a52dec-$(A52DEC_VERSION).tar.gz
	$(EXTRACT_GZ)

.a52: a52dec
	$(CONTRIB_SRC_PATH)$</configure $(HOSTCONF) --prefix=$(PREFIX) && cd liba52 && make && make install && cd ../include && make && make install
	touch $@

CLEAN_PKG += $(CONTRIB_SRC_PATH)a52dec
DISTCLEAN_PKG += $(CONTRIB_SRC_PATH)a52dec-$(A52DEC_VERSION).tar.gz

# ***************************************************************************
# faad2
# ***************************************************************************

$(CONTRIB_SRC_PATH)faad2-$(FAAD_VERSION).tar.gz:
	cd $(CONTRIB_SRC_PATH) && $(WGET) $(FAAD_URL)

faad2: $(CONTRIB_SRC_PATH)faad2-$(FAAD_VERSION).tar.gz
	$(EXTRACT_GZ)

.faad2: faad2
	(cd $(CONTRIB_SRC_PATH)$< ; ./bootstrap)
	($(CONTRIB_SRC_PATH)/$</configure $(HOSTCONF) --disable-shared --prefix=$(PREFIX) --without-bmp --without-xmms --without-drm --without-mpeg4ip && make -C libfaad && make -C libfaad install)
	touch $@

CLEAN_PKG += $(CONTRIB_SRC_PATH)faad2
DISTCLEAN_PKG += $(CONTRIB_SRC_PATH)faad2-$(FAAD_VERSION).tar.gz

# ***************************************************************************
# ffmpeg
# ***************************************************************************

$(CONTRIB_SRC_PATH)ffmpeg:
	$(SVN) co $(FFMPEG_SVN) $@

.ffmpeg: $(CONTRIB_SRC_PATH)ffmpeg .faad2 .a52
	echo LDFLAGS=$(LDFLAGS)
	echo CFLAGS=$(CFLAGS)
	($(CONTRIB_SRC_PATH)ffmpeg/configure $(FFMPEGCONF) --prefix=$(PREFIX) --extra-cflags="$(CFLAGS) $(FFMPEG_CFLAGS)" --extra-ldflags="$(FFMPEG_LDFLAGS)" && make && make install-libs install-headers)
	touch $@

ffmpeg-source: cfvz $(CONTRIB_SRC_PATH)ffmpeg-$(DATE).tar.gz
	tar cfvz $(CONTRIB_SRC_PATH)ffmpeg-$(DATE).tar.gz $(CONTRIB_SRC_PATH)ffmpeg

SOURCE += ffmpeg-source
CLEAN_PKG += $(CONTRIB_SRC_PATH)ffmpeg

source: $(SOURCE) $(DISTCLEAN_PKG)

clean: FORCE
	rm -rf $(CLEAN_PKG) $(DISTCLEAN_PKG)
