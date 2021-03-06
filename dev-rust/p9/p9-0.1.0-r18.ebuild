# Copyright 2018 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="6fb2fead5b8dd25c5ab89fca8138f09db41ce0b3"
CROS_WORKON_TREE="04d3c2c5a03fc535b999410d543700d020ba2e4f"
CROS_WORKON_LOCALNAME="../platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_SUBTREE="vm_tools/p9"

inherit cros-fuzzer cros-workon cros-rust

DESCRIPTION="Server implementation of the 9P file system protocol"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/master/vm_tools/p9/"

LICENSE="BSD-Google"
KEYWORDS="*"
IUSE="fuzzer test"

DEPEND="
	dev-rust/libc:=
	=dev-rust/proc-macro2-1*:=
	=dev-rust/quote-1*:=
	=dev-rust/syn-1*:=
	fuzzer? ( dev-rust/cros_fuzz:= )
"

RDEPEND="!!<=dev-rust/p9-0.1.0-r14"

get_crate_version() {
	local crate="$1"
	awk '/^version = / { print $3 }' "$1/Cargo.toml" | head -n1 | tr -d '"'
}

src_unpack() {
	cros-workon_src_unpack
	S+="/vm_tools/p9"

	cros-rust_src_unpack
}

src_compile() {
	use test && ecargo_test --no-run

	if use fuzzer; then
		cd fuzz
		ecargo_build_fuzzer
	fi
}

src_test() {
	if ! use x86 && ! use amd64 ; then
		elog "Skipping unit tests on non-x86 platform"
	else
		ecargo_test
	fi
}

src_install() {
	pushd wire_format_derive > /dev/null
	local version="$(get_crate_version .)"
	cros-rust_publish wire_format_derive "${version}"
	popd > /dev/null

	version="$(get_crate_version .)"
	cros-rust_publish p9 "${version}"

	if use fuzzer; then
		fuzzer_install "${S}/fuzz/OWNERS" \
			"$(cros-rust_get_build_dir)/p9_tframe_decode_fuzzer"
	fi
}

pkg_postinst() {
	cros-rust_pkg_postinst wire_format_derive
	cros-rust_pkg_postinst p9
}

pkg_prerm() {
	cros-rust_pkg_prerm wire_format_derive
	cros-rust_pkg_prerm p9
}
