# Copyright 2014 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

#
# Original Author: The Chromium OS Authors <chromium-os-dev@chromium.org>
# Purpose: Library for handling building of ChromiumOS packages
#
#

# @ECLASS-VARIABLE: EC_BOARDS
# @DESCRIPTION:
#  This class contains function that lists the name of embedded
#  controllers for a given system.
#  When found, the array EC_BOARDS is populated.
#  It no ECs are known or build host tools, bds toolchain is defined.
#  For example, for a falco machine, EC_BOARDS = [ "falco" ]
#  For samus, EC_BOARDS = [ "samus", "samus_pd" ]
#
#  The firmware for these ECs can be found in platform/ec/build
#  When not using unibuild, the first item of the array is always the main ec.

# Check for EAPI 4+
case "${EAPI:-0}" in
4|5|6|7) ;;
*) die "unsupported EAPI (${EAPI}) in eclass (${ECLASS})" ;;
esac

inherit cros-unibuild

# For unibuild we need EAPI 5 for the sub-slot dependency feature.
case "${EAPI:-0}" in
5|6|7)
	DEPEND+="
		unibuild? (
			!generated_cros_config? ( chromeos-base/chromeos-config )
			generated_cros_config? ( chromeos-base/chromeos-config-bsp:= )
		)"
	;;
esac

EC_BOARD_USE_PREFIX="ec_firmware_"
EC_EXTRA_BOARD_USE_PREFIX="ec_firmware_extra_"

# EC firmware board names for overlay with special configuration
EC_BOARD_NAMES=(
	asurada
	atlas
	atlas_ish
	bds
	cheza
	coral
	cr50
	cyan
	dedede
	dingdong
	dragonegg
	elm
	endeavour
	eve
	eve_fp
	fizz
	flapjack
	glkrvp
	grunt
	hadoken
	hammer
	hatch
	hatch_fp
	hoho
	jacuzzi
	jerry
	kalista
	kukui
	llama
	lux
	meowth
	meowth_fp
	minimuffin
	mushu
	nami
	nami_fp
	nautilus
	nefario
	nocturne
	nocturne_fp
	oak
	oak_pd
	octopus
	orchestra
	palkia
	plankton
	poppy
	rammus
	reef
	ryu
	ryu_p4p5
	ryu_sh
	ryu_sh_loader
	samus
	samus_pd
	scarlet
	soraka
	staff
	strago
	trogdor
	twinkie
	wand
	whiskers
	zinger
	zoombini
	zork
)

IUSE_FIRMWARES="${EC_BOARD_NAMES[@]/#/${EC_BOARD_USE_PREFIX}}"
IUSE_EXTRA_FIRMWARES="${EC_BOARD_NAMES[@]/#/${EC_EXTRA_BOARD_USE_PREFIX}}"
IUSE="${IUSE_FIRMWARES} ${IUSE_EXTRA_FIRMWARES} cros_host unibuild generated_cros_config"


# Echo the current boards
get_ec_boards()
{
	EC_BOARDS=()
	if use cros_host; then
		# If we are building for the purpose of emitting host-side tools, assume
		# EC_BOARDS=(bds) for the build.
		EC_BOARDS=(bds)
		return
	fi

	# Add board names requested by ec_firmware_* USE flags
	local ec_board
	if use unibuild; then
		EC_BOARDS+=($(cros_config_host get-firmware-build-targets ec))
		EC_BOARDS+=($(cros_config_host get-firmware-build-targets ish))
	else
		for ec_board in ${IUSE_FIRMWARES}; do
			use ${ec_board} && EC_BOARDS+=(${ec_board#${EC_BOARD_USE_PREFIX}})
		done
		for ec_board in ${IUSE_EXTRA_FIRMWARES}; do
			use ${ec_board} && EC_BOARDS+=(${ec_board#${EC_EXTRA_BOARD_USE_PREFIX}})
		done
	fi

	# Allow building for boards that don't have an EC
	# (so we can compile test on bots for testing).
	if [[ ${#EC_BOARDS[@]} -eq 0 ]]; then
		EC_BOARDS=(bds)
	fi
	einfo "Building for boards: ${EC_BOARDS[*]}"
}
