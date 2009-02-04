# ***************************************************************************
# src/packages.mak : Archive locations
# ***************************************************************************
# Copyright (C) 2003 - 2006 the VideoLAN team
# $Id: packages.mak 24122 2008-01-05 17:58:36Z jb $
#
# Authors: Christophe Massiot <massiot@via.ecp.fr>
#          Derk-Jan Hartman <hartman at videolan dot org>
#          Felix Kühne <fkuehne@users.sourceforge.net>
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

# Definition of package distributors
GNU=http://ftp.heanet.ie/mirrors/ftp.gnu.org/gnu
SF=http://heanet.dl.sourceforge.net/sourceforge
VIDEOLAN=http://download.videolan.org/pub/videolan
A52DEC_VERSION=0.7.4
A52DEC_URL=$(VIDEOLAN)/testing/contrib/a52dec-$(A52DEC_VERSION).tar.gz
FAAD_VERSION=2.6.1
FAAD_URL=$(SF)/faac/faad2-$(FAAD_VERSION).tar.gz
LAME_VERSION=3.97
LAME_URL=$(SF)/lame/lame-$(LAME_VERSION).tar.gz
EBML_VERSION=0.7.8
EBML_URL=http://dl.matroska.org/downloads/libebml/libebml-$(EBML_VERSION).tar.bz2
MATROSKA_VERSION=0.8.1
MATROSKA_URL=http://dl.matroska.org/downloads/libmatroska/libmatroska-$(MATROSKA_VERSION).tar.bz2

FFMPEG_VERSION=0.4.8
FFMPEG_URL=$(SF)/ffmpeg/ffmpeg-$(FFMPEG_VERSION).tar.gz
FFMPEG_SVN=svn://svn.mplayerhq.hu/ffmpeg/trunk

# Definition of contributed packages
darwin_packages:.faad2 .matroska .a52
