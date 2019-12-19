# Copyright 2015 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2.

EAPI=5

CROS_GO_SOURCE="go.googlesource.com/tools:golang.org/x/tools a434f64ace81347eff0fb4a32bc80a235e0ad762"

CROS_GO_PACKAGES=(
	"golang.org/x/tools/go/ast/astutil"
	"golang.org/x/tools/go/gcexportdata"
	"golang.org/x/tools/go/internal/gcimporter"
)

CROS_GO_TEST=(
	"${CROS_GO_PACKAGES[@]}"
)

CROS_GO_BINARIES=(
	"golang.org/x/tools/cmd/godoc"
	"golang.org/x/tools/cmd/goimports"
	"golang.org/x/tools/cmd/guru:goguru"
	"golang.org/x/tools/cmd/stringer"
)

inherit cros-go

DESCRIPTION="Packages and tools that support the Go programming language"
HOMEPAGE="https://golang.org/x/tools"
SRC_URI="$(cros-go_src_uri)"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE=""
RESTRICT="binchecks strip"

DEPEND=""
RDEPEND=""
