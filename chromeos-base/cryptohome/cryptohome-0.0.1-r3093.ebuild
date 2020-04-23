# Copyright 2014 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="32ccb40ef5c831be8ce6f04617df7c44ef2bf672"
CROS_WORKON_TREE=("dea48af07754556aac092c0830de0b1ab410077b" "0cd1fadf03b2a18784f71c65856d3e8f1c3cf6db" "d33af452545894a4015d3e685ef122cea924019c" "a6d4fca3db878377b5ababec63bde6714fa580dc" "e7dba8c91c1f3257c34d4a7ffff0ea2537aeb6bb")
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_DESTDIR="${S}/platform2"
CROS_WORKON_INCREMENTAL_BUILD=1
# TODO(crbug.com/809389): Avoid directly including headers from other packages.
CROS_WORKON_SUBTREE="common-mk cryptohome libhwsec secure_erase_file .gn"

PLATFORM_NATIVE_TEST="yes"
PLATFORM_SUBDIR="cryptohome"

inherit cros-workon platform systemd udev user

DESCRIPTION="Encrypted home directories for Chromium OS"
HOMEPAGE="http://www.chromium.org/"
SRC_URI=""

LICENSE="BSD-Google"
SLOT="0/0"
KEYWORDS="*"
# The flag distributed_cryptohome is for turning on tpm_manager and
# attestation for 1.2 devices.
IUSE="-cert_provision cryptohome_userdataauth_interface +device_mapper
	-direncryption distributed_cryptohome double_extend_pcr_issue fuzzer
	pinweaver selinux systemd test tpm tpm2 user_session_isolation"

REQUIRED_USE="
	device_mapper
	tpm2? ( !tpm )
"

COMMON_DEPEND="
	!chromeos-base/chromeos-cryptohome
	tpm? (
		app-crypt/trousers:=
	)
	tpm2? (
		chromeos-base/trunks:=
	)
	selinux? (
		sys-libs/libselinux:=
	)
	chromeos-base/attestation:=
	chromeos-base/chaps:=
	chromeos-base/libhwsec:=
	chromeos-base/libscrypt:=
	chromeos-base/metrics:=
	chromeos-base/secure-erase-file:=
	chromeos-base/tpm_manager:=
	dev-libs/dbus-glib:=
	dev-libs/glib:=
	dev-libs/openssl:=
	dev-libs/protobuf:=
	sys-apps/keyutils:=
	sys-fs/e2fsprogs:=
	sys-fs/ecryptfs-utils:=
	sys-fs/lvm2:=
"

RDEPEND="${COMMON_DEPEND}"
DEPEND="${COMMON_DEPEND}
	tpm2? ( chromeos-base/trunks:=[test?] )
	chromeos-base/attestation-client:=
	chromeos-base/bootlockbox-client:=
	chromeos-base/cryptohome-client:=
	chromeos-base/protofiles:=
	chromeos-base/system_api:=[fuzzer?]
	chromeos-base/tpm_manager-client:=
	chromeos-base/vboot_reference:=
	chromeos-base/libhwsec:=
"

src_install() {
	pushd "${OUT}" >/dev/null
	dosbin cryptohomed cryptohome cryptohome-proxy cryptohome-path homedirs_initializer \
		lockbox-cache tpm-manager
	dosbin cryptohome-namespace-mounter
	dosbin mount-encrypted
	if use tpm2; then
		dosbin bootlockboxd bootlockboxtool
	fi
	if use cert_provision; then
		dolib.so lib/libcert_provision.so
		dosbin cert_provision_client
	fi
	popd >/dev/null

	insinto /etc/dbus-1/system.d
	doins etc/Cryptohome.conf
	doins etc/org.chromium.UserDataAuth.conf
	if use tpm2; then
		doins etc/BootLockbox.conf
	fi

	# Install init scripts
	if use systemd; then
		if use tpm2; then
			sed 's/tcsd.service/attestationd.service/' \
				init/cryptohomed.service \
				> "${T}/cryptohomed.service"
			systemd_dounit "${T}/cryptohomed.service"
		else
			systemd_dounit init/cryptohomed.service
		fi
		systemd_dounit init/mount-encrypted.service
		systemd_dounit init/lockbox-cache.service
		systemd_enable_service boot-services.target cryptohomed.service
		systemd_enable_service system-services.target mount-encrypted.service
		systemd_enable_service ui.target lockbox-cache.service
	else
		insinto /etc/init
		doins init/*.conf
		if use tpm2; then
			sed -i 's/started tcsd/started attestationd/' \
				"${D}/etc/init/cryptohomed.conf" ||
				die "Can't replace tcsd with attestationd in cryptohomed.conf"
			insinto /usr/share/policy
			newins bootlockbox/seccomp/bootlockboxd-seccomp-${ARCH}.policy \
				bootlockboxd-seccomp.policy
			insinto /etc/init
			doins bootlockbox/bootlockboxd.conf
		fi
		if use direncryption; then
			sed -i '/env DIRENCRYPTION_FLAG=/s:=.*:="--direncryption":' \
				"${D}/etc/init/cryptohomed.conf" ||
				die "Can't replace direncryption flag in cryptohomed.conf"
		fi
		if use distributed_cryptohome; then
			sed -i 's/started tcsd/started attestationd/' \
				"${D}/etc/init/cryptohomed.conf" ||
				die "Can't replace tcsd with attestationd in cryptohomed.conf"
			sed -i '/env DISTRIBUTED_MODE_FLAG=/s:=.*:="--attestation_mode=dbus":' \
				"${D}/etc/init/cryptohomed.conf" ||
				die "Can't activate distributed mode in cryptohomed.conf"
		fi
	fi
	exeinto /usr/share/cros/init
	doexe init/lockbox-cache.sh
	if use cert_provision; then
		insinto /usr/include/cryptohome
		doins cert_provision.h
	fi

	# Install the configuration file and utility for detecting if the new
	# (UserDataAuth) or old interface is used.
	insinto /etc/
	doins cryptohome_userdataauth_interface.conf
	exeinto /usr/libexec/cryptohome
	doexe shall-use-userdataauth.sh

	platform_fuzzer_install "${S}"/OWNERS \
		"${OUT}"/cryptohome_cryptolib_rsa_oaep_decrypt_fuzzer \
		fuzzers/data/*

	platform_fuzzer_install "${S}"/OWNERS \
		"${OUT}"/cryptohome_cryptolib_blob_to_hex_fuzzer
}

pkg_preinst() {
	enewuser "bootlockboxd"
	enewgroup "bootlockboxd"
}

platform_pkg_test() {
	platform_test "run" "${OUT}/cryptohome_testrunner"
	platform_test "run" "${OUT}/mount_encrypted_unittests"
	if use tpm2; then
		platform_test "run" "${OUT}/boot_lockbox_unittests"
	fi
}
