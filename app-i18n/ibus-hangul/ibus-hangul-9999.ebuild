# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-i18n/ibus-hangul/ibus-hangul-1.2.0.20090617.ebuild,v 1.1 2009/06/18 15:40:05 matsuu Exp $

EAPI="2"

inherit cros-workon

DESCRIPTION="The Hangul engine for IBus input platform"
HOMEPAGE="http://code.google.com/p/ibus/"
#SRC_URI="http://ibus.googlecode.com/files/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE="nls"

RDEPEND=">=app-i18n/ibus-1.2
	>=app-i18n/libhangul-0.0.10
	nls? ( virtual/libintl )"
DEPEND="${RDEPEND}
	dev-util/pkgconfig
	nls? ( >=sys-devel/gettext-0.16.1 )"

CROS_WORKON_SUBDIR="files"

src_unpack() {
	cros-workon_src_unpack
	cd "${S}"
	ln -s "$(type -P true)" py-compile || die
}

src_prepare() {
	NOCONFIGURE=1 ./autogen.sh
}

src_configure() {
	econf $(use_enable nls) || die
}

src_compile() {
	emake || die
}

src_install() {
	emake DESTDIR="${D}" install || die
	# Remove all Python related files
	rm "${D}/usr/libexec/ibus-setup-hangul" || die
	rm -rf "${D}/usr/share/ibus-hangul/setup" || die
	dodoc AUTHORS ChangeLog NEWS README
}

pkg_postinst() {
	ewarn "This package is very experimental, please report your bugs to"
	ewarn "http://ibus.googlecode.com/issues/list"
	elog
	elog "You should run ibus-setup and enable IM Engines you want to use!"
	elog
}
