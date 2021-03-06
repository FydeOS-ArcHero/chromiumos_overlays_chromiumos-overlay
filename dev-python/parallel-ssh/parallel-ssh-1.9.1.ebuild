# Copyright 2019 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2.

EAPI=6

PYTHON_COMPAT=( python{2_7,3_4,3_5,3_6} pypy )

inherit distutils-r1

DESCRIPTION="Asynchronous parallel SSH client library."
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="*"

RDEPEND="dev-python/gevent
		dev-python/ssh2-python
		net-libs/libssh2"

DEPEND="${RDEPEND}
	dev-python/setuptools[${PYTHON_USEDEP}]"
