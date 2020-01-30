# Copyright 2017 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="388009cab8aca7ef2eb6652c67fc175fa0cc3326"
CROS_WORKON_TREE=("2ef18d1c42c7aee2c4bb4110359103045c055adf" "fe066ae9ce0bf6c03b8985a4dfd8d92afdb6175b" "e7dba8c91c1f3257c34d4a7ffff0ea2537aeb6bb")
CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
CROS_WORKON_SUBTREE="common-mk imageloader .gn"

PLATFORM_SUBDIR="imageloader/client"

inherit cros-workon platform

DESCRIPTION="ImageLoader DBus client library for Chromium OS"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/master/imageloader/"

LICENSE="BSD-Google"
KEYWORDS="*"
IUSE="cros_host"

# D-Bus proxies generated by this client library depend on the code generator
# itself (chromeos-dbus-bindings) and produce header files that rely on
# libbrillo library.
DEPEND="
	cros_host? ( chromeos-base/chromeos-dbus-bindings:= )
"

RDEPEND="chromeos-base/imageloader"

src_install() {
	# Install DBus client library.
	platform_install_dbus_client_lib "imageloader"
}