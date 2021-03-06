# Copyright (c) 2010 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_COMMIT="10dbd8f557c0cef1e41a2f00ef38834f31913adf"
CROS_WORKON_TREE="5858217ad29e54dd69c94a9be8da7ba4b050ff5c"
CROS_WORKON_PROJECT="chromiumos/third_party/trousers"

inherit cros-workon autotest

DESCRIPTION="Trousers TPM tests"
HOMEPAGE="http://www.chromium.org/"
SRC_URI=""
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
DEPEND="
	app-crypt/trousers
	!<chromeos-base/autotest-tests-0.0.1-r1521
"
RDEPEND="${DEPEND}"

# Enable autotest by default.
IUSE="${IUSE} +autotest"

IUSE_TESTS="
	+tests_hardware_TPM
"

IUSE="${IUSE} ${IUSE_TESTS}"

CROS_WORKON_LOCALNAME=trousers

# path from root of repo
AUTOTEST_CLIENT_SITE_TESTS=autotest

src_compile() {
	# for Makefile
	export TROUSERS_DIR=${WORKDIR}/${P}
	autotest_src_compile
}

