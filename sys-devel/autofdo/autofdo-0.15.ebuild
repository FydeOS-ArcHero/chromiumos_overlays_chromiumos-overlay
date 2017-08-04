# Copyright (c) 2014 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit autotools eutils flag-o-matic

DESCRIPTION="Utilies for generating, examining AFDO profiles"
HOMEPAGE="http://gcc.gnu.org/wiki/AutoFDO"
SRC_URI="https://github.com/google/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND="dev-libs/openssl
	dev-libs/libffi
	sys-devel/llvm
	sys-libs/zlib"
RDEPEND="${DEPEND}"

src_prepare() {
	# Fix a build problem with gcc.
	epatch "${FILESDIR}/autofdo-0.15-rpath.patch"
	# LLVM ProfileData.h header has changed upstream.
	# Patch to use new API if llvm was built with llvm-next use flag.
	# Make this patch unconditional after next chromiumos-sdk update.
	if has_version --host-root 'sys-devel/llvm[llvm-next]' ||
		has_version --host-root ">=sys-devel/llvm-5.0_pre305632"; then
		epatch "${FILESDIR}/autofdo-0.15-llvm-next.patch"
	fi
	eautoreconf
}

src_configure() {
	append-ldflags $(no-as-needed)
	econf
}

src_install() {
	dobin create_gcov create_llvm_prof dump_gcov profile_diff \
		profile_merger profile_update sample_merger
}
