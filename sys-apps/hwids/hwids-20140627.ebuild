# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/hwids/hwids-20140627.ebuild,v 1.1 2014/06/27 18:50:10 flameeyes Exp $

EAPI=5
inherit udev eutils

DESCRIPTION="Hardware (PCI, USB, OUI, IAB) IDs databases"
HOMEPAGE="https://github.com/gentoo/hwids"
if [[ ${PV} == "99999999" ]]; then
	EGIT_REPO_URI="${HOMEPAGE}.git"
	inherit git-2
else
	SRC_URI="${HOMEPAGE}/archive/${P}.tar.gz"
	KEYWORDS="*"
fi

LICENSE="|| ( GPL-2 BSD ) public-domain"
SLOT="0"
IUSE="+net +pci +udev +usb"

DEPEND="udev? (
	dev-lang/perl
	>=virtual/udev-206
)"
[[ ${PV} == "99999999" ]] && DEPEND+=" udev? ( net-misc/curl )"
RDEPEND="!<sys-apps/pciutils-3.1.9-r2
	!<sys-apps/usbutils-005-r1"

S=${WORKDIR}/hwids-${P}

src_prepare() {
	[[ ${PV} == "99999999" ]] && emake fetch

	sed -i -e '/udevadm hwdb/d' Makefile || die
}

_emake() {
	emake \
		NET=$(usex net) \
		PCI=$(usex pci) \
		UDEV=$(usex udev) \
		USB=$(usex usb) \
		"$@"
}

src_compile() {
	_emake
}

src_install() {
	_emake install \
		DOCDIR="${EPREFIX}/usr/share/doc/${PF}" \
		MISCDIR="${EPREFIX}/usr/share/misc" \
		HWDBDIR="${EPREFIX}$(get_udevdir)/hwdb.d" \
		DESTDIR="${D}"
}

pkg_postinst() {
	if use udev; then
		udevadm hwdb --update --root="${ROOT%/}"
		# http://cgit.freedesktop.org/systemd/systemd/commit/?id=1fab57c209035f7e66198343074e9cee06718bda
		[ "${ROOT:-/}" = "/" ] && udevadm control --reload
	fi
}
