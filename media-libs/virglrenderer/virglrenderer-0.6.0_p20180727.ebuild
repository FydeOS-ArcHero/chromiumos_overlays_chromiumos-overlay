# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

inherit autotools cros-fuzzer cros-sanitizers eutils flag-o-matic toolchain-funcs

if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="https://anongit.freedesktop.org/git/virglrenderer.git"
	KEYWORDS="~*"
	inherit git-r3
else
	GIT_SHA1="9c420d224d86215d408dff8dea599ed9414a24d6"
	SRC_URI="https://github.com/freedesktop/virglrenderer/archive/${GIT_SHA1}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}/${PN}-${GIT_SHA1}"
	KEYWORDS="*"
fi

# Uncomment the following line temporarily to update the manifest when updating
# the pinned version via: ebuild $(equery w virglrenderer) manifest
#RESTRICT=nomirror

DESCRIPTION="library used implement a virtual 3D GPU used by qemu"
HOMEPAGE="https://virgil3d.github.io/"

LICENSE="MIT"
SLOT="0"
IUSE="fuzzer profiling static-libs test"

RDEPEND="
	>=x11-libs/libdrm-2.4.50
	media-libs/libepoxy
	fuzzer? ( media-libs/mesa[gbm] )
"
# We need autoconf-archive for @CODE_COVERAGE_RULES@. #568624
DEPEND="${RDEPEND}
	sys-devel/autoconf-archive
	>=x11-misc/util-macros-1.8
	test? ( >=dev-libs/check-0.9.4 )"

PATCHES=(
	"${FILESDIR}"/${PN}-0.6.0-libdrm.patch
)

src_prepare() {
	default
	[[ -e configure ]] || eautoreconf
}

src_configure() {
	sanitizers-setup-env

	if use profiling; then
		append-flags -fprofile-instr-generate -fcoverage-mapping
		append-ldflags -fprofile-instr-generate -fcoverage-mapping
	fi
	econf \
		$(use_enable static-libs static) \
		$(use_enable test tests) \
		$(use_enable fuzzer)
}

src_install() {
	default

	local f="tests/fuzzer/.libs/virgl_fuzzer"
	fuzzer_install "${FILESDIR}/fuzzer-OWNERS" "${f}"

	find "${ED}"/usr -name 'lib*.la' -delete
}
