# Copyright 2015 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2.

EAPI=5

CROS_GO_SOURCE="go.googlesource.com/lint:golang.org/x/lint 5906bd5c48cd840279ace88b165057fbbd7fb35a"

CROS_GO_BINARIES=(
	"golang.org/x/lint/golint"
)

CROS_GO_PACKAGES=(
	"golang.org/x/lint"
)

inherit cros-go

DESCRIPTION="A linter for Go source code"
HOMEPAGE="https://github.com/golang/lint"
SRC_URI="$(cros-go_src_uri)"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE=""
RESTRICT="binchecks strip"

DEPEND="dev-go/go-tools"
RDEPEND=""
