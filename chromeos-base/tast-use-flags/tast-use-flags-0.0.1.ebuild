# Copyright 2018 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

DESCRIPTION="Text file listing USE flags for Tast test dependencies"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"

# Use flags needed for crostini_stable software dep.
# Kept separate so that they can be cleanly removed as the set of stable boards
# grows.
# TODO(crbug.com/950346): Remove this list when hwdeps are available.
CROSTINI_STABLE_USE_FLAGS="
	auron_paine
	auron_yuna
	banon
	bob
	buddy
	celes
	coral
	cyan
	edgar
	elm
	fizz
	gandof
	grunt
	hana
	kefka
	kevin64
	kevin
	kukui
	kefka
	lulu
	nocturne
	octopus
	reks
	relm
	samus
	sarien
	scarlet
	setzer
	terra
	ultima
	wizpig
"

# NB: Flags listed here are off by default unless prefixed with a '+'.
IUSE="
	amd64
	android-container-master-arc-dev
	android-container-nyc
	android-container-pi
	android-container-qt
	android-vm-pi
	arc
	arc-camera1
	arc-camera3
	arcpp
	arcvm
	arm
	arm64
	asan
	atlas
	betty
	biod
	chrome_internal
	chromeless_tty
	containers
	cr50_onboard
	crosvm-gpu
	cups
	diagnostics
	disable_cros_video_decoder
	elm-kernelnext
	+display_backlight
	dlc_test
	+drivefs
	drm_atomic
	fizz
	force_breakpad
	force_crashpad
	grunt
	hana-kernelnext
	internal
	+internal_mic
	+internal_speaker
	iwlwifi_rescan
	kernel-3_8
	kernel-3_10
	kernel-3_14
	kernel-3_18
	kernel-4_4
	kernel-4_14
	kernel-4_19
	kernel-5_4
	kukui
	kvm_host
	kvm_transition
	lxc
	memd
	ml_service
	moblab
	mocktpm
	msan
	nyan_kitty
	octopus
	pita
	rialto
	rk3399
	selinux
	selinux_experimental
	skate
	smartdim
	snow
	spring
	+storage_wearout_detect
	touchview
	tpm2
	transparent_hugepage
	ubsan
	unibuild
	usbguard
	vaapi
	veyron_mickey
	veyron_rialto
	vulkan
	watchdog
	wifi_hostap_test
	wilco
	+wired_8021x
	${CROSTINI_STABLE_USE_FLAGS}
"

S=${WORKDIR}

src_install() {
	# Install a file containing a list of currently-set USE flags.
	local path="${WORKDIR}/tast_use_flags.txt"
	cat <<EOF >"${path}"
# This file is used by the Tast integration testing system to
# determine which software features are present in the system image.
# Don't use it for anything else. Your code will break.
EOF

	# If you need to inspect a new flag, add it to $IUSE at the top of the file.
	local flags=( ${IUSE} )
	local flag
	for flag in ${flags[@]/#[-+]} ; do
		usev ${flag}
	done | sort -u >>"${path}"

	insinto /etc
	doins "${path}"
}
