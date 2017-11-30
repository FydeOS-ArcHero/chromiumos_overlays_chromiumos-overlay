# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

SCM=""
if [ "${PV%9999}" != "${PV}" ] ; then # Live ebuild
	SCM=git-r3
	EGIT_BRANCH=master
	EGIT_REPO_URI="https://github.com/01org/intel-vaapi-driver"
fi

AUTOTOOLS_AUTORECONF="yes"
inherit autotools-multilib ${SCM}

DESCRIPTION="HW video decode support for Intel integrated graphics"
HOMEPAGE="https://github.com/01org/intel-vaapi-driver"
if [ "${PV%9999}" != "${PV}" ] ; then # Live ebuild
	SRC_URI=""
	S="${WORKDIR}/${PN}"
else
	SRC_URI="https://github.com/01org/intel-vaapi-driver/archive/${PV}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}/intel-vaapi-driver-${PV}"
fi

LICENSE="MIT"
SLOT="0"
if [ "${PV%9999}" = "${PV}" ] ; then
	KEYWORDS="*"
else
	KEYWORDS=""
fi
IUSE="+drm wayland X hybrid_codec"

RDEPEND=">=x11-libs/libva-1.8.3[X?,wayland?,drm?]
	>=x11-libs/libdrm-2.4.46[video_cards_intel]
	hybrid_codec? ( media-libs/intel-hybrid-driver )
	wayland? ( >=media-libs/mesa-9.1.6[egl] >=dev-libs/wayland-1.0.6 )"

DEPEND="${RDEPEND}
	virtual/pkgconfig"

DOCS=( AUTHORS NEWS README )
AUTOTOOLS_PRUNE_LIBTOOL_FILES="all"

src_prepare() {
	epatch "${FILESDIR}"/no_explicit_sync_in_va_sync_surface.patch
	epatch "${FILESDIR}"/Avoid-GPU-crash-with-malformed-streams.patch
	epatch "${FILESDIR}"/set_multisample_state_for_gen6.patch
	epatch "${FILESDIR}"/disable_vp8_encoding.patch
	epatch "${FILESDIR}"/Disable-VP8-decoder-on-BDW.patch
	epatch "${FILESDIR}"/Don-t-check-the-stride-in-the-y-direction-for-a-sing.patch
	epatch "${FILESDIR}"/Change-the-vertical-alignment-for-linear-surface.patch
	epatch "${FILESDIR}"/Revert-Use-Media-Read-message-if-possible-on-Gen8.patch
# next seven patches are a specific backport for cyan h.264 encoder.  They are adapted
# to work only on this 1.8.3 build. When moving to libva-2.0 all seven patches can be
# safely removed
	epatch "${FILESDIR}"/make-gpe-utils-compatible-with-gen8.patch
	epatch "${FILESDIR}"/change-prefix-of-function-name-from-gen9-to-i965-in-.patch
	epatch "${FILESDIR}"/add-gen8-avc-encoder-kernel.patch
	epatch "${FILESDIR}"/add-structures-and-const-tables-related-with-gen8-av.patch
	epatch "${FILESDIR}"/add-init-kernel-set-curbe-send-surface-for-gen8-avc-.patch
	epatch "${FILESDIR}"/update-gen8-avc-encoder-code-path.patch
	epatch "${FILESDIR}"/change-file-name-prefix-from-gen9-to-i965-for-avc-en.patch

	sed -e 's/intel-gen4asm/\0diSaBlEd/g' -i configure.ac || die
	autotools-multilib_src_prepare
}

multilib_src_configure() {
	local myeconfargs=(
		$(use_enable drm)
		$(use_enable wayland)
		$(use_enable X x11)
		$(use_enable hybrid_codec)
	)
	autotools-utils_src_configure
}
