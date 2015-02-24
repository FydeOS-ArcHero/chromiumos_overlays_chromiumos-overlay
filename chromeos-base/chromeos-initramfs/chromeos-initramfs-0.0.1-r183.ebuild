# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=4
CROS_WORKON_COMMIT="fbf33b5c40669e3719a0bb751040516fa8223475"
CROS_WORKON_TREE="a88fa20b479f9f2d221b21e2a9630258b342461a"
CROS_WORKON_PROJECT="chromiumos/platform/initramfs"
CROS_WORKON_LOCALNAME="initramfs"
CROS_WORKON_OUTOFTREE_BUILD="1"

inherit cros-workon cros-board

DESCRIPTION="Create Chrome OS initramfs"
HOMEPAGE="http://www.chromium.org/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="frecon +interactive_recovery -mtd netboot_ramfs +power_management"

# Packages required for building recovery initramfs.
RECOVERY_DEPENDS="
	chromeos-base/chromeos-installer
	chromeos-base/common-assets
	chromeos-base/vboot_reference
	chromeos-base/vpd
	media-gfx/ply-image
	sys-apps/flashrom
	sys-apps/pv
	sys-fs/lvm2
	virtual/assets
	"

# Packages required for building factory installer shim initramfs.
FACTORY_SHIM_DEPENDS="
	chromeos-base/chromeos-installshim
	chromeos-base/vboot_reference
	"

# Packages required for building factory netboot installer initramfs.
FACTORY_NETBOOT_DEPENDS="
	app-arch/sharutils
	app-shells/bash
	chromeos-base/chromeos-base
	chromeos-base/chromeos-factoryinstall
	chromeos-base/chromeos-installer
	chromeos-base/chromeos-installshim
	chromeos-base/ec-utils
	chromeos-base/memento_softwareupdate
	chromeos-base/vboot_reference
	chromeos-base/vpd
	dev-libs/openssl
	dev-util/shflags
	dev-util/xxd
	net-misc/htpdate
	net-misc/wget
	sys-apps/coreutils
	sys-apps/flashrom
	sys-apps/util-linux
	sys-block/parted
	sys-fs/dosfstools
	sys-fs/e2fsprogs
	sys-libs/ncurses
	sys-apps/iproute2
	"

DEPEND="${RECOVERY_DEPENDS}
	${FACTORY_SHIM_DEPENDS}
	netboot_ramfs? ( ${FACTORY_NETBOOT_DEPENDS} )
	sys-apps/busybox[-make-symlinks]
	chromeos-base/chromeos-init
	frecon? ( sys-apps/frecon )
	power_management? ( chromeos-base/power_manager ) "

RDEPEND=""

src_prepare() {
	local srcroot='/mnt/host/source'
	export BUILD_LIBRARY_DIR="${srcroot}/src/scripts/build_library"
	export INTERACTIVE_COMPLETE="$(usex interactive_recovery true false)"

	# Need the lddtree from the chromite dir.
	local chromite_bin="${srcroot}/chromite/bin"
	export PATH="${chromite_bin}:${PATH}"
}

src_compile() {
	local deps=()
	use frecon && deps+=(/sbin/frecon)
	use power_management && deps+=(/usr/bin/backlight_tool)
	use mtd && deps+=(/usr/bin/cgpt.bin)

	local targets=(factory_shim recovery)
	use netboot_ramfs && targets+=(factory_netboot)

	emake SYSROOT="${SYSROOT}" BOARD="$(get_current_board_with_variant)" \
		OUTPUT_DIR="${WORKDIR}" OPTIONAL_DEPS="${deps[*]}" ${targets[*]}
}

src_install() {
	insinto /var/lib/misc
	doins "${WORKDIR}"/initramfs.cpio.xz
	doins "${WORKDIR}"/factory_shim_ramfs.cpio.xz
	use netboot_ramfs && doins "${WORKDIR}"/netboot_ramfs.cpio.xz
}
