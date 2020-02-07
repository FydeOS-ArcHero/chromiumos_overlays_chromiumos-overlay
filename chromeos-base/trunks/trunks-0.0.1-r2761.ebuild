# Copyright 2014 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="b1c9371a4574916181117c8f2b1c68c7e04eb6e9"
CROS_WORKON_TREE=("33378ea9ec0ce2140519976d43d90cb944b86813" "d5a78a696950572d4aaec93154465312b22a7119" "e7dba8c91c1f3257c34d4a7ffff0ea2537aeb6bb")
CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
CROS_WORKON_SUBTREE="common-mk trunks .gn"

PLATFORM_SUBDIR="trunks"

inherit cros-workon platform user

DESCRIPTION="Trunks service for Chromium OS"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/master/trunks/"

LICENSE="Apache-2.0"
KEYWORDS="*"
IUSE="cr50_onboard fuzzer ftdi_tpm test tpm2_simulator"

# This depends on protobuf because it uses protoc and needs to be rebuilt
# whenever the protobuf library is updated since generated source files may be
# incompatible across different versions of the protobuf library.
COMMON_DEPEND="
	chromeos-base/minijail:=
	chromeos-base/power_manager-client:=
	ftdi_tpm? ( dev-embedded/libftdi:= )
	tpm2_simulator? ( chromeos-base/tpm2:= )
	dev-libs/protobuf:=
	fuzzer? (
		dev-cpp/gtest:=
	)
	"

RDEPEND="
	${COMMON_DEPEND}
	cr50_onboard? ( chromeos-base/chromeos-cr50 )
	!app-crypt/tpm-tools
	"

DEPEND="
	${COMMON_DEPEND}
	chromeos-base/chromeos-ec-headers:=
	"

src_install() {
	insinto /etc/dbus-1/system.d
	doins org.chromium.Trunks.conf

	insinto /etc/init
	if use tpm2_simulator; then
		newins trunksd.conf.tpm2_simulator trunksd.conf
	elif use cr50_onboard; then
		newins trunksd.conf.cr50 trunksd.conf
	else
		doins trunksd.conf
	fi

	dosbin "${OUT}"/pinweaver_client
	dosbin "${OUT}"/trunks_client
	dosbin "${OUT}"/trunks_send
	dosbin tpm_version
	dosbin "${OUT}"/trunksd
	dolib.so "${OUT}"/lib/libtrunks.so
	# trunks_test library implements trunks mocks which
	# are used by unittest and fuzzer.
	if use test || use fuzzer; then
		dolib.a "${OUT}"/libtrunks_test.a
	fi

	insinto /usr/share/policy
	newins trunksd-seccomp-${ARCH}.policy trunksd-seccomp.policy

	insinto /usr/include/trunks
	doins *.h
	doins "${OUT}"/gen/include/trunks/*.h

	insinto /usr/include/proto
	doins "${S}"/pinweaver.proto

	insinto /usr/include/chromeos/dbus/trunks
	doins "${S}"/interface.proto

	insinto "/usr/$(get_libdir)/pkgconfig"
	doins "${OUT}"/obj/trunks/libtrunks.pc
	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/trunks_creation_blob_fuzzer
	platform_fuzzer_install "${S}"/OWNERS \
		"${OUT}"/trunks_hmac_authorization_delegate_fuzzer
	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/trunks_key_blob_fuzzer
	platform_fuzzer_install "${S}"/OWNERS \
		"${OUT}"/trunks_password_authorization_delegate_fuzzer
	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/trunks_resource_manager_fuzzer
	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/trunks_tpm_pinweaver_fuzzer
}

platform_pkg_test() {
	"${S}/generator/generator_test.py" || die

	local tests=(
		trunks_testrunner
	)

	local test_bin
	for test_bin in "${tests[@]}"; do
		platform_test "run" "${OUT}/${test_bin}"
	done
}

pkg_preinst() {
	enewuser trunks
	enewgroup trunks
}