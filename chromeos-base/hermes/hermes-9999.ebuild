# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_SUBTREE="common-mk hermes .gn"

PLATFORM_SUBDIR="hermes"

inherit cros-workon platform

DESCRIPTION="Chrome OS eSIM/EUICC integration"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/master/hermes"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="~*"
IUSE=""

RDEPEND="
	chromeos-base/libbrillo:=
	"

DEPEND="
	${RDEPEND}
	chromeos-base/google-lpa:=
	chromeos-base/system_api:=
	"

src_install() {
	dobin "${OUT}"/hermes

	# Install CA certs.
	local cert_dir=/usr/share/hermes-ca-certificates
	insinto "${cert_dir}"
	doins -r certs/*
	c_rehash "${D}/${cert_dir}/prod" || die
	c_rehash "${D}/${cert_dir}/test" || die
}

platform_pkg_test() {
	platform_test "run" "${OUT}/hermes_test"
}
