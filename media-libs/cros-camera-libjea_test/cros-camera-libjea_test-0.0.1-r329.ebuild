# Copyright 2018 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=5

CROS_WORKON_COMMIT="b03a25287d8370084464788ceb489b8c732415e2"
CROS_WORKON_TREE=("e7dba8c91c1f3257c34d4a7ffff0ea2537aeb6bb" "d58be6324ba2a1d0452d23bafb39c869c5ed2cd6" "7d460d2da286d6e7ed8fd47fe005ee3040ccb930" "612b52cf28b0531da3b29d6a9af5ac2a8c60e6bb" "4d12bab3d459cb0c9801c4e1742df6f9010b7ebb" "dea48af07754556aac092c0830de0b1ab410077b" "c218b19793213fbc08daad20dce926cf44766c10")
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_LOCALNAME="../platform2"
CROS_WORKON_SUBTREE=".gn camera/build camera/common camera/include camera/mojo common-mk metrics"
CROS_WORKON_OUTOFTREE_BUILD="1"
CROS_WORKON_INCREMENTAL_BUILD="1"

PLATFORM_SUBDIR="camera/common/jpeg/libjea_test"

inherit cros-camera cros-workon platform

DESCRIPTION="End to end test for JPEG encode accelerator"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"

RDEPEND="
	chromeos-base/metrics
	dev-cpp/gtest:=
	media-libs/cros-camera-libcamera_common
	media-libs/cros-camera-libcamera_exif
	media-libs/cros-camera-libcamera_ipc
	media-libs/cros-camera-libcamera_metadata
	media-libs/cros-camera-libcbm
	media-libs/libyuv"

DEPEND="${RDEPEND}
	chromeos-base/metrics
	media-libs/libyuv
	media-libs/cros-camera-android-headers"

src_install() {
	dobin "${OUT}/libjea_test"
}