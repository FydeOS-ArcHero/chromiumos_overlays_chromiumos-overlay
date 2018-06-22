# Copyright 2017 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

DESCRIPTION="List of packages that are needed inside the SDK, but after we've
built all the toolchain packages that we install separately via binpkgs.  This
avoids circular dependencies when bootstrapping."
HOMEPAGE="http://dev.chromium.org/"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE=""

# The vast majority of packages should not be listed here!  You most likely
# want to update virtual/target-chromium-os-sdk instead.  Only list packages
# here that need the cross-compiler toolchains installed first.
RDEPEND="
	dev-lang/rust
	dev-util/cargo
	sys-apps/mosys
"
