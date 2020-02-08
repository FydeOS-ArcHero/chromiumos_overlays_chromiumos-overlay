# Copyright 2019 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

# Increment the "eclass bug workaround count" below when you change
# "cros-ec-release.eclass" to work around http://crbug.com/220902.
#
# eclass bug workaround count: 1

EAPI=7

CROS_WORKON_COMMIT=("427c530edeefb7026f8b2b31a44b5bdfd9369a16" "a4b6290cd6253bbeaad508e18d933484ff6f1d30" "51c319ff23b6e5d6b3d8deb539a063edffb24483")
CROS_WORKON_TREE=("544f4509d13de665a632eb8801fabe32e352458e" "af8c38a147ac8f1b3e4c21212b5976bdb51c34aa" "5b25e42c84714218b06757c9d47399820bb64da5")
FIRMWARE_EC_BOARD="bloonchipper"

CROS_WORKON_PROJECT=(
	"chromiumos/platform/ec"
	"chromiumos/third_party/tpm2"
	"chromiumos/third_party/cryptoc"
)

CROS_WORKON_LOCALNAME=(
	"../platform/release-firmware/fpmcu-bloonchipper"
	"tpm2"
	"cryptoc"
)

CROS_WORKON_DESTDIR=(
	"${S}/platform/ec"
	"${S}/third_party/tpm2"
	"${S}/third_party/cryptoc"
)

inherit cros-workon cros-ec-release

HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform/ec/+/master/README.md"
LICENSE="BSD-Google"
KEYWORDS="*"