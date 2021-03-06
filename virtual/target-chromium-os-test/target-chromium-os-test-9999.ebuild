# Copyright 2014 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

# This ebuild only cares about its own FILESDIR and ebuild file, so it tracks
# the canonical empty project.
CROS_WORKON_PROJECT="chromiumos/infra/build/empty-project"
CROS_WORKON_LOCALNAME="../platform/empty-project"

inherit cros-workon

DESCRIPTION="List of packages that are needed inside the Chromium OS test image;
Note: test images are a superset of dev images."
HOMEPAGE="https://dev.chromium.org/"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="~*"
# Note: Do not utilize USE=internal here.  Update virtual/target-chrome-os-test.
IUSE="
	arc-camera3
	biod
	-chromeless_tests
	cheets
	chromeless_tty
	cr50_onboard
	+cras
	cros_ec
	cros_embedded
	kvm_host
	hammerd
	opengl
	opengles
	p2p
	+shill
	+tpm
	tpm2
	unibuild
	vaapi
	wifi_hostap_test
	wifi_testbed_ap
	+wired_8021x
"

# Packages required to support autotest images.  Dependencies here
# are for packages that must be present on a local device and that
# are not downloaded by the autotest server.  This includes both
# packages relied on by the server, as well as packages relied on by
# specific tests.
#
# This package is not meant to capture tools useful for test debug;
# use the chromeos-dev package for that purpose.
#
# Note that some packages used by autotest are actually built by the
# autotest package and downloaded by the server, regardless of
# whether the package is present on the target device; those
# packages aren't listed here.
#
# Developers should be aware that packages installed by this ebuild
# are rooted in /usr/local.  This means that libraries are installed
# in /usr/local/lib, executables in /usr/local/bin, etc.
#
# TODO(jrbarnette):  It's not known definitively that the list
# below contains no unneeded dependencies.  More work is needed to
# determine for sure that every package listed is actually used.


################################################################################
#
# CROS_COMMON_* : Dependencies common to all CrOS flavors (embedded, regular)
#
################################################################################

CROS_COMMON_RDEPEND="
	tpm? (
		app-crypt/tpm-tools
		chromeos-base/tpm_softclear_utils
	)
	tpm2? ( chromeos-base/tpm_softclear_utils )
	chromeos-base/chromeos-test-root
	chromeos-base/ec-utils
	chromeos-base/ec-utils-test
	chromeos-base/factory-deps
	biod? ( virtual/chromeos-fpmcu-test )
	hammerd? ( chromeos-base/hammerd-test-utils )
	chromeos-base/recover-duts
	chromeos-base/tast-local-test-runner
	chromeos-base/tast-local-tests
	chromeos-base/tast-use-flags
	chromeos-base/verity
	chromeos-base/vpd
	cros_ec? ( chromeos-base/ec-devutils )
	!chromeless_tty? (
		!chromeless_tests? (
			>=dev-cpp/gflags-2.0
		)
	)
	wifi_testbed_ap? (
		dev-python/btsocket
	)
	dev-lang/python:2.7
	dev-lang/python:3.6
	p2p? ( dev-python/dpkt )
	cr50_onboard? ( dev-util/u2f-ref-code )
	net-misc/rsync
	sys-apps/memtester
	virtual/autotest-capability
	virtual/chromeos-bsp-test
	kvm_host? (
		chromeos-base/crostini-pin
		chromeos-base/termina-pin
	)
"

# Packages needed by FAFT.
CROS_COMMON_RDEPEND+="
	sys-apps/hdparm
	sys-apps/mmc-utils
"

################################################################################
#
# CROS_* : Dependencies for "regular" CrOS devices (coreutils, etc.)
#
################################################################################
CROS_X86_RDEPEND="
	app-benchmarks/sysbench
	sys-apps/pciutils
	sys-power/iasl
	vaapi? ( media-gfx/vadumpcaps media-video/libva-utils )
	x11-misc/read-edid
"

CROS_RDEPEND="
	x86? ( ${CROS_X86_RDEPEND} )
	amd64? ( ${CROS_X86_RDEPEND} )
"

CROS_RDEPEND="${CROS_RDEPEND}
	app-admin/sudo
	app-arch/gzip
	app-arch/tar
	app-benchmarks/blktests
	app-benchmarks/blogbench
	app-benchmarks/lmbench
	app-benchmarks/microbenchmarks
	app-benchmarks/pjdfstest
	app-benchmarks/xfstests
	app-misc/ckermit
	opengles? ( app-misc/eglinfo )
	app-misc/tmux
	app-misc/utouch-evemu
	app-mobilephone/dfu-util
	chromeos-base/autotest-client
	cras? ( chromeos-base/audiotest )
	chromeos-base/avtest_label_detect
	chromeos-base/chrome-binary-tests
	chromeos-base/cros-camera-tool
	chromeos-base/cros-config-test
	!chromeless_tty? ( !chromeless_tests? ( chromeos-base/drm-tests ) )
	chromeos-base/factory-mini
	chromeos-base/glbench
	chromeos-base/libvda-gpu-tests
	chromeos-base/modem-diagnostics
	chromeos-base/policy_utils
	chromeos-base/protofiles
	chromeos-base/pywalt
	!chromeless_tty? ( chromeos-base/screenshot )
	chromeos-base/secure-wipe
	shill? (
		chromeos-base/shill-test-scripts
		wired_8021x? ( net-wireless/hostapd )
	)
	!chromeless_tests? ( chromeos-base/telemetry )
	chromeos-base/touchbot
	chromeos-base/toolchain-tests
	dev-embedded/dfu-programmer
	dev-libs/re2
	dev-python/protobuf-python
	dev-python/btsocket
	dev-python/contextlib2
	dev-python/dbus-python
	dev-python/dpkt
	dev-python/httplib2
	dev-python/imaging
	dev-python/jsonrpclib
	dev-python/mkvparse
	dev-python/netifaces
	dev-python/pygobject
	dev-python/pyserial
	dev-python/pytest
	dev-python/python-evdev
	dev-python/python-uinput
	dev-python/pyudev
	dev-python/pyxattr
	dev-python/pyyaml
	dev-python/selenium
	dev-python/setproctitle
	dev-python/setuptools
	dev-python/ws4py
	dev-util/stressapptest
	dev-util/trace-cmd
	games-util/joystick
	media-gfx/imagemagick[jpeg,png,svg,tiff]
	media-gfx/perceptualdiff
	media-gfx/zbar
	cheets? ( media-libs/arc-codec-test )
	arc-camera3? ( media-libs/cros-camera-libjea_test )
	arc-camera3? ( media-libs/cros-camera-test )
	media-libs/cros-camera-v4l2_test
	media-libs/libexif
	media-libs/libvpx
	media-libs/opencv
	!chromeless_tty? ( !chromeless_tests? ( media-gfx/deqp ) )
	media-libs/tiff
	opengles? ( media-libs/waffle )
	opengl? ( media-libs/waffle )
	media-sound/sox
	net-analyzer/netperf
	net-dialup/minicom
	net-dns/dnsmasq
	net-misc/dhcp
	net-misc/iperf:2
	net-misc/iputils
	net-misc/openssh
	net-misc/radvd
	wifi_hostap_test? ( net-wireless/hostap-test )
	sci-geosciences/gpsd
	sys-apps/coreutils
	sys-apps/dtc
	sys-apps/ethtool
	sys-apps/file
	sys-apps/findutils
	sys-apps/kbd
	sys-apps/shadow
	sys-devel/binutils
	sys-process/iotop
	sys-process/procps
	sys-process/psmisc
	sys-process/time
	x11-libs/libdrm
	"

################################################################################
# Assemble the final RDEPEND and DEPEND variables for portage
################################################################################
RDEPEND="${CROS_COMMON_RDEPEND}
	!cros_embedded? ( ${CROS_RDEPEND} )
"

# Packages that are only installed into the sysroot and are needed for running
# unit tests
DEPEND="
	chromeos-base/chromite
	unibuild? ( chromeos-base/chromeos-config-file-dump-test )
"
