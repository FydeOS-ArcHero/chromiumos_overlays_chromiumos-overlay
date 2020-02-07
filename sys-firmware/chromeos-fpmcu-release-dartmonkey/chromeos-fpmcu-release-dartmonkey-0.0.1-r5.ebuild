# Copyright 2019 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

# Increment the "eclass bug workaround count" below when you change
# "cros-ec-release.eclass" to work around http://crbug.com/220902.
#
# eclass bug workaround count: 1

EAPI=7

CROS_WORKON_COMMIT=("99b5e2c9852277cc5d828fc659b3da4d8fc88f9c" "0a5793abb36ca159efbc84a0a4aa1d566cbf1106" "e05bfa91102dd5137b4027b4f3405e041ffe2c32")
CROS_WORKON_TREE=("de24666c969f091c31d12557623a396b426a5991" "87e39cb12ae271131e61ca6d7500222f2cba380b" "1f42f6d549ba7b3f6bc5d67029984b113787ae0d")
FIRMWARE_EC_BOARD="dartmonkey"

CROS_WORKON_PROJECT=(
	"chromiumos/platform/ec"
	"chromiumos/third_party/tpm2"
	"chromiumos/third_party/cryptoc"
)

CROS_WORKON_LOCALNAME=(
	"../platform/release-firmware/fpmcu-dartmonkey"
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