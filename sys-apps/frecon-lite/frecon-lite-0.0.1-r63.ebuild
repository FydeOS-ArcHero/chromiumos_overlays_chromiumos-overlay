# Copyright 2014 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="0041ad07c60ad4eb0bb0b63ecdfd4d69e19baf63"
CROS_WORKON_TREE="e5bfcc876ab2fcbd6b15e9705c5491baffdc3ce0"
CROS_WORKON_PROJECT="chromiumos/platform/frecon"
CROS_WORKON_LOCALNAME="../platform/frecon"
CROS_WORKON_OUTOFTREE_BUILD=1
CROS_WORKON_INCREMENTAL_BUILD=1

inherit cros-sanitizers cros-workon cros-common.mk toolchain-funcs

DESCRIPTION="Chrome OS KMS console (without DBUS/UDEV support)"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform/frecon"

LICENSE="BSD-Google"
KEYWORDS="*"
IUSE="-asan"

BDEPEND="virtual/pkgconfig"

COMMON_DEPEND="media-libs/libpng:0=
	sys-apps/libtsm:="

RDEPEND="${COMMON_DEPEND}"

DEPEND="${COMMON_DEPEND}
	media-sound/adhd:=
	x11-libs/libdrm:="

src_configure() {
	export FRECON_LITE=1
	sanitizers-setup-env
	cros-common.mk_src_configure
}