# Copyright 2018 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="b1c9371a4574916181117c8f2b1c68c7e04eb6e9"
CROS_WORKON_TREE=("33378ea9ec0ce2140519976d43d90cb944b86813" "39a5f59e47af96d209f0cc50266beb20f614756a" "d5a78a696950572d4aaec93154465312b22a7119" "e7dba8c91c1f3257c34d4a7ffff0ea2537aeb6bb")
CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
# TODO(crbug.com/809389): Avoid directly including headers from other packages.
CROS_WORKON_SUBTREE="common-mk libtpmcrypto trunks .gn"

PLATFORM_SUBDIR="libtpmcrypto"

inherit cros-workon platform

DESCRIPTION="Encrypts/Decrypts data to a serialized proto with TPM sealed key."
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/master/libtpmcrypto/"

LICENSE="BSD-Google"
KEYWORDS="*"
IUSE="tpm tpm2"
REQUIRED_USE="tpm2? ( !tpm )"

# This depends on protobuf because it uses protoc and needs to be rebuilt
# whenever the protobuf library is updated since generated source files may be
# incompatible across different versions of the protobuf library.
COMMON_DEPEND="
	tpm2? (
		chromeos-base/trunks:=
	)
	!tpm2? (
		app-crypt/trousers:=
	)
	dev-libs/protobuf:=
"

RDEPEND="
	${COMMON_DEPEND}
"

DEPEND="
	${COMMON_DEPEND}
"

src_install() {
	dolib.so "${OUT}/lib/libtpmcrypto.so"

	"${S}"/platform2_preinstall.sh "${PV}" "/usr/include/chromeos" "${OUT}"
	insinto "/usr/$(get_libdir)/pkgconfig"
	doins "${OUT}/libtpmcrypto.pc"

	insinto "/usr/include/libtpmcrypto"
	doins *.h
}

platform_pkg_test() {
	local tests=(
		tpmcrypto_test
	)
	local test_bin
	for test_bin in "${tests[@]}"; do
		platform_test "run" "${OUT}/${test_bin}"
	done
}