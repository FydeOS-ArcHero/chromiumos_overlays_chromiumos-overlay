# Copyright (c) 2011 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=2
CROS_WORKON_COMMIT="9d467bfed696144c4023f66baf5cfa2c0bdc3750"

inherit cros-workon

DESCRIPTION="Utility for signing Tegra2 boot images"
HOMEPAGE="http://git.chromium.org"
SRC_URI=""
LICENSE="GPLv2"
SLOT="0"
KEYWORDS="amd64 arm x86"
IUSE=""

RDEPEND=""
DEPEND=""

src_compile() {
	emake || die "emake failed"
}

src_install() {
	dodir /usr/bin
        exeinto /usr/bin

        doexe cbootimage
}
