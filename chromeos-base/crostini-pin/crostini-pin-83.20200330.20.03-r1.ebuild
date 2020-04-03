# Copyright 2019 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

# This ebuild does not install the Crostini container. Instead, it installs
# a .json file that is included on the rootfs to allow a pinned version of
# the Crostini container to be included as a build artifact for testing
# purposes.

EAPI="6"

inherit versionator

DESCRIPTION="Files for pinning the Crostini container version for testing"
HOMEPAGE="http://dev.chromium.org/"
SRC_URI=""

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE=""

S="${WORKDIR}"

src_compile() {
	local container_arch="unknown"
	case ${ARCH} in
		amd64) container_arch=amd64;;
		arm) container_arch=arm64;;
		arm64) container_arch=arm64;;
		*) die "Unsupported architecture: ${ARCH}";;
	esac

	local milestone="$(get_major_version)"
	local container_timestamp="$(version_format_string '$2_$3:$4')"

	cat > crostini_rootfs.json <<EOF
{
	"name": "container_rootfs",
	"version": "${PV}",
	"filename": "container_rootfs.tar.xz",
	"gsuri": "gs://cros-containers-staging/${milestone}/images/debian/stretch/${container_arch}/test/${container_timestamp}/rootfs.tar.xz"
}
EOF

cat > crostini_metadata.json <<EOF
{
	"name": "container_metadata",
	"version": "${PV}",
	"filename": "container_metadata.tar.xz",
	"gsuri": "gs://cros-containers-staging/${milestone}/images/debian/stretch/${container_arch}/test/${container_timestamp}/lxd.tar.xz"
}
EOF
}

src_install() {
	insinto /usr/local/opt/google/containers/pins
	doins crostini_rootfs.json
	doins crostini_metadata.json
}
