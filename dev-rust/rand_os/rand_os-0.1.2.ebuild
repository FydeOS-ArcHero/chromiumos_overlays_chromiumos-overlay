# Copyright 2019 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

inherit cros-rust

DESCRIPTION="A random number generator that retrieves randomness straight from the operating system"
HOMEPAGE="https://github.com/rust-random/rand"
SRC_URI="https://crates.io/api/v1/crates/${PN}/${PV}/download -> ${P}.crate"

LICENSE="|| ( MIT Apache-2.0 )"
SLOT="${PV}/${PR}"
KEYWORDS="*"

DEPEND="
	>=dev-rust/cloudabi-0.0.3:=
	=dev-rust/fuchsia-cprng-0.1*:=
	=dev-rust/libc-0.2*:=
	=dev-rust/log-0.4*:=
	~dev-rust/rand_core-0.4.0:=
	~dev-rust/rdrand-0.4.0:=
	=dev-rust/stdweb-0.4*:=
	>=dev-rust/wasm-bindgen-0.2.12:=
	=dev-rust/winapi-0.3*:=
"
