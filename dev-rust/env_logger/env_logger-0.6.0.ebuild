# Copyright 2019 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

inherit cros-rust

DESCRIPTION="Implements a logger that can be configured via environment variables."
HOMEPAGE="https://github.com/sebasmagri/env_logger/"
SRC_URI="https://crates.io/api/v1/crates/${PN}/${PV}/download -> ${P}.crate"

LICENSE="|| ( MIT Apache-2.0 )"
SLOT="${PV}/${PR}"
KEYWORDS="*"

DEPEND="
	=dev-rust/log-0.4*:=
	>=dev-rust/atty-0.2.5:=
	=dev-rust/humantime-1.1*:=
	>=dev-rust/regex-1.0.3:=
	>=dev-rust/termcolor-0.3.0:=
"
