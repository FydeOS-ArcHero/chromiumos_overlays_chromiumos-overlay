# Copyright 2019 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

inherit cros-rust

DESCRIPTION="This is a helper for finding native MSVC ABI libraries in a Vcpkg installation from cargo build scripts."
HOMEPAGE="https://github.com/mcgoo/vcpkg-rs"
SRC_URI="https://crates.io/api/v1/crates/${PN}/${PV}/download -> ${P}.crate"

LICENSE="|| ( MIT Apache-2.0 )"
SLOT="${PV}/${PR}"
KEYWORDS="*"

DEPEND="
	=dev-rust/lazy_static-1*:=
	>=dev-rust/tempdir-0.3.7:=
"
