# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2
CROS_WORKON_COMMIT="a6275a3ed87519efa193219c834e78852238f7e6"
CROS_WORKON_TREE="a71fd561bad9c3a53ed6b98c1df0dd1fb678acd5"

EAPI=4
CROS_WORKON_PROJECT="chromiumos/platform/wimax_manager"

inherit toolchain-funcs cros-debug cros-workon

DESCRIPTION="Chromium OS WiMAX Manager"
HOMEPAGE="http://www.chromium.org/"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 arm x86"
IUSE="test"

LIBCHROME_VERS="125070"

RDEPEND="
	chromeos-base/libchromeos
	chromeos-base/metrics
	dev-cpp/gflags
	dev-libs/dbus-c++
	>=dev-libs/glib-2.30
"

DEPEND="${RDEPEND}
	chromeos-base/libchrome:${LIBCHROME_VERS}[cros-debug=]
	net-wireless/gdmwimax
	test? ( dev-cpp/gmock )
	test? ( dev-cpp/gtest )
"

src_compile() {
	tc-export CXX CC OBJCOPY PKG_CONFIG STRIP
	cros-debug-add-NDEBUG
	emake OUT=build-opt BASE_VER=${LIBCHROME_VERS}
}

src_test() {
	emake OUT=build-opt BASE_VER=${LIBCHROME_VERS} tests
}

src_install() {
	# Install daemon executable.
	dosbin build-opt/wimax-manager

	# Install upstart config file.
	insinto /etc/init
	doins wimax_manager.conf
}
