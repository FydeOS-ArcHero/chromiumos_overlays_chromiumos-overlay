# Copyright 2014 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="d17303e23372e838d0660c3d0c21530298f4c69c"
CROS_WORKON_TREE=("dea48af07754556aac092c0830de0b1ab410077b" "0639c7d00ce87330842831c8645dcba4b2f36846" "c218b19793213fbc08daad20dce926cf44766c10" "d395d3e37ff022de9a8afa82749b5e99692e7a28" "e7dba8c91c1f3257c34d4a7ffff0ea2537aeb6bb")
CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_USE_VCSID=1
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
# TODO(crbug.com/809389): Avoid directly including headers from other packages.
CROS_WORKON_SUBTREE="common-mk chaps metrics trunks .gn"

PLATFORM_SUBDIR="chaps"

inherit cros-workon platform systemd user

DESCRIPTION="PKCS #11 layer over TrouSerS"
HOMEPAGE="http://www.chromium.org/developers/design-documents/chaps-technical-design"
SRC_URI=""

LICENSE="BSD-Google"
KEYWORDS="*"
IUSE="systemd test tpm tpm2 fuzzer"

REQUIRED_USE="tpm2? ( !tpm )"

RDEPEND="
	!tpm2? (
		app-crypt/trousers:=
	)
	tpm2? (
		chromeos-base/trunks:=
	)
	chromeos-base/minijail:=
	chromeos-base/metrics:=
	!dev-db/leveldb
	dev-libs/leveldb:=
	dev-libs/openssl:=
	dev-libs/protobuf:=
"

DEPEND="${RDEPEND}
	test? ( app-arch/gzip )
	chromeos-base/system_api:=[fuzzer?]
	fuzzer? ( dev-libs/libprotobuf-mutator )
	tpm2? ( chromeos-base/trunks:=[test?] )
	"

src_install() {
	dosbin "${OUT}"/chapsd
	dobin "${OUT}"/chaps_client
	dobin "${OUT}"/p11_replay
	dolib.so "${OUT}"/lib/libchaps.so

	# Install D-Bus config file.
	dodir /etc/dbus-1/system.d
	sed 's,@POLICY_PERMISSIONS@,group="pkcs11",' \
		"org.chromium.Chaps.conf.in" \
		> "${D}/etc/dbus-1/system.d/org.chromium.Chaps.conf"

	# Install init scripts.
	if use systemd; then
		if use tpm2; then
			sed 's/tcsd.service/trunksd.service' \
				init/chapsd.service \
				> "${T}/chapsd.service"
			systemd_dounit "${T}/chapsd.service"
		else
			systemd_dounit init/chapsd.service
		fi
		systemd_enable_service boot-services.target chapsd.service
		systemd_dotmpfilesd init/chapsd_directories.conf
	else
		insinto /etc/init
		doins init/chapsd.conf
		if use tpm2; then
			sed -i 's/started tcsd/started trunksd/' \
				"${D}/etc/init/chapsd.conf" ||
				die "Can't replace tcsd with trunksd in chapsd.conf"
		fi
	fi
	exeinto /usr/share/cros/init

	# Install headers for use by clients.
	insinto /usr/include/chaps
	doins token_manager_client.h
	doins token_manager_client_mock.h
	doins token_manager_interface.h
	doins isolate.h
	doins chaps_proxy_mock.h
	doins chaps_interface.h
	doins chaps.h
	doins attributes.h

	# Install live tests
	if use test; then
		dosbin "${OUT}"/chapsd_test
		dosbin "${OUT}"/tpm_utility_test
	fi

	insinto /usr/include/chaps/pkcs11
	doins pkcs11/*.h

	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/chaps_attributes_fuzzer
	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/chaps_object_store_fuzzer
}

platform_pkg_test() {
	local tests=(
		chaps_test
		chaps_service_test
		dbus_test
		slot_manager_test
		session_test
		object_test
		object_policy_test
		object_pool_test
		object_store_test
		opencryptoki_importer_test
		isolate_login_client_test
	)
	use tpm2 && tests+=(
		tpm2_utility_test
	)

	local gtest_filter_qemu=""
	gtest_filter_qemu+="-*DeathTest*"
	gtest_filter_qemu+=":*ImportSample*"
	gtest_filter_qemu+=":TestSession.RSA*"
	gtest_filter_qemu+=":TestSession.KeyTypeMismatch"
	gtest_filter_qemu+=":TestSession.KeyFunctionPermission"
	gtest_filter_qemu+=":TestSession.BadKeySize"
	gtest_filter_qemu+=":TestSession.BadSignature.*"

	local test_bin
	for test_bin in "${tests[@]}"; do
		platform_test "run" "${OUT}/${test_bin}" "" "" "${gtest_filter_qemu}"
	done
}

pkg_preinst() {
	local ug
	for ug in attestation pkcs11 chaps; do
		enewuser "${ug}"
		enewgroup "${ug}"
	done
}
