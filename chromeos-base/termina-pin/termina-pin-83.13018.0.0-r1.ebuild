# Copyright 2019 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

# This ebuild does not install the Termina VM. Instead, it installs a .json file
# that is included on the rootfs to allow a pinned version of the Termina VM
# to be included as a build artifact for testing purposes.

EAPI="6"

inherit versionator

DESCRIPTION="File for pinning the Termina version for testing"
HOMEPAGE="http://dev.chromium.org/"
SRC_URI=""

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE=""

S="${WORKDIR}"

src_compile() {
	local gs_arch="unknown"
	case ${ARCH} in
		amd64) gs_arch=intel64;;
		arm) gs_arch=arm32;;
		arm64) gs_arch=arm32;;
		*) die "Unsupported architecture: ${ARCH}";;
	esac

	local milestone="$(get_major_version)"
	local platform_version="$(get_after_major_version)"
	cat > termina.json <<EOF
{
    "name": "termina",
    "version": "${PV}",
    "filename": "vm_image.zip",
    "gsuri": "gs://termina-component-testing/${milestone}/${platform_version}/chromeos_${gs_arch}-archive/files.zip"
}
EOF
}

src_install() {
	insinto /usr/local/opt/google/containers/pins
	doins termina.json
}
