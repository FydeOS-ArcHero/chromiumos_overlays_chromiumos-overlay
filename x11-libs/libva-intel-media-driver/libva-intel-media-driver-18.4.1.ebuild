# Copyright 1999-2018 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

CMAKE_BUILD_TYPE="Release"
inherit cmake-utils

if [[ ${PV} == *9999 ]] ; then
	: ${EGIT_REPO_URI:="https://github.com/intel/media-driver"}
	if [[ ${PV%9999} != "" ]] ; then
		: ${EGIT_BRANCH:="release/${PV%.9999}"}
	fi
	inherit git-r3
fi

DESCRIPTION="Intel Media Driver for VAAPI (iHD)"
HOMEPAGE="https://github.com/intel/media-driver"
if [[ ${PV} == *9999 ]] ; then
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="https://github.com/intel/media-driver/archive/intel-media-${PV}.tar.gz"
	S="${WORKDIR}/media-driver-intel-media-${PV}"
	KEYWORDS="*"
fi

LICENSE="MIT BSD"
SLOT="0"
IUSE=""

DEPEND=">=media-libs/gmmlib-${PV}
	>=x11-libs/libva-2.4.0
	>=x11-libs/libpciaccess-0.10
"
RDEPEND="${DEPEND}"

PATCHES=(
	"${FILESDIR}"/0001-Adjust-compile-flags-for-clang.patch
	"${FILESDIR}"/0002-Decode-Align-the-height-for-external-surfaces.patch
	"${FILESDIR}"/0003-Allow-I420-for-surface-creation.patch
	"${FILESDIR}"/0004-Don-t-look-for-X-package.patch
	"${FILESDIR}"/0006-VP-Add-VAProfileVP9Profile2-support-for-VA_RT_FORMAT.patch
	"${FILESDIR}"/0007-register-reconstruct-surfaces.patch
	"${FILESDIR}"/0008-Decode-Fix-partition-lengths-for-MFD_VP8_BSD_OBJECT.patch
	"${FILESDIR}"/0009-Add-X11_FOUND-flag.patch
	"${FILESDIR}"/0010-Keep-the-right-slice-number-for-bitstream-buffer.patch
	"${FILESDIR}"/0011-Encode-Add-some-device-IDs-for-CML.patch
	"${FILESDIR}"/0012-set-vp8-encode-max-resolution-to-4k.patch
	"${FILESDIR}"/0013-reset-BRC-when-the-target-bitrate-or-max-bitrate-changed.patch
	"${FILESDIR}"/0014-Encode-Fix-the-num_token_partitions-for-VP8-encode.patch
	"${FILESDIR}"/0015-ignore-error-status-value-for-jpeg-decode.patch
	"${FILESDIR}"/0016-VP-Add-VP-pipeline-in-PutImage.patch
	"${FILESDIR}"/0017-VP-Add-NV21-kernel-rule.patch
	"${FILESDIR}"/0018-VP-Refactor-image-creation-and-image-capability.patch
	"${FILESDIR}"/0019-Encoder-VP8-GEN9-GEN10-GEN11-Ensure-forced_lf_adjust.patch
	"${FILESDIR}"/0020-Fix-Clang-Warning.patch
)

src_configure() {
	local mycmakeargs=(
		-DMEDIA_VERSION="18.4.1"
		-DMEDIA_RUN_TEST_SUITE=OFF
		-DINSTALL_DRIVER_SYSCONF=OFF
		-DBUILD_CMRTLIB=OFF
	)

	cmake-utils_src_configure
}
