# Copyright 2017 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_COMMIT="afd98dcd1de1bb1daf9436e16658021345a8d1e3"
CROS_WORKON_TREE=("142f8e8618a85124529b0000717d72079aa4ad97" "d5a78a696950572d4aaec93154465312b22a7119" "11cf580b60e9b5b8fdc05216e8ff2e2f29622168" "4362694196bc53a106e4395b625fa6cbdbd7e92c" "e7dba8c91c1f3257c34d4a7ffff0ea2537aeb6bb")
CROS_WORKON_USE_VCSID="1"
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
CROS_WORKON_INCREMENTAL_BUILD=1
# TODO(crbug.com/809389): Avoid directly including headers from other packages.
CROS_WORKON_SUBTREE="common-mk trunks metrics u2fd .gn"

PLATFORM_SUBDIR="u2fd"

inherit cros-workon platform user

DESCRIPTION="U2FHID Emulation Daemon"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/master/u2fhid"

LICENSE="BSD-Google"
KEYWORDS="*"
IUSE="fuzzer"

COMMON_DEPEND="
	chromeos-base/attestation:=
	chromeos-base/attestation-client:=
	chromeos-base/metrics:=
	chromeos-base/power_manager-client:=
	chromeos-base/trunks:=
	dev-libs/hidapi:=
"

RDEPEND="${COMMON_DEPEND}"

DEPEND="${COMMON_DEPEND}
	chromeos-base/attestation-client:=
	chromeos-base/system_api:=[fuzzer?]
"

pkg_setup() {
	# Has to be done in pkg_setup() instead of pkg_preinst() since
	# src_install() needs the u2f user and group.
	enewuser "u2f"
	enewgroup "u2f"
	cros-workon_pkg_setup
}

src_install() {
	dobin "${OUT}"/u2fd

	insinto /etc/init
	doins init/*.conf

	insinto /etc/dbus-1/system.d
	doins org.chromium.U2F.conf

	local daemon_store="/etc/daemon-store/u2f"
	dodir "${daemon_store}"
	fperms 0700 "${daemon_store}"
	fowners u2f:u2f "${daemon_store}"

	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/u2f_adpu_fuzzer
}

platform_pkg_test() {
	platform_test "run" "${OUT}/u2fd_test_runner"
}