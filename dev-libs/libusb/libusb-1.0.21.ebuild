# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit eutils toolchain-funcs multilib-minimal

DESCRIPTION="Userspace access to USB devices"
HOMEPAGE="http://libusb.info/ https://github.com/libusb/libusb"
SRC_URI="https://github.com/${PN}/${PN}/releases/download/v${PV}/${P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="1"
KEYWORDS="*"
IUSE="debug doc examples static-libs test udev"

RDEPEND="udev? ( >=virtual/libudev-208:=[${MULTILIB_USEDEP},static-libs?] )"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )
	!udev? ( virtual/os-headers )"

src_prepare() {
	epatch "${FILESDIR}/${P}-open-fd.patch" # crbug/831850
	epatch "${FILESDIR}/${P}-jailed.patch" # crbug/831850
}

multilib_src_configure() {
	ECONF_SOURCE=${S} \
	econf \
		$(use_enable static-libs static) \
		$(use_enable udev) \
		$(use_enable debug debug-log) \
		$(use_enable test tests-build)
}

multilib_src_compile() {
	emake

	if multilib_is_native_abi; then
		use doc && emake -C doc docs
	fi
}

multilib_src_test() {
	emake check

	# noinst_PROGRAMS from tests/Makefile.am
	tests/stress || die
}

multilib_src_install() {
	emake DESTDIR="${D}" install

	if multilib_is_native_abi; then
		gen_usr_ldscript -a usb-1.0

		use doc && dohtml doc/html/*
	fi
}

multilib_src_install_all() {
	prune_libtool_files

	dodoc AUTHORS ChangeLog NEWS PORTING README TODO

	if use examples; then
		insinto /usr/share/doc/${PF}/examples
		doins examples/*.{c,h}
		insinto /usr/share/doc/${PF}/examples/getopt
		doins examples/getopt/*.{c,h}
	fi
}
