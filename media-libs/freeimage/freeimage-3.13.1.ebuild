# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"
inherit flag-o-matic toolchain-funcs multilib

MY_PN=FreeImage
MY_P=${MY_PN}${PV//.}
DESCRIPTION="image library supporting many formats"
HOMEPAGE="http://freeimage.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${MY_P}.zip
	doc? ( mirror://sourceforge/${PN}/${MY_P}.pdf )"

LICENSE="|| ( GPL-2 FIPL-1.0 )"
SLOT="0"
KEYWORDS="~x86"
IUSE="cxx doc"

S=${WORKDIR}/${MY_PN}

src_prepare() {
	append-cflags -std=c99 -D_POSIX_SOURCE # silence warnings from gcc
}

src_compile() {
	tc-export CC CXX AR RANLIB LD NM

	emake -f Makefile.gnu || die
	if use cxx ; then
		emake -f Makefile.fip || die
	fi
}

src_install() {
	emake DESTDIR="${D}" -f Makefile.gnu install || die
	if use cxx ; then
		emake DESTDIR="${D}" -f Makefile.fip install || die
	fi
	dodoc README.linux Whatsnew.txt
	use doc && dodoc "${DISTDIR}"/${MY_P}.pdf
}
