# Copyright (c) 2011 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=2

CROS_WORKON_PROJECT="chromiumos/platform/smogcheck"
inherit toolchain-funcs cros-debug cros-workon

DESCRIPTION="TPM SmogCheck library"
HOMEPAGE="http://www.chromium.org/"
SRC_URI=""
LICENSE="BSD"
SLOT="0"
IUSE=""
KEYWORDS="~amd64 ~arm ~x86"

RDEPEND=""
DEPEND="${RDEPEND}
	sys-kernel/linux-headers"

src_configure() {
	cros-workon_src_configure
}

src_compile() {
	tc-export CC
	cros-debug-add-NDEBUG

	emake clean
	emake || die "Smogcheck compile failed"
}

src_install() {
	emake DESTDIR="${D}" install || die "Install failed"
}
