# Copyright 2015 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

CROS_WORKON_COMMIT="84f7942b2fece1bfd2fc0ea54e9b025f387ab041"
CROS_WORKON_TREE=("861f66e9f884ebb293fb541a5501f183861a2dda" "d33af452545894a4015d3e685ef122cea924019c" "39a5f59e47af96d209f0cc50266beb20f614756a" "7e090ba54425d36a9899ce32e6195fa8e1b93335" "f25fa82fc2c04e9173bc337714b8d4256d495554" "9cb341b2cea326e9b1b922a5fe1b6ae11c4624e4" "e7dba8c91c1f3257c34d4a7ffff0ea2537aeb6bb")
CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
# TODO(crbug.com/809389): Avoid directly including headers from other packages.
CROS_WORKON_SUBTREE="common-mk libhwsec libtpmcrypto metrics tpm_manager trunks .gn"

PLATFORM_SUBDIR="tpm_manager"

inherit cros-workon platform user

DESCRIPTION="Daemon to manage TPM ownership."
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/master/tpm_manager/"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="*"
IUSE="distributed_cryptohome test tpm tpm2"

REQUIRED_USE="tpm2? ( !tpm )"

RDEPEND="
	!tpm2? ( app-crypt/trousers )
	tpm2? (
		chromeos-base/trunks
	)
	chromeos-base/metrics
	chromeos-base/minijail
	chromeos-base/libhwsec
	chromeos-base/libtpmcrypto
	"

DEPEND="${RDEPEND}
	tpm2? ( chromeos-base/trunks[test?] )
	"

pkg_preinst() {
	enewuser tpm_manager
	enewgroup tpm_manager
}

src_install() {
	# Install D-Bus configuration file.
	if use tpm2 || use distributed_cryptohome; then
		insinto /etc/dbus-1/system.d
		doins server/org.chromium.TpmManager.conf

		# Install upstart config file.
		insinto /etc/init
		doins server/tpm_managerd.conf
		if use tpm2; then
			sed -i 's/started tcsd/started trunksd/' \
				"${D}/etc/init/tpm_managerd.conf" ||
				die "Can't replace tcsd with trunksd in tpm_managerd.conf"
		fi

		# Install the executables provided by TpmManager
		dosbin "${OUT}"/tpm_managerd
		dosbin "${OUT}"/local_data_migration
		dobin "${OUT}"/tpm_manager_client

		# Install seccomp policy files.
		insinto /usr/share/policy
		newins server/tpm_managerd-seccomp-${ARCH}.policy tpm_managerd-seccomp.policy
	fi

	dolib.so "${OUT}"/lib/libtpm_manager.so
	dolib.a "${OUT}"/libtpm_manager_test.a


	# Install header files.
	insinto /usr/include/tpm_manager/client
	doins client/*.h
	insinto /usr/include/tpm_manager/common
	doins common/*.h
}

platform_pkg_test() {
	local tests=(
		tpm_manager_testrunner
	)

	local test_bin
	for test_bin in "${tests[@]}"; do
		platform_test "run" "${OUT}/${test_bin}"
	done
}