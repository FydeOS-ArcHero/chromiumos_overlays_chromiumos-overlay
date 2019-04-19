# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="Stress test for a computer system with various selectable ways"
HOMEPAGE="https://kernel.ubuntu.com/~cking/stress-ng/"
SRC_URI="https://kernel.ubuntu.com/~cking/tarballs/${PN}/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"

DEPEND="
	dev-libs/libaio
	dev-libs/libbsd
	dev-libs/libgcrypt:0=
	sys-apps/attr
	sys-apps/keyutils
	sys-libs/libapparmor
	sys-libs/libcap
	sys-libs/zlib:=
"

RDEPEND="${DEPEND}"

DOCS=( "README" "README.Android" "TODO" "syscalls.txt" )

PATCHES=( "${FILESDIR}/${PN}-0.09.53-makefile.patch" )
