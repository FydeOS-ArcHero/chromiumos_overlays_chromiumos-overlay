# Copyright 1999-2018 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

CMAKE_BUILD_TYPE="Release"
inherit cmake-utils

if [[ ${PV} == *9999 ]] ; then
	: ${EGIT_REPO_URI:="https://github.com/intel/gmmlib"}
	if [[ ${PV%9999} != "" ]] ; then
		: ${EGIT_BRANCH:="release/${PV%.9999}"}
	fi
	inherit git-r3
fi

DESCRIPTION="Intel Graphics Memory Management Library"
HOMEPAGE="https://github.com/intel/gmmlib"
if [[ ${PV} == *9999 ]] ; then
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="https://github.com/intel/gmmlib/archive/intel-${P}.tar.gz"
	S="${WORKDIR}/${PN}-intel-${P}"
	KEYWORDS="*"
fi

LICENSE="MIT"
SLOT="0"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

PATCHES=(
	"${FILESDIR}"/0001-Provide-full-path-to-the-GMMULT-executable.patch
)

src_configure() {
	local mycmakeargs=(
		-DRUN_TEST_SUITE=OFF
	)

	cmake-utils_src_configure
}
