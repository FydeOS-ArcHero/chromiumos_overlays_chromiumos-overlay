# Copyright (c) 2014 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

# Change this version number when any change is made to configs/files under
# coreboot and an auto-revbump is required.
# VERSION=REVBUMP-0.0.3

EAPI=4
CROS_WORKON_PROJECT=(
	"chromiumos/third_party/coreboot"
	"chromiumos/third_party/arm-trusted-firmware"
	"chromiumos/platform/vboot_reference"
	"chromiumos/third_party/coreboot/blobs"
	"chromiumos/third_party/cbootimage"
)
CROS_WORKON_LOCALNAME=(
	"coreboot"
	"arm-trusted-firmware"
	"../platform/vboot_reference"
	"coreboot/3rdparty/blobs"
	"cbootimage"
)
CROS_WORKON_DESTDIR=(
	"${S}"
	"${S}/3rdparty/arm-trusted-firmware"
	"${S}/3rdparty/vboot"
	"${S}/3rdparty/blobs"
	"${S}/util/nvidia/cbootimage"
)

inherit cros-board cros-workon toolchain-funcs

DESCRIPTION="coreboot firmware"
HOMEPAGE="http://www.coreboot.org"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~*"
IUSE="em100-mode fastboot fsp memmaps mocktpm quiet-cb rmt vmx mtc mma"
IUSE="${IUSE} +bmpblk cros_ec pd_sync qca-framework quiet verbose"

PER_BOARD_BOARDS=(
	bayleybay beltino bolt butterfly chell cyan daisy eve falco fox gizmo glados
	kunimitsu link lumpy nyan panther parrot peppy poppy rambi samus sklrvp
	slippy stout stout32 strago stumpy urara variant-peach-pit
)

DEPEND_BLOCKERS="${PER_BOARD_BOARDS[@]/#/!sys-boot/chromeos-coreboot-}"

RDEPEND="
	${DEPEND_BLOCKERS}
	!virtual/chromeos-coreboot
	"

# Dependency shared by x86 and amd64.
DEPEND_X86="
	sys-power/iasl
	sys-boot/chromeos-mrc
	"
DEPEND="
	mtc? ( sys-boot/mtc )
	chromeos-base/vboot_reference
	${DEPEND_BLOCKERS}
	virtual/coreboot-private-files
	sys-apps/coreboot-utils
	bmpblk? ( sys-boot/chromeos-bmpblk )
	cros_ec? ( chromeos-base/chromeos-ec )
	pd_sync? ( chromeos-base/chromeos-ec )
	x86? ($DEPEND_X86)
	amd64? ($DEPEND_X86)
	qca-framework? ( sys-boot/qca-framework )
	"

# Get the coreboot board config to build for.
# Checks the current board with/without variant, and also whether an FSP
# is in use. Echoes the board config file that should be used to build
# coreboot.
get_board() {
	local board=$(get_current_board_with_variant)

	if [[ ! -s "${FILESDIR}/configs/config.${board}" ]]; then
		board=$(get_current_board_no_variant)
	fi
	if use fsp; then
		if [[ -s "${FILESDIR}/configs/config.${board}.fsp" ]]; then
			elog "   - using fsp config"
			board=${board}.fsp
		fi
	fi
	echo "${board}"
}

set_build_env() {
	BOARD="$1"

	CONFIG=".config"
	CONFIG_SERIAL=".config_serial"
	BUILD_DIR="build"
	BUILD_DIR_SERIAL="build_serial"
}

# Create the coreboot configuration files for a particular board. This
# creates a standard config and a serial config.
# Args:
#    $1: Name of board to create a configure file for (e.g. "reef")
create_config() {
	set_build_env "$1"

	if [[ -s "${FILESDIR}/configs/config.${BOARD}" ]]; then

		cp -v "${FILESDIR}/configs/config.${BOARD}" "${CONFIG}"

		# Override mainboard vendor if needed.
		if [[ -n "${SYSTEM_OEM}" ]]; then
			echo "CONFIG_MAINBOARD_VENDOR=\"${SYSTEM_OEM}\"" >> "${CONFIG}"
		fi

		# In case config comes from a symlink we are likely building
		# for an overlay not matching this config name. Enable adding
		# a CBFS based board ID for coreboot.
		if [[ -L "${FILESDIR}/configs/config.${BOARD}" ]]; then
			echo "CONFIG_BOARD_ID_MANUAL=y" >> "${CONFIG}"
			echo "CONFIG_BOARD_ID_STRING=\"${BOARD_USE}\"" >> "${CONFIG}"
		fi
	fi

	if use rmt; then
		echo "CONFIG_MRC_RMT=y" >> "${CONFIG}"
	fi
	if use vmx; then
		elog "   - enabling VMX"
		echo "CONFIG_ENABLE_VMX=y" >> "${CONFIG}"
	fi
	if use quiet-cb; then
		# Suppress console spew if requested.
		cat >> "${CONFIG}" <<EOF
CONFIG_DEFAULT_CONSOLE_LOGLEVEL=3
# CONFIG_DEFAULT_CONSOLE_LOGLEVEL_8 is not set
CONFIG_DEFAULT_CONSOLE_LOGLEVEL_3=y
EOF
	fi
	if use mocktpm; then
		echo "CONFIG_VBOOT_MOCK_SECDATA=y" >> "${CONFIG}"
	fi
	if use mma; then
		echo "CONFIG_MMA=y" >> "${CONFIG}"
	fi

	# disable coreboot's own EC firmware building mechanism
	echo "CONFIG_EC_GOOGLE_CHROMEEC_FIRMWARE_NONE=y" >> "${CONFIG}"
	echo "CONFIG_EC_GOOGLE_CHROMEEC_PD_FIRMWARE_NONE=y" >> "${CONFIG}"
	# enable common GBB flags for development
	echo "CONFIG_GBB_FLAG_DEV_SCREEN_SHORT_DELAY=y" >> "${CONFIG}"
	echo "CONFIG_GBB_FLAG_DISABLE_FW_ROLLBACK_CHECK=y" >> "${CONFIG}"
	echo "CONFIG_GBB_FLAG_FORCE_DEV_BOOT_USB=y" >> "${CONFIG}"
	echo "CONFIG_GBB_FLAG_FORCE_DEV_SWITCH_ON=y" >> "${CONFIG}"
	if use fastboot; then
		echo "CONFIG_GBB_FLAG_FORCE_DEV_BOOT_FASTBOOT_FULL_CAP=y" >> "${CONFIG}"
	fi
	local version=$(${CHROOT_SOURCE_ROOT}/src/third_party/chromiumos-overlay/chromeos/config/chromeos_version.sh |grep "^[[:space:]]*CHROMEOS_VERSION_STRING=" |cut -d= -f2)
	echo "CONFIG_CHROMEOS_FWID_VERSION=\".${version}\"" >> "${CONFIG}"

	cp "${CONFIG}" "${CONFIG_SERIAL}"
	# handle the case when "${CONFIG}" does not have a newline in the end.
	echo >> "${CONFIG_SERIAL}"
	file="${FILESDIR}/configs/fwserial.${BOARD}"
	if [ ! -f "${file}" ]; then
		file="${FILESDIR}/configs/fwserial.default"
	fi
	cat "${file}" >> "${CONFIG_SERIAL}" || die
	echo "CONFIG_GBB_FLAG_ENABLE_SERIAL=y" >> "${CONFIG_SERIAL}"

	einfo "Configured ${CONFIG} for board ${BOARD} in ${BUILD_DIR}"
}

src_prepare() {
	local froot="${SYSROOT}/firmware"
	local privdir="${SYSROOT}/firmware/coreboot-private"
	local file

	if [[ -d "${privdir}" ]]; then
		while read -d $'\0' -r file; do
			rsync --recursive --links --executability \
				"${file}" ./ || die
		done < <(find "${privdir}" -maxdepth 1 -mindepth 1 -print0)
	fi

	for blob in mrc.bin mrc.elf efi.elf; do
		if [[ -r "${SYSROOT}/firmware/${blob}" ]]; then
			cp "${SYSROOT}/firmware/${blob}" 3rdparty/blobs/
		fi
	done

	create_config "$(get_board)"
}

add_ec() {
	local rom="$1"
	local name="$2"
	local ecroot="$3"

	cbfstool "${rom}" add -r FW_MAIN_A,FW_MAIN_B -t raw -c lzma \
		 -f "${ecroot}/ec.RW.bin" -n "${name}" || die
	cbfstool "${rom}" add -r FW_MAIN_A,FW_MAIN_B -t raw -c none \
		 -f "${ecroot}/ec.RW.hash" -n "${name}.hash" || die
}

make_coreboot() {
	local builddir="$1"
	local froot="${SYSROOT}/firmware"

	rm -rf "${builddir}" .xcompile

	local CB_OPTS=( "objutil=objutil" )
	use quiet && CB_OPTS+=( "V=0" )
	use verbose && CB_OPTS+=( "V=1" )
	use quiet && REDIR="/dev/null" || REDIR="/dev/stdout"

	yes "" | emake oldconfig "${CB_OPTS[@]}" obj="${builddir}" >${REDIR}
	emake "${CB_OPTS[@]}" obj="${builddir}"

	# Modify firmware descriptor if building for the EM100 emulator.
	if use em100-mode; then
		ifdtool --em100 "${builddir}/coreboot.rom" || die
		mv "${builddir}/coreboot.rom"{.new,} || die
	fi

	if use cros_ec; then
		add_ec "${builddir}/coreboot.rom" "ecrw" "${froot}"
	fi

	if use pd_sync; then
		add_ec "${builddir}/coreboot.rom" "pdrw" "${froot}/${PD_FIRMWARE}"
	fi

	( cd "${froot}/cbfs" 2>/dev/null && find . -type f) | \
	while read file; do
		file="${file:2}" # strip ./ prefix
		cbfstool "${builddir}/coreboot.rom" add \
			-r COREBOOT,FW_MAIN_A,FW_MAIN_B \
			-f "${froot}/cbfs/$file" \
			-n "$file" \
			-t raw -c lzma
	done
}

src_compile() {
	tc-export CC

	# Set KERNELREVISION (really coreboot revision) to the ebuild revision
	# number followed by a dot and the first seven characters of the git
	# hash. The name is confusing but consistent with the coreboot
	# Makefile.
	local sha1v="${VCSID/*-/}"
	export KERNELREVISION=".${PV}.${sha1v:0:7}"

	# Export the known cross compilers so there isn't a reliance
	# on what the default profile is for exporting a compiler. The
	# reasoning is that the firmware may need more than one to build
	# and boot.
	export CROSS_COMPILE_i386="i686-pc-linux-gnu-"
	# For coreboot.org upstream architecture naming.
	export CROSS_COMPILE_x86="i686-pc-linux-gnu-"
	export CROSS_COMPILE_mipsel="mipsel-cros-linux-gnu-"
	# aarch64: used on chromeos-2013.04
	export CROSS_COMPILE_aarch64="aarch64-cros-linux-gnu-"
	# arm64: used on coreboot upstream
	export CROSS_COMPILE_arm64="aarch64-cros-linux-gnu-"
	export CROSS_COMPILE_arm="armv7a-cros-linux-gnu- armv7a-cros-linux-gnueabi-"

	use verbose && elog "Toolchain:\n$(sh util/xcompile/xcompile)\n"

	set_build_env "$(get_board)"
	make_coreboot "${BUILD_DIR}"

	# Build a second ROM with serial support for developers
	mv "${CONFIG_SERIAL}" "${CONFIG}"
	make_coreboot "${BUILD_DIR_SERIAL}"
}

src_install() {
	local mapfile

	set_build_env "$(get_board)"
	insinto /firmware

	newins "${BUILD_DIR}/coreboot.rom" coreboot.rom
	newins "${BUILD_DIR_SERIAL}/coreboot.rom" coreboot.rom.serial

	local config_file="${FILESDIR}/configs/config.$(get_board)"
	OPROM=$( awk 'BEGIN{FS="\""} /CONFIG_VGA_BIOS_FILE=/ { print $2 }' \
		"${config_file}" )
	CBFSOPROM=pci$( awk 'BEGIN{FS="\""} /CONFIG_VGA_BIOS_ID=/ { print $2 }' \
		"${config_file}" ).rom
	FSP=$( awk 'BEGIN{FS="\""} /CONFIG_FSP_FILE=/ { print $2 }' \
		"${config_file}" )
	if [[ -n "${FSP}" ]]; then
		newins ${FSP} fsp.bin
	fi
	if [[ -n "${OPROM}" ]]; then
		newins ${OPROM} ${CBFSOPROM}
	fi
	if use memmaps; then
		for mapfile in "${BUILD_DIR}"/cbfs/fallback/*.map
		do
			doins $mapfile
		done
	fi
	newins "${CONFIG}" coreboot.config

	# Keep binaries with debug symbols around for crash dump analysis
	if [[ -s build/bl31.elf ]]; then
		newins build/bl31.elf bl31.elf
		newins build_serial/bl31.elf bl31.serial.elf
	fi
	insinto /firmware/coreboot
	doins "${BUILD_DIR}"/cbfs/fallback/*.debug
	insinto /firmware/coreboot_serial
	doins "${BUILD_DIR_SERIAL}"/cbfs/fallback/*.debug
}
