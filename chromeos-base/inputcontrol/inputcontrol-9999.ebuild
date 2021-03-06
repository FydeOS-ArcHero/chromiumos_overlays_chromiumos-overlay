# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_PROJECT="chromiumos/platform/inputcontrol"
CROS_WORKON_LOCALNAME="platform/inputcontrol"

inherit cros-workon

DESCRIPTION="A collection of utilities for configuring input devices"
HOMEPAGE="http://www.chromium.org/"

LICENSE="BSD-Google"
KEYWORDS="~*"
IUSE=""

RDEPEND="app-arch/gzip"
DEPEND=""

src_configure() {
	cros-workon_src_configure
}
