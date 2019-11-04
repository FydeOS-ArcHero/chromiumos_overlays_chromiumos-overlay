# Copyright 2019 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

# This is separate from the chromite ebuild currently so that we *don't* track
# the chromite repo directly.  This stuff rarely changes, so we don't want to
# throw useless churn into the SDK.

EAPI="7"

PYTHON_COMPAT=( python{2_7,3_6,3_7} )

inherit cros-constants python-r1

DESCRIPTION="Blend chromite bits into the SDK"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/chromite/"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE=""

S="${WORKDIR}"

src_install() {
	install_python() {
		# TODO(crbug.com/771085): Figure out this SYSROOT business.
		local dir="$(python_get_sitedir | sed "s:^${SYSROOT}::")/chromite"

		dodir "${dir%/*}"
		dosym "${CHROOT_SOURCE_ROOT}/chromite" "${dir}"
	}
	python_foreach_impl install_python
}
