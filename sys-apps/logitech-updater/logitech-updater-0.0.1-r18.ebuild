# Copyright 2017 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_COMMIT="3696d75e4dfe8e9b6887150f8f6370b8d32852fc"
CROS_WORKON_TREE="6c9267494195a1507305c3fa1a03f808dd08d4b4"
CROS_WORKON_PROJECT="chromiumos/third_party/logitech-updater"

inherit cros-workon libchrome udev user

DESCRIPTION="Logitech firmware updater"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/third_party/logitech-updater"

LICENSE="BSD-Google"
KEYWORDS="*"

COMMON_DEPEND="chromeos-base/libbrillo:=
	virtual/libusb:1=
	chromeos-base/libdfu_notification
"

RDEPEND="${COMMON_DEPEND}"
DEPEND="${COMMON_DEPEND}"

src_configure() {
	cros-workon_src_configure
}

src_install() {
	dosbin logitech-updater
	udev_dorules conf/99-logitech-updater.rules

	# Install seccomp policy.
	insinto "/usr/share/policy"
	newins "seccomp/logitech-updater-seccomp-${ARCH}.policy" logitech-updater-seccomp.policy
}

pkg_preinst() {
	enewuser cfm-firmware-updaters
	enewgroup cfm-firmware-updaters
}