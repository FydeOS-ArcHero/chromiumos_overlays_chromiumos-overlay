# Copyright 2018 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=5
CROS_WORKON_PROJECT="chromiumos/platform/tast-tests"
CROS_WORKON_LOCALNAME="tast-tests"

# Test support packages that live above local/bundles/.
CROS_GO_TEST=(
	"chromiumos/tast/local/..."
)

inherit cros-workon tast-bundle

DESCRIPTION="Bundle of local integration tests for Chrome OS"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform/tast-tests/"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="~*"
IUSE=""

DEPEND="
	dev-go/cdp
	dev-go/dbus
	dev-go/gopsutil
"
RDEPEND="!chromeos-base/tast-local-tests"
