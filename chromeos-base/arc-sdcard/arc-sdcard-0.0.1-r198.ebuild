# Copyright 2018 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="c90aa6f17dcbdeaf4e7c5ce155f3a685afdbfd01"
CROS_WORKON_TREE=("6efa0db0e49014be7389d66af98ab7469b93fc60" "8507735579e7fc9b3850039ffb51c77c9c39c64c" "e7dba8c91c1f3257c34d4a7ffff0ea2537aeb6bb")
CROS_WORKON_INCREMENTAL_BUILD="1"
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
CROS_WORKON_SUBTREE="common-mk arc/sdcard .gn"

PLATFORM_SUBDIR="arc/sdcard"

inherit cros-workon platform

DESCRIPTION="Container to run Android's sdcard daemon."
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/master/arc/sdcard"

LICENSE="BSD-Google"
KEYWORDS="*"
IUSE="esdfs"

CONTAINER_DIR="/opt/google/containers/arc-sdcard"

RDEPEND="!esdfs? ( chromeos-base/arc-setup )"
DEPEND="${DEPEND}"

src_install() {
	if ! use esdfs; then
		insinto /etc/init
		doins arc-sdcard.conf
	fi

	insinto "${CONTAINER_DIR}"
	doins "${OUT}"/rootfs.squashfs

	# Keep the parent directory of mountpoints inaccessible from non-root
	# users because mountpoints themselves are often world-readable but we
	# do not want to expose them.
	# container-root is where the root filesystem of the container in which
	# arc-obb-mounter daemon runs is mounted.
	diropts --mode=0700 --owner=root --group=root
	keepdir "${CONTAINER_DIR}"/mountpoints/
	keepdir "${CONTAINER_DIR}"/mountpoints/container-root
}