# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: cros-u-boot.eclass
# @MAINTAINER:
# The Chromium OS Authors
# @BLURB: Unifies logic for building u-boot images for Chromium OS.

[[ ${EAPI} != "4" ]] && die "Only EAPI=4 is supported"

CROS_WORKON_OUTOFTREE_BUILD=1

inherit binutils-funcs cros-board toolchain-funcs flag-o-matic

DESCRIPTION="Das U-Boot boot loader"
HOMEPAGE="http://www.denx.de/wiki/U-Boot"
LICENSE="GPL-2"
SLOT="0"
IUSE="dev profiling factory-mode"

DEPEND=">=chromeos-base/vboot_reference-firmware-0.0.1-r175
	!sys-boot/x86-firmware-fdts
	!sys-boot/exynos-u-boot
	!sys-boot/tegra2-public-firmware-fdts
	"

RDEPEND="${DEPEND}
	"

# @ECLASS-VARIABLE: U_BOOT_ALL_CONFIGS
# @DESCRIPTION:
# List of all boards for which this u-boot can be configured
: ${U_BOOT_ALL_CONFIGS:=}

# @ECLASS-VARIABLE: U_BOOT_CFG_PREFIX
# @DESCRIPTION:
# Prefix used for configuring u-boot for a board, i.e. "chromeos_"
: ${U_BOOT_CFG_PREFIX:=chromeos_}

# @ECLASS-VARIABLE: U_BOOT_CONFIG_USE_PREFIX
# @DESCRIPTION:
# Prefix used to identify which board u-boot is building for.
: ${U_BOOT_CONFIG_USE_PREFIX:=u_boot_config_use_}

[[ -z ${U_BOOT_ALL_CONFIGS} ]] && die "U_BOOT_ALL_CONFIGS must be set"

IUSE_CONFIGS=${U_BOOT_ALL_CONFIGS[@]/#/${U_BOOT_CONFIG_USE_PREFIX}}

IUSE="${IUSE} ${IUSE_CONFIGS}"

REQUIRED_USE="^^ ( ${IUSE_CONFIGS} )"

UB_BUILD_DIR="${WORKDIR}/${P}"
UB_BUILD_DIR_NB="${UB_BUILD_DIR%/}_nb"

# @FUNCTION: get_current_u_boot_config
# @DESCRIPTION:
# Finds the config for the current board by searching USE for an entry
# signifying which version to use.
get_current_u_boot_config() {
	local use_config
	for use_config in ${IUSE_CONFIGS}; do
		if use ${use_config}; then
			echo "${U_BOOT_CFG_PREFIX}${use_config#${U_BOOT_CONFIG_USE_PREFIX}}_config"
			return
		fi
	done
	die "Unable to determine current U-Boot config."
}

# @FUNCTION: netboot_required
# @DESCRIPTION:
# Checks if netboot image also needs to be generated.
netboot_required() {
	# Build netbootable image for Link unconditionally for now.
	# TODO (vbendeb): come up with a better scheme of determining what
	#                 platforms should always generate the netboot capable
	#                 legacy image.
	local board=$(get_current_board_no_variant)

	use factory-mode || [[ "${board}" == "link" ]]
}

# @FUNCTION: get_config_var
# @USAGE: <config name> <requested variable>
# @DESCRIPTION:
# Returns the value of the requested variable in the specified config
# if present. This can only be called after make config.
get_config_var() {
	local config="${1%_config}"
	local var="${2}"
	local boards_cfg="${S}/boards.cfg"
	local i
	case "${var}" in
	ARCH)	i=2;;
	CPU)	i=3;;
	BOARD)	i=4;;
	VENDOR)	i=5;;
	SOC)	i=6;;
	*)	die "Unsupported field: ${var}"
	esac
	awk -v i=$i -v cfg="${config}" '$1 == cfg { print $i }' "${boards_cfg}"
}

umake() {
	# Add `ARCH=` to reset ARCH env and let U-Boot choose it.
	ARCH= emake "${COMMON_MAKE_FLAGS[@]}" "$@"
}

cros-u-boot_src_configure() {
	export LDFLAGS=$(raw-ldflags)
	tc-export BUILD_CC

	CROS_U_BOOT_CONFIG="$(get_current_u_boot_config)"
	elog "Using U-Boot config: ${CROS_U_BOOT_CONFIG}"

	# Firmware related binaries are compiled with 32-bit toolchain
	# on 64-bit platforms
	if [[ ${CHOST} == x86_64-* ]]; then
		CROSS_PREFIX="i686-pc-linux-gnu-"
	else
		CROSS_PREFIX="${CHOST}-"
	fi

	COMMON_MAKE_FLAGS=(
		"CROSS_COMPILE=${CROSS_PREFIX}"
		"VBOOT=${SYSROOT}/usr"
		DEV_TREE_SEPARATE=1
		"HOSTCC=${BUILD_CC}"
		HOSTSTRIP=true
	)
	if use dev; then
		# Avoid hiding the errors and warnings
		COMMON_MAKE_FLAGS+=( -s )
	else
		COMMON_MAKE_FLAGS+=( -k )
		COMMON_MAKE_FLAGS+=( WERROR=y )
	fi
	if use x86 || use amd64 || use cros-debug; then
		COMMON_MAKE_FLAGS+=( VBOOT_DEBUG=1 )
	fi
	if use profiling; then
		COMMON_MAKE_FLAGS+=( VBOOT_PERFORMANCE=1 )
	fi

	BUILD_FLAGS=(
		"O=${UB_BUILD_DIR}"
	)

	umake "${BUILD_FLAGS[@]}" distclean
	umake "${BUILD_FLAGS[@]}" ${CROS_U_BOOT_CONFIG}

	if netboot_required; then
		BUILD_NB_FLAGS=(
			"O=${UB_BUILD_DIR_NB}"
			BUILD_FACTORY_IMAGE=1
		)
		umake "${BUILD_FLAGS[@]}" distclean
		umake "${BUILD_FLAGS[@]}" ${CROS_U_BOOT_CONFIG}
	fi
}

cros-u-boot_src_compile() {
	umake "${BUILD_FLAGS[@]}" all

	if netboot_required; then
		umake "${BUILD_NB_FLAGS[@]}" all
	fi
}

cros-u-boot_src_install() {
	local inst_dir="/firmware"
	local files_to_copy=(
		System.map
		u-boot.bin
	)
	local ub_vendor="$(get_config_var ${CROS_U_BOOT_CONFIG} VENDOR)"
	local ub_board="$(get_config_var ${CROS_U_BOOT_CONFIG} BOARD)"
	local ub_arch="$(get_config_var ${CROS_U_BOOT_CONFIG} ARCH)"
	local file
	local dts_dir

	if [[ -e spl/${ub_board}-spl.bin ]]; then
		files_to_copy+=( spl/${ub_board}-spl.bin )
	fi

	insinto "${inst_dir}"
	doins "${files_to_copy[@]/#/${UB_BUILD_DIR}/}"
	newins "${UB_BUILD_DIR}/u-boot" u-boot.elf

	if netboot_required; then
		newins "${UB_BUILD_DIR_NB}/u-boot.bin" u-boot_netboot.bin
		newins "${UB_BUILD_DIR_NB}/u-boot" u-boot_netboot.elf
	fi

	insinto "${inst_dir}/dts"
	local dts_dirs=(
		"board/${ub_vendor}/dts"
		"board/${ub_vendor}/${ub_board}"
		"arch/${ub_arch}/dts"
		"cros/dts"
	)
	for dts_dir in "${dts_dirs[@]}"; do
		files_to_copy="$(find ${dts_dir} -regex '.*\.dtsi?')"
		if [[ -n ${files_to_copy} ]]; then
			elog "Installing device tree files in ${dts_dir}"
			doins ${files_to_copy}
		fi
	done
}

EXPORT_FUNCTIONS src_configure src_compile src_install
