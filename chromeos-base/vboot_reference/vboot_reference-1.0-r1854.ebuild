# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="8cb57f3498f00cf599be8acc54e272896237ec85"
CROS_WORKON_TREE="473e48ffbc02b1b0be064ebe115c3046b4112b6c"
CROS_WORKON_PROJECT="chromiumos/platform/vboot_reference"
CROS_WORKON_LOCALNAME="platform/vboot_reference"

inherit cros-debug cros-fuzzer cros-sanitizers cros-workon

DESCRIPTION="Chrome OS verified boot tools"

LICENSE="BSD-Google"
KEYWORDS="*"
IUSE="cros_host dev_debug_force fuzzer pd_sync tpmtests tpm tpm2"

REQUIRED_USE="?? ( tpm2 tpm )"

COMMON_DEPEND="dev-libs/libzip:=
	dev-libs/openssl:=
	sys-apps/util-linux:="
RDEPEND="${COMMON_DEPEND}"
DEPEND="${COMMON_DEPEND}"

get_build_dir() {
	echo "${S}/build-main"
}

src_configure() {
	cros-workon_src_configure

	# Determine sanitizer flags. This is necessary because the Makefile
	# purposely ignores CFLAGS from the environment. So we collect the
	# sanitizer flags and pass just them to the Makefile explicitly.
	SANITIZER_CFLAGS=$(
		append-flags() {
			printf "%s" "$* "
		}
		sanitizers-setup-env
	)
	if use_sanitizers; then
		# Disable alignment sanitization and memory leak checks,
		# https://crbug.com/1015908 .
		SANITIZER_CFLAGS+=" -fno-sanitize=alignment"
		export ASAN_OPTIONS+=":detect_leaks=0:"
	fi
}

vemake() {
	emake \
		SRCDIR="${S}" \
		LIBDIR="$(get_libdir)" \
		ARCH=$(tc-arch) \
		SDK_BUILD=$(usev cros_host) \
		TPM2_MODE=$(usev tpm2) \
		PD_SYNC=$(usev pd_sync) \
		DEV_DEBUG_FORCE=$(usev dev_debug_force) \
		FUZZ_FLAGS="${SANITIZER_CFLAGS}" \
		"$@"
}

src_compile() {
	mkdir "$(get_build_dir)"
	tc-export CC AR CXX PKG_CONFIG
	cros-debug-add-NDEBUG
	# vboot_reference knows the flags to use
	unset CFLAGS
	vemake BUILD="$(get_build_dir)" all $(usex fuzzer fuzzers '')
}

src_test() {
	! use amd64 && ! use x86 && ewarn "Skipping unittests for non-x86" && return 0
	vemake BUILD="$(get_build_dir)" rununittests
}

src_install() {
	einfo "Installing programs"
	vemake \
		BUILD="$(get_build_dir)" \
		DESTDIR="${D}" \
		install

	if use cros_host; then
		exeinto /usr/share/vboot/bin
		doexe scripts/image_signing/*.sh
	fi

	if use tpmtests; then
		into /usr
		# copy files starting with tpmtest, but skip .d files.
		dobin "$(get_build_dir)"/tests/tpm_lite/tpmtest*[^.]?
		dobin "$(get_build_dir)"/utility/tpm_set_readsrkpub
	fi

	# Install devkeys to /usr/share/vboot/devkeys
	# (shared by host and target)
	einfo "Installing devkeys"
	insinto /usr/share/vboot/devkeys
	doins tests/devkeys/*

	# Install public headers to /build/${BOARD}/usr/include/vboot
	einfo "Installing header files"
	insinto /usr/include/vboot
	doins host/include/* \
		firmware/include/gpt.h \
		firmware/include/tlcl.h \
		firmware/include/tss_constants.h \
		firmware/include/tpm1_tss_constants.h \
		firmware/include/tpm2_tss_constants.h

	einfo "Installing host library"
	dolib.a "$(get_build_dir)"/libvboot_host.a

	if use fuzzer; then
		einfo "Installing fuzzers"
		fuzzer_install "${S}"/OWNERS "$(get_build_dir)"/tests/cgpt_fuzzer
		fuzzer_install "${S}"/OWNERS "$(get_build_dir)"/tests/vb2_keyblock_fuzzer
		fuzzer_install "${S}"/OWNERS "$(get_build_dir)"/tests/vb2_preamble_fuzzer
	fi
}