# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2
# $Header:$
EAPI=4

CROS_WORKON_PROJECT="chromiumos/platform/bootcache"
CROS_WORKON_LOCALNAME="../platform/bootcache"
inherit toolchain-funcs cros-workon

DESCRIPTION="Utility for creating store for boot cache"
HOMEPAGE="http://git.chromium.org/gitweb/?s=bootcache"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE=""

src_compile() {
	tc-export CC
	emake
}

src_install() {
	dosbin bootcache

	insinto /etc/init
	doins bootcache.conf
}
