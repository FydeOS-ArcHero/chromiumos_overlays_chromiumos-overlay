# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

#
# Original Author: The Chromium OS Authors <chromium-os-dev@chromium.org>
# Purpose: Library for handling building of ChromiumOS packages
#
#
#  This class provides an easy way to retrieve the BOARD variable.
#  It is intended to be used by ebuild packages that need to have the
#  board information for various reasons -- for example, to differentiate
#  various hardware attributes at build time.
#
#  If an unknown board is encountered and no default is provided, or multiple
#  boards are defined, this class deliberately fails the build.
#  This provides an easy method of identifying a change to
#  the build which might affect inheriting packages.

# Check for EAPI 4+
case "${EAPI:-0}" in
4|5|6|7) ;;
*) die "unsupported EAPI (${EAPI}) in eclass (${ECLASS})" ;;
esac

BOARD_USE_PREFIX="board_use_"

# Obsolete boards' names are commented-out but retained in this list so
# they won't be accidentally recycled in the future.
ALL_BOARDS=(
	acorn
	amd64-corei7
	#amd64-drm
	amd64-generic
	amd64-generic-cheets
	amd64-generic-goofy
	amd64-generic_embedded
	amd64-anbox-generic
	#amd64-generic_freon
	#amd64-generic_mobbuild
	amd64-host
	#anglar
	aplrvp
	#app-shell-panther
	aries
	arkham
	arm-generic
	#arm-generic_freon
	arm64-generic
	arm64-llvmpipe
	asuka
	asurada
	atlas
	atlas-blueznext
	atlas-kvm
	auron
	auron_paine
	auron_pearlvalley
	auron_yuna
	banjo
	banon
	bayleybay
	beaglebone
	beaglebone_servo
	beaglebone_vv1
	beltino
	betty
	betty-arc64
	betty-arcmaster
	betty-arcnext
	betty-arcvm-master
	betty-arcvm-pi
	betty-nyc-arc
	betty-pi-arc
	betty-qt-arc
	#bettyvirgl
	blackwall
	bob
	bobcat
	bolt
	borealis
	bruteus
	bubs
	buddy
	buddy-cfm
	#buranku
	butterfly
	bwtm2
	#bxt-rvp
	candy
	capri
	capri-zfpga
	caroline
	caroline-arc64
	#caroline-arcnext
	#caroline-bertha
	caroline-kernelnext
	caroline-ndktranslation
	caroline-userdebug
	cardhu
	cave
	celes
	celes-cheets
	chell
	chell-cheets
	cheza
	cheza-freedreno
	cheza64
	cheza64-freedreno
	#chronos
	cid
	clapper
	cmlrvp
	#cnlrvp
	cobblepot
	coral
	cosmos
	cranky
	cyan
	cyan-cheets
	cyan-kernelnext
	cyclone
	daisy
	#daisy-drm
	daisy_embedded
	daisy_skate
	daisy_snow
	daisy_spring
	daisy_winter
	dalmore
	danger
	danger_embedded
	dedede
	deltaur
	#derwent
	#dragonegg
	drallion
	duck
	edgar
	elm
	elm-cheets
	elm-kernelnext
	#emeraldlake2
	endeavour
	enguarde
	#envoy-jerry
	eve
	eve-arcdual
	eve-arcnext
	eve-arc-r
	eve-arcvm
	eve-arcvm-mesa-virgl-next
	eve-arm64
	#eve-bertha
	eve-campfire
	eve-kvm
	eve-lacros
	eve-manatee
	eve-swap
	eve-userdebug
	excelsior
	expresso
	falco
	falco_gles
	falco_li
	fb1
	fizz
	fizz-accelerator
	fizz-cfm
	fizz-labstation
	fizz-moblab
	flapjack
	foster
	#fox
	#fox_baskingridge
	#fox_wtm1
	#fox_wtm2
	gale
	gandof
	#gizmo
	glados
	glados-cheets
	glimmer
	glimmer-cheets
	glkrvp
	gnawty
	gonzo
	gru
	grunt
	grunt-kernelnext
	guado
	guado-accelerator
	guado-cfm
	guado-macrophage
	guado_moblab
	guado-kernelnext
	guado_labstation
	hana
	hana-kernelnext
	hatch
	hatch-arc-r
	hatch-diskswap
	hatch-kernelnext
	heli
	hsb
	#iclrvp
	ironhide
	jacuzzi
	#jadeite
	#jaguar
	jecht
	#kahlee
	kalista
	kalista-cfm
	kayle
	kblrvp
	kefka
	kefka-kernelnext
	#kennet
	kevin
	kevin64
	#kevin-arcnext
	kevin-arc64
	#kevin-bertha
	kevin-tpm2
	kidd
	#kiev
	kip
	klang
	kukui
	kukui-arc-r
	kumo
	kunimitsu
	lakitu
	lakitu-gpu
	#lakitu_mobbuild
	lakitu-nc
	lakitu_next
	lakitu-slice
	lakitu-st
	lars
	laser
	lasilla-ground
	#lasilla-sky
	lassen
	#lemmings
	#lemmings_external
	leon
	link
	littlejoe
	loonix
	lulu
	lulu-cheets
	lumpy
	#macchiato-ground
	mappy
	#mappy-envoy
	mappy_flashstation
	marble
	mccloud
	#meowth
	metis
	minnowboard
	mipseb-n32-generic
	mipseb-n64-generic
	mipseb-o32-generic
	mipsel-n32-generic
	mipsel-n64-generic
	mipsel-o32-generic
	mistral
	moblab-generic-vm
	monroe
	moose
	mushu
	nami
	nami-kvm
	nautilus
	#nefario
	#newbie
	ninja
	nocturne
	novato
	novato-arc64
	novato-arcnext
	nyan
	nyan_big
	nyan_blaze
	#nyan_blaze-freon
	#nyan_freon
	nyan_kitty
	oak
	oak-cheets
	octavius
	octopus
	#optimus
	orchestra
	orco
	palkia
	panda
	panther
	panther_embedded
	panther_goofy
	panther_moblab
	parrot
	parrot32
	parrot64
	parrot_ivb
	#parry
	#pbody
	peach
	peach_kirby
	peach_pi
	peach_pit
	#pedra
	peppy
	plaso
	poppy
	ppcbe-32-generic
	ppcbe-64-generic
	ppcle-32-generic
	ppcle-64-generic
	puff
	puppy
	purin
	pyro
	quawks
	rainier
	rambi
	rammus
	raspberrypi
	reef
	relm
	reks
	#reptile
	#ricochet
	rikku
	rikku-cfm
	rizer
	romer
	rotor
	rowan
	rush
	rush_ryu
	sama5d3
	samus
	samus-cheets
	samus-kernelnext
	sand
	sarien
	sarien-kvm
	scarlet
	scarlet-arcnext
	sentry
	setzer
	shogun
	sklrvp
	#slippy
	smaug
	smaug-cheets
	smaug-kasan
	snappy
	sonic
	soraka
	#space
	squawks
	stelvio
	storm
	storm_nand
	stout
	#stout32
	strago
	stumpy
	stumpy_moblab
	stumpy_pico
	sumo
	swanky
	tails
	tatl
	tael
	#tegra2
	#tegra2_aebl
	#tegra2_arthur
	#tegra2_asymptote
	#tegra2_dev-board
	#tegra2_dev-board-opengl
	#tegra2_kaen
	#tegra2_seaboard
	#tegra2_wario
	tegra3-generic
	terra
	tglrvp
	tidus
	tricky
	trogdor
	ultima
	umaro
	#urara
	veyron
	veyron_fievel
	veyron_gus
	veyron_jaq
	veyron_jerry
	#veyron_jerry-kernelnext
	veyron_mickey
	veyron_mighty
	veyron_minnie
	veyron_minnie-cheets
	#veyron_minnie-kernelnext
	veyron_nicky
	veyron_pinky
	veyron_remy
	veyron_rialto
	veyron_shark
	veyron_speedy
	veyron_speedy-cheets
	veyron_thea
	veyron_tiger
	viking
	viking-poc2
	volteer
	#waluigi
	whirlwind
	whlrvp
	winky
	wizpig
	wolf
	wooten
	wristpin
	wsb
	x30evb
	x32-generic
	x86-agz
	x86-alex
	x86-alex32
	x86-alex32_he
	x86-alex_he
	x86-alex_hubble
	x86-dogfood
	#x86-drm
	#x86-fruitloop
	x86-generic
	x86-generic_embedded
	#x86-generic_freon
	x86-mario
	x86-mario64
	#x86-pineview
	#x86-wayland
	x86-zgb
	x86-zgb32
	x86-zgb32_he
	x86-zgb_he
	zako
	zoombini
	zork
)

# Use the CROS_BOARDS defined by ebuild, otherwise use ALL_BOARDS.
if [[ ${#CROS_BOARDS[@]} -eq 0 ]]; then
	CROS_BOARDS=( "${ALL_BOARDS[@]}" )
fi

# Add BOARD_USE_PREFIX to each board in ALL_BOARDS to create IUSE.
# Also add cros_host so that we can inherit this eclass in ebuilds
# that get emerged both in the cros-sdk and for target boards.
# See REQUIRED_USE below.
IUSE="${CROS_BOARDS[@]/#/${BOARD_USE_PREFIX}} cros_host unibuild"

# Echo the current board, with variant. The arguments are:
#   1: default, the value to return when no board is found; default: ""
get_current_board_with_variant()
{
	[[ $# -gt 1 ]] && die "Usage: ${FUNCNAME} [default]"

	local b
	local current
	local default_board="$1"

	for b in "${CROS_BOARDS[@]}"; do
		if use ${BOARD_USE_PREFIX}${b}; then
			if [[ -n "${current}" ]]; then
				die "More than one board is set: ${current} and ${b}"
			fi
			current="${b}"
		fi
	done

	if [[ -n "${current}" ]]; then
		echo ${current}
		return
	fi

	echo "${default_board}"
}

# Echo the current board, without variant.
get_current_board_no_variant()
{
	get_current_board_with_variant "$@" | cut -d '_' -f 1
}
