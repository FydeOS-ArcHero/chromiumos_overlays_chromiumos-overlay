# Copyright 2016 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=4

DESCRIPTION="Ebuild to support the Chrome OS CR50 device."

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"

RDEPEND="chromeos-base/ec-utils"

CR50_NAME="cr50.r0.0.9.w0.0.8"
TARBALL_NAME="${CR50_NAME}.tbz2"
SRC_URI="gs://chromeos-localmirror/distfiles/${TARBALL_NAME}"
S="${WORKDIR}"

src_install() {
	insinto /opt/google/cr50/firmware
	newins "${CR50_NAME}"/*.bin cr50.bin

	insinto /etc/init
	doins "${FILESDIR}"/*.conf
}
