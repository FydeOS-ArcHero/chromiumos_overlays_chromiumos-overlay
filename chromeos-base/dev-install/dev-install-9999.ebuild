# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

# This ebuild file installs the developer installer package. It:
#  + Copies dev_install.
#  + Copies some config files for emerge: make.defaults and make.conf.
#  + Generates a list of packages installed (in base images).
# dev_install downloads and bootstraps emerge in base images without
# modifying the root filesystem.

EAPI="4"
CROS_WORKON_PROJECT="chromiumos/platform/dev-util"
CROS_WORKON_LOCALNAME="dev"
CROS_WORKON_OUTOFTREE_BUILD="1"

inherit cros-workon cros-board

DESCRIPTION="Chromium OS Developer Packages installer"
HOMEPAGE="http://www.chromium.org/chromium-os"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE=""

DEPEND="app-arch/tar
	sys-apps/coreutils
	sys-apps/grep
	sys-apps/portage
	sys-apps/sed"
# TODO(arkaitzr): remove dependency on tar if it's gonna be removed from the
# base image. Also modify dev_install.
RDEPEND="app-arch/tar
	net-misc/curl
	sys-apps/coreutils"

S=${WORKDIR}

src_prepare() {
	SRCDIR="${S}/dev-install"
	mkdir -p "$(cros-workon_get_build_dir)"
}

src_compile() {
	cd "$(cros-workon_get_build_dir)"

	local pkg pkgs BOARD=$(get_current_board_with_variant)

	pkgs=(
		# Generate a list of packages that go into the base image. These
		# packages will be assumed to be installed by emerge in the target.
		chromeos

		# Get the list of the packages needed to bootstrap emerge.
		portage

		# Get the list of dev and test packages.
		chromeos-dev
		chromeos-test
	)
	einfo "Ignore warnings below related to LD_PRELOAD/libsandbox.so"
	for pkg in ${pkgs[@]} ; do
		emerge-${BOARD} \
			--pretend --quiet --emptytree --ignore-default-opts \
			--root-deps=rdeps ${pkg} | \
			egrep -o ' [[:alnum:]-]+/[^[:space:]/]+\b' | \
			tr -d ' ' > ${pkg}.packages &
	done
	wait
	# No virtual packages in package.provided.
	grep -v "virtual/" chromeos.packages > package.provided

	python "${FILESDIR}"/filter.py || die

	# Add the board specific binhost repository.
	sed -e "s|BOARD|${BOARD}|g" "${SRCDIR}/repository.conf" > repository.conf

	# Add dhcp to the list of packages installed since its installation will not
	# complete (can not add dhcp group since /etc is not writeable). Bootstrap it
	# instead.
	grep "net-misc/dhcp-" chromeos-dev.packages >> package.provided
	grep "net-misc/dhcp-" chromeos-dev.packages >> bootstrap.packages
}

src_install() {
	local build_dir=$(cros-workon_get_build_dir)

	cd "${SRCDIR}"
	dobin dev_install

	insinto /etc/portage
	doins "${build_dir}"/{bootstrap.packages,repository.conf}

	insinto /etc/portage/make.profile
	doins "${build_dir}"/package.{installable,provided} make.{conf,defaults}

	insinto /etc/env.d
	doins 99devinstall

	# Python will be installed in /usr/local after running dev_install.
	dosym "/usr/local/bin/python2.6" "/usr/bin/python"
}
