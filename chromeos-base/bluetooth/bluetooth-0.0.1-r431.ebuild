# Copyright 2018 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_COMMIT="940ca4da805d83c9e25919c7146bee62523d6c57"
CROS_WORKON_TREE=("03bbbcee411f17ba1fc689765743cc4876d16cbb" "8bc6068d6e25ed98aa7ab2a0f91a2d2c1dfaa6d6" "4e28123273d6286f8decd2b6774e39ec1310dbb3" "e7dba8c91c1f3257c34d4a7ffff0ea2537aeb6bb")
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_SUBTREE="common-mk chromeos-config bluetooth .gn"

PLATFORM_SUBDIR="bluetooth"

inherit cros-workon platform

DESCRIPTION="Bluetooth service for Chromium OS"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/master/bluetooth"

LICENSE="BSD-Google"
KEYWORDS="*"
IUSE="+bluetooth_suspend_management fuzzer generated_cros_config seccomp unibuild"

RDEPEND="
	chromeos-base/chromeos-config-tools:=
	unibuild? (
		!generated_cros_config? ( chromeos-base/chromeos-config )
		generated_cros_config? ( chromeos-base/chromeos-config-bsp:= )
	)
	net-wireless/bluez:=
"

DEPEND="${RDEPEND}
	chromeos-base/system_api:=[fuzzer?]"

src_install() {
	dobin "${OUT}"/btdispatch

	insinto /etc/dbus-1/system.d
	doins dbus/org.chromium.Bluetooth.conf

	insinto /etc/init
	doins init/upstart/btdispatch.conf

	if use seccomp; then
		# Install seccomp policy files.
		insinto /usr/share/policy
		newins "seccomp_filters/btdispatch-seccomp-${ARCH}.policy" btdispatch-seccomp.policy
	else
		# Remove seccomp flags from minijail parameters.
		sed -i '/^env seccomp_flags=/s:=.*:="":' "${ED}"/etc/init/btdispatch.conf || die
	fi
}

platform_pkg_test() {
	platform_test "run" "${OUT}/bluetooth_test"
}