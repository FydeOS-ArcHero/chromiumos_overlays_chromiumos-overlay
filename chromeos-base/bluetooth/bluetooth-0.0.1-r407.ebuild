# Copyright 2018 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_COMMIT="e9cea82687d60e10566f8069f834403ca03f8f70"
CROS_WORKON_TREE=("33378ea9ec0ce2140519976d43d90cb944b86813" "8bcd8c698ec0c922eebfc3cd860d31e7c0558448" "cdd561e3db24d82f9bce4bd758d7f81aaaeea1ce" "e7dba8c91c1f3257c34d4a7ffff0ea2537aeb6bb")
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
	chromeos-base/newblue:=
	net-wireless/bluez:=
"

DEPEND="${RDEPEND}
	chromeos-base/system_api:=[fuzzer?]"

src_install() {
	dobin init/scripts/bluetooth-setup.sh
	dobin "${OUT}"/btdispatch

	insinto /etc/dbus-1/system.d
	doins dbus/org.chromium.Bluetooth.conf

	insinto /etc/init
	doins init/upstart/bluetooth-setup.conf
	doins init/upstart/btdispatch.conf

	if use seccomp; then
		# Install seccomp policy files.
		insinto /usr/share/policy
		newins "seccomp_filters/btdispatch-seccomp-${ARCH}.policy" btdispatch-seccomp.policy
	else
		# Remove seccomp flags from minijail parameters.
		sed -i '/^env seccomp_flags=/s:=.*:="":' "${ED}"/etc/init/btdispatch.conf || die
	fi

	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/bluetooth_parsedataintouuids_fuzzer
	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/bluetooth_parsedataintoservicedata_fuzzer
	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/bluetooth_parseeir_fuzzer
	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/bluetooth_parsereportdescriptor_fuzzer
	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/bluetooth_trimadapterfromobjectpath_fuzzer
	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/bluetooth_trimdevicefromobjectpath_fuzzer
	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/bluetooth_trimservicefromobjectpath_fuzzer
	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/bluetooth_trimcharacteristicfromobjectpath_fuzzer
	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/bluetooth_trimdescriptorfromobjectpath_fuzzer
}

platform_pkg_test() {
	platform_test "run" "${OUT}/bluetooth_test"
}