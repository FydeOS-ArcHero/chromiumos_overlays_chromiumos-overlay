# Copyright 2016 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=5

CROS_WORKON_COMMIT=("a0f172755fa87b358d1f913f3f898d8d9a25e001" "2e25490e360d2f57255b7eda8d1a4a9f51d1cd1a")
CROS_WORKON_TREE=("dea48af07754556aac092c0830de0b1ab410077b" "37e19db442fe0d9a96e3af1d7c568ac6f3fd7c0b" "e7dba8c91c1f3257c34d4a7ffff0ea2537aeb6bb" "1c710a0cfba96351fc28316a3af037893cbf4dad" "7b39269fbf100d5694714a910e004c1c67600080" "a05d9c3cb8b4e216e6fd9fef349374709aff7057")
CROS_WORKON_INCREMENTAL_BUILD=1

CROS_WORKON_PROJECT=(
	"chromiumos/platform2"
	"chromiumos/config"
)
CROS_WORKON_LOCALNAME=(
	"platform2"
	"config"
)
CROS_WORKON_SUBTREE=(
	"common-mk chromeos-config .gn power_manager"
	"python test"
)
CROS_WORKON_DESTDIR=(
	"${S}/platform2"
	"${S}/config"
)
PLATFORM_SUBDIR="chromeos-config"

inherit cros-workon platform

DESCRIPTION="Chrome OS configuration tools"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/master/chromeos-config"

LICENSE="BSD-Google"
SLOT=0
KEYWORDS="*"
IUSE=""

RDEPEND=""

DEPEND="${RDEPEND}"

src_install() {
	dolib.so "${OUT}/lib/libcros_config.so"

	insinto "/usr/include/chromeos/chromeos-config/libcros_config"
	doins "${S}"/libcros_config/*.h

	"${S}"/platform2_preinstall.sh "${PV}" "/usr/include/chromeos" "${OUT}"
	insinto "/usr/$(get_libdir)/pkgconfig"
	doins "${OUT}"/libcros_config.pc

	insinto "/usr/include/cros_config"
	doins "libcros_config/cros_config_interface.h"
	doins "libcros_config/cros_config.h"
	doins "libcros_config/fake_cros_config.h"

	dobin "${OUT}"/cros_config
	dosbin "${OUT}"/cros_configfs

	# Install init scripts.
	insinto /etc/init
	doins init/*.conf
}

platform_pkg_test() {
	# Run this here since we may not run cros_config_main_test.
	./chromeos-config-test-setup.sh
	local tests=(
		fake_cros_config_test
		cros_config_test
		cros_config_main_test
	)

	local test_bin
	for test_bin in "${tests[@]}"; do
		platform_test "run" "${OUT}/${test_bin}"
	done
	./run_tests.sh || die "cros_config unit tests have errors"
}
