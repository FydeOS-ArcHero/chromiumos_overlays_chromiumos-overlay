# Copyright 2018 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=6

CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_SUBTREE="common-mk diagnostics"

PLATFORM_SUBDIR="diagnostics"

inherit cros-workon platform

DESCRIPTION="Device telemetry and diagnostics for Chrome OS"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/master/diagnostics"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="~*"
IUSE=""

RDEPEND="
	chromeos-base/libbrillo:=
"
DEPEND="${RDEPEND}"

src_install() {
	dobin "${OUT}/diagnosticsd"
}

platform_pkg_test() {
	local tests=(
		diagnosticsd_test
	)

	local test_bin
	for test_bin in "${tests[@]}"; do
		platform_test "run" "${OUT}/${test_bin}"
	done
}
