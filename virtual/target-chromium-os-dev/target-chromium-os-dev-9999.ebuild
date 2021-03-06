# Copyright 2014 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

# This ebuild only cares about its own FILESDIR and ebuild file, so it tracks
# the canonical empty project.
CROS_WORKON_PROJECT="chromiumos/infra/build/empty-project"
CROS_WORKON_LOCALNAME="../platform/empty-project"

inherit cros-workon

DESCRIPTION="List of packages that are needed inside the Chromium OS dev image"
HOMEPAGE="https://dev.chromium.org/"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="~*"
# Note: Do not utilize USE=internal here.  Update virtual/target-chrome-os-dev.
IUSE="cras nvme pam opengl +power_management +profile
	+shill tpm tpm2 usb vaapi video_cards_intel
	chromeless_tty"

# The dependencies here are meant to capture "all the packages
# developers want to use for development, test, or debug".  This
# category is meant to include all developer use cases, including
# software test and debug, performance tuning, hardware validation,
# and debugging failures running autotest.
#
# To protect developer images from changes in other ebuilds you
# should include any package with a user constituency, regardless of
# whether that package is included in the base Chromium OS image or
# any other ebuild.
#
# Don't include packages that are indirect dependencies: only
# include a package if a file *in that package* is expected to be
# useful.

################################################################################
#
# CROS_* : Dependencies for CrOS devices (coreutils, etc.)
#
################################################################################
CROS_X86_RDEPEND="
	app-benchmarks/i7z
	power_management? ( dev-util/turbostat )
	sys-apps/dmidecode
	sys-apps/pciutils
	sys-boot/syslinux
	vaapi? ( media-gfx/vadumpcaps media-video/libva-utils )
	video_cards_intel? ( x11-apps/igt-gpu-tools )
"

RDEPEND="
	x86? ( ${CROS_X86_RDEPEND} )
	amd64? ( ${CROS_X86_RDEPEND} )
"

RDEPEND="${RDEPEND}
	pam? ( app-admin/sudo )
	app-admin/sysstat
	app-arch/bzip2
	app-arch/gzip
	app-arch/tar
	app-arch/unzip
	app-arch/xz-utils
	app-arch/zip
	profile? (
		chromeos-base/quipper
		app-benchmarks/libc-bench
		net-analyzer/netperf
		dev-util/perf
	)
	app-crypt/nss
	tpm? ( app-crypt/tpm-tools )
	app-editors/nano
	app-editors/qemacs
	app-editors/vim
	app-misc/edid-decode
	app-misc/evtest
	app-misc/pax-utils
	app-misc/screen
	app-portage/portage-utils
	app-shells/bash
	app-text/tree
	cras? (
		chromeos-base/audiotest
		media-sound/sox
	)
	chromeos-base/avtest_label_detect
	chromeos-base/chromeos-dev-root
	chromeos-base/cros-config-test
	chromeos-base/cryptohome-dev-utils
	tpm2? ( chromeos-base/g2f_tools )
	!chromeless_tty? ( chromeos-base/graphics-utils-go )
	chromeos-base/update-utils
	chromeos-base/policy_utils
	chromeos-base/protofiles
	!chromeless_tty? ( chromeos-base/screenshot )
	shill? ( chromeos-base/shill-test-scripts )
	chromeos-base/touch_firmware_test
	net-analyzer/tcpdump
	net-analyzer/traceroute
	net-dialup/minicom
	net-dns/bind-tools
	net-misc/dhcp
	net-misc/iperf:2
	net-misc/iputils
	net-misc/openssh
	net-misc/rsync
	net-wireless/iw
	net-wireless/wireless-tools
	dev-lang/python:2.7
	dev-lang/python:3.6
	dev-libs/libgpiod
	dev-python/protobuf-python
	dev-python/cherrypy
	dev-python/dbus-python
	dev-util/hdctools
	dev-util/mem
	dev-util/strace
	media-tv/v4l-utils
	media-video/yavta
	net-dialup/lrzsz
	net-fs/sshfs
	net-misc/curl
	net-misc/wget
	sys-apps/coreboot-utils
	sys-apps/coreutils
	sys-apps/diffutils
	sys-apps/file
	sys-apps/findutils
	sys-apps/flashrom-tester
	sys-apps/gawk
	sys-apps/i2c-tools
	sys-apps/iotools
	sys-apps/kbd
	sys-apps/less
	sys-apps/mmc-utils
	nvme? ( sys-apps/nvme-cli )
	sys-apps/portage
	sys-apps/smartmontools
	usb? ( sys-apps/usbutils )
	sys-apps/which
	sys-block/fio
	sys-devel/gdb
	sys-fs/fuse
	sys-fs/lvm2
	sys-fs/mtd-utils
	power_management? ( sys-power/powertop )
	sys-process/procps
	sys-process/psmisc
	sys-process/time
	virtual/autotest-capability
	virtual/chromeos-bsp-dev
"
