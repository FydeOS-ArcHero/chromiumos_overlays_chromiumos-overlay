# Copyright (c) 2019 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the BSD license.

EAPI="6"
CROS_WORKON_COMMIT="dea0a6324f58e13c1c0b23ea33626f5211675a6f"
CROS_WORKON_TREE="1924486c94845c319094c6239e8f85d11730d153"
CROS_WORKON_PROJECT="chromiumos/platform/touch_updater"
CROS_WORKON_LOCALNAME="touch_updater"
CROS_WORKON_SUBTREE="etphidiap"
CROS_WORKON_OUTOFTREE_BUILD=1

inherit cros-workon user

DESCRIPTION="Wrapper for etphidiap touch firmware updater."
HOMEPAGE="https://www.chromium.org/chromium-os"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"

RDEPEND="
	chromeos-base/chromeos-touch-common
	sys-apps/etphidiap
"

pkg_preinst() {
	enewgroup fwupdate-i2c
	enewuser fwupdate-i2c
}

src_install() {
	exeinto "/opt/google/touch/scripts"
	doexe etphidiap/scripts/*.sh

	if [ -d "etphidiap/policies/${ARCH}" ]; then
		insinto "/opt/google/touch/policies"
		doins etphidiap/policies/"${ARCH}"/*.policy
	fi
}
