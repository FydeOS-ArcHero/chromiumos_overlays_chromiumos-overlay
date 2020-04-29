# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="43135447aa59aa5822a0bbf35a613144dab1dbda"
CROS_WORKON_TREE=("e7dba8c91c1f3257c34d4a7ffff0ea2537aeb6bb" "d58be6324ba2a1d0452d23bafb39c869c5ed2cd6" "1d838adcdcb6ec5d9913691cc1e34765ed00cf42" "612b52cf28b0531da3b29d6a9af5ac2a8c60e6bb" "093c7a01cb65cb24871c5a2ce7c2bdd0a536fccf" "dea48af07754556aac092c0830de0b1ab410077b")
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_LOCALNAME="../platform2"
CROS_WORKON_SUBTREE=".gn camera/build camera/common camera/include camera/mojo common-mk"
CROS_WORKON_OUTOFTREE_BUILD="1"
CROS_WORKON_INCREMENTAL_BUILD="1"

PLATFORM_SUBDIR="camera/common/libcamera_connector"

inherit cros-camera cros-workon platform

DESCRIPTION="Chrome OS camera connector for simpler uses."

LICENSE="BSD-Google"
KEYWORDS="*"

BDEPEND="virtual/pkgconfig"

RDEPEND="
	media-libs/cros-camera-libcamera_common
	media-libs/cros-camera-libcamera_ipc
	media-libs/cros-camera-libcbm"

DEPEND="${RDEPEND}
	media-libs/cros-camera-android-headers"

src_install() {
	dolib.so "${OUT}/lib/libcamera_connector.so"
	cros-camera_dopc ../libcamera_connector.pc.template
	cros-camera_doheader ../../include/cros-camera/camera_service_connector.h
}

