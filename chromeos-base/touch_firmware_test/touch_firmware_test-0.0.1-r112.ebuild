# Copyright 2015 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_COMMIT="a62af2362e813c565a9c5e865855b1f3d77f614a"
CROS_WORKON_TREE="e6eebfca19ad41639408ed17b95f835349e8f660"
CROS_WORKON_PROJECT="chromiumos/platform/touch_firmware_test"
CROS_WORKON_LOCALNAME="platform/touch_firmware_test"

PYTHON_COMPAT=( python2_7 )
inherit cros-sanitizers cros-workon cros-constants cros-debug distutils-r1

DESCRIPTION="Chromium OS multitouch utilities"

LICENSE="BSD-Google"
SLOT="0/0"
KEYWORDS="*"
IUSE="-asan"

RDEPEND=""

DEPEND=${RDEPEND}

src_prepare() {
	cros-workon_src_prepare
}

src_configure() {
	sanitizers-setup-env
	cros-workon_src_configure
}

src_install() {
	# install the remote package
	distutils-r1_src_install

	# install the webplot script
	exeinto /usr/local/bin
	newexe webplot/chromeos_wrapper.sh webplot

	# install the heatmapplot script
	newexe heatmap/chromeos_heatmapplot_wrapper.sh heatmapplot

	# install to autotest deps directory for dependency
	DESTDIR="${D}${AUTOTEST_BASE}/client/deps/touchpad-tests/touch_firmware_test"
	mkdir -p "${DESTDIR}"
	echo "CMD:" cp -Rp "${S}"/* "${DESTDIR}"
	cp -Rp "${S}"/* "${DESTDIR}"
}