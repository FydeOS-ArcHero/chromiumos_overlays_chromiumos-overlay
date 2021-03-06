# Copyright 2018 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

DESCRIPTION="List of packages that should be fuzzed"
HOMEPAGE="http://dev.chromium.org/"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE="asan msan"

RDEPEND="
	chromeos-base/arc-adbd[fuzzer]
	asan? ( chromeos-base/arc-keymaster[fuzzer] )
	chromeos-base/arc-networkd[fuzzer]
	chromeos-base/arc-obb-mounter[fuzzer]
	chromeos-base/arc-setup[fuzzer]
	chromeos-base/authpolicy[fuzzer]
	chromeos-base/biod[fuzzer]
	chromeos-base/bluetooth[fuzzer]
	chromeos-base/chaps[fuzzer]
	chromeos-base/chromeos-ec[fuzzer]
	chromeos-base/chromeos-login[fuzzer]
	chromeos-base/crash-reporter[fuzzer]
	chromeos-base/cros-disks[fuzzer]
	chromeos-base/crosdns[fuzzer]
	chromeos-base/cryptohome[fuzzer]
	chromeos-base/cups-fuzz[fuzzer]
	chromeos-base/diagnostics[fuzzer]
	chromeos-base/dlcservice[fuzzer]
	chromeos-base/ghostscript-fuzz[fuzzer]
	chromeos-base/hammerd[fuzzer]
	chromeos-base/imageloader[fuzzer]
	chromeos-base/ippusb_manager[fuzzer]
	chromeos-base/kerberos[fuzzer]
	chromeos-base/libbrillo[fuzzer]
	chromeos-base/libipp[fuzzer]
	asan? ( chromeos-base/libvda[fuzzer] )
	chromeos-base/metrics[fuzzer]
	chromeos-base/ml[fuzzer]
	chromeos-base/modemfwd[fuzzer]
	chromeos-base/p2p[fuzzer]
	chromeos-base/permission_broker[fuzzer]
	chromeos-base/power_manager[fuzzer]
	chromeos-base/runtime_probe[fuzzer]
	chromeos-base/shill[fuzzer]
	chromeos-base/smbprovider[fuzzer]
	chromeos-base/trunks[fuzzer]
	chromeos-base/u2fd[fuzzer]
	chromeos-base/update_engine[fuzzer]
	chromeos-base/usb_bouncer[fuzzer]
	chromeos-base/vboot_reference[fuzzer]
	chromeos-base/vm_guest_tools[fuzzer]
	chromeos-base/vpn-manager[fuzzer]
	asan? ( chromeos-base/vm_host_tools[fuzzer] )
	dev-libs/modp_b64[fuzzer]
	asan? ( dev-rust/p9[fuzzer] )
	dev-util/bsdiff[fuzzer]
	dev-util/puffin[fuzzer]
	media-libs/virglrenderer[fuzzer]
	media-sound/adhd[fuzzer]
	net-dns/avahi[fuzzer]
"
