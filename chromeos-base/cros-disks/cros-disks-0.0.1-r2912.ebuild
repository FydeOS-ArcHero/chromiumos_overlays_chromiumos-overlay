# Copyright 2014 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_COMMIT="274ceb94bed71121b05943af1c65f75680fc2ef8"
CROS_WORKON_TREE=("33378ea9ec0ce2140519976d43d90cb944b86813" "f099d4930bbddeb21c471039c09ec951eca1f858" "11cf580b60e9b5b8fdc05216e8ff2e2f29622168" "e7dba8c91c1f3257c34d4a7ffff0ea2537aeb6bb")
CROS_WORKON_INCREMENTAL_BUILD="1"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
# TODO(crbug.com/809389): Avoid directly including headers from other packages.
CROS_WORKON_SUBTREE="common-mk cros-disks metrics .gn"

PLATFORM_SUBDIR="cros-disks"

inherit cros-workon platform user

DESCRIPTION="Disk mounting daemon for Chromium OS"
HOMEPAGE="http://www.chromium.org/"
LICENSE="BSD-Google"
KEYWORDS="*"
IUSE="chromeless_tty fuzzer +seccomp"

COMMON_DEPEND="
	chromeos-base/metrics:=
	chromeos-base/minijail:=
	chromeos-base/session_manager-client:=
	sys-apps/rootdev:=
	sys-apps/util-linux:=
"

RDEPEND="
	${COMMON_DEPEND}
	app-arch/unrar
	net-fs/sshfs
	sys-fs/avfs
	sys-fs/dosfstools
	sys-fs/exfat-utils
	sys-fs/fuse-exfat
	sys-fs/ntfs3g
	sys-fs/rar2fs
	virtual/udev
"

DEPEND="
	${COMMON_DEPEND}
	chromeos-base/system_api:=[fuzzer?]
"

pkg_preinst() {
	enewuser "cros-disks"
	enewgroup "cros-disks"

	enewuser "ntfs-3g"
	enewgroup "ntfs-3g"

	enewuser "avfs"
	enewgroup "avfs"

	enewuser "fuse-exfat"
	enewgroup "fuse-exfat"

	enewuser "fuse-rar2fs"
	enewgroup "fuse-rar2fs"

	enewuser "fuse-sshfs"
	enewgroup "fuse-sshfs"

	enewuser "fuse-drivefs"
	enewgroup "fuse-drivefs"
}

src_install() {
	dobin "${OUT}"/cros-disks

	# Install USB device IDs file.
	insinto /usr/share/cros-disks
	doins usb-device-info

	# Install seccomp policy file.
	insinto /usr/share/policy
	use seccomp && newins avfsd-seccomp-${ARCH}.policy avfsd-seccomp.policy

	# Install upstart config file.
	insinto /etc/init
	doins cros-disks.conf
	# Insert the --no-session-manager flag if needed.
	if use chromeless_tty; then
		sed -i -E "s/(CROS_DISKS_OPTS=')/\1--no_session_manager /" "${D}"/etc/init/cros-disks.conf || die
	fi

	# Install D-Bus config file.
	insinto /etc/dbus-1/system.d
	doins org.chromium.CrosDisks.conf

	# Install setuid restrictions file.
	insinto /usr/share/cros/startup/process_management_policies
	doins setuid_restrictions/cros_disks_whitelist.txt

	local fuzzers=(
		mount_options_fuzzer
		filesystem_label_fuzzer
	)

	local fuzzer
	for fuzzer in "${fuzzers[@]}"; do
		platform_fuzzer_install "${S}"/OWNERS "${OUT}/${PN}_${fuzzer}"
	done
}

platform_pkg_test() {
	local gtest_filter_qemu_common=""
	gtest_filter_qemu_common+="DiskManagerTest.*"
	gtest_filter_qemu_common+=":ExternalMounterTest.*"
	gtest_filter_qemu_common+=":UdevDeviceTest.*"
	gtest_filter_qemu_common+=":MountInfoTest.RetrieveFromCurrentProcess"
	gtest_filter_qemu_common+=":GlibProcessTest.*"

	local gtest_filter_user_tests="-*RunAsRoot*:"
	! use x86 && ! use amd64 && gtest_filter_user_tests+="${gtest_filter_qemu_common}"

	local gtest_filter_root_tests="*RunAsRoot*-"
	! use x86 && ! use amd64 && gtest_filter_root_tests+="${gtest_filter_qemu_common}"

	platform_test "run" "${OUT}/disks_testrunner" "1" \
		"${gtest_filter_root_tests}"
	platform_test "run" "${OUT}/disks_testrunner" "0" \
		"${gtest_filter_user_tests}"
}