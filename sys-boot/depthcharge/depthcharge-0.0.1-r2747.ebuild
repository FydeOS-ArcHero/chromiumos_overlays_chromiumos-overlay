# Copyright 2012 The Chromium OS Authors.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_COMMIT=("75e56c796714fe0acbdde7c097166dc0c963676c" "b25d49d44bdda52eb063e8c1db0fc55c37832d45")
CROS_WORKON_TREE=("b86444b3047a5a527514bd4fa2594954ee6a06ad" "e52989c7c37d5aa1e046c6045c0efa1ea21caec4")
CROS_WORKON_PROJECT=(
	"chromiumos/platform/depthcharge"
	"chromiumos/platform/vboot_reference"
)

DESCRIPTION="coreboot's depthcharge payload"
HOMEPAGE="http://www.coreboot.org"
LICENSE="GPL-2"
KEYWORDS="*"
IUSE="detachable menu_ui legacy_menu_ui diag_payload fwconsole mocktpm pd_sync
	unibuild verbose debug generated_cros_config
	physical_presence_power physical_presence_recovery"

DEPEND="
	sys-boot/libpayload:=
	unibuild? (
		!generated_cros_config? ( chromeos-base/chromeos-config )
		generated_cros_config? ( chromeos-base/chromeos-config-bsp:= )
	)
"

CROS_WORKON_LOCALNAME=("../platform/depthcharge" "../platform/vboot_reference")
VBOOT_REFERENCE_DESTDIR="${S}/vboot_reference"
CROS_WORKON_DESTDIR=("${S}" "${VBOOT_REFERENCE_DESTDIR}")

# Don't strip to ease remote GDB use (cbfstool strips final binaries anyway)
STRIP_MASK="*"

inherit cros-workon cros-board toolchain-funcs cros-unibuild

src_configure() {
	cros-workon_src_configure
}

# Get the depthcharge board config to build for.
# Checks the current board with/without variant. Echoes the board config file
# that should be used to build depthcharge.
get_board() {
	local board=$(get_current_board_with_variant)
	if [[ ! -d "board/${board}" ]]; then
		board=$(get_current_board_no_variant)
	fi

	echo "${board}"
}

# Build depthcharge with common options.
# Usage example: dc_make dev LIBPAYLOAD_DIR="libpayload"
# Args:
#   $1: Target to build
#   $2: Build directory to use.
#   $3: Firmware file to use for LIBPAYLOAD_DIR
#   $4+: Any other Makefile arguments.
dc_make() {
	local target="$1"
	local builddir="$2"
	local libpayload

	[[ -n "$3" ]] && libpayload="LIBPAYLOAD_DIR=${SYSROOT}/firmware/$3/"

	shift 3

	local OPTS=(
		"VB_SOURCE=${VBOOT_REFERENCE_DESTDIR}"
		"PD_SYNC=$(usev pd_sync)"
		"obj=${builddir}"
	)

	use verbose && OPTS+=( "V=1" )
	use debug && OPTS+=( "SOURCE_DEBUG=1" )

	emake "${OPTS[@]}" \
		${libpayload} \
		"${target}" \
		"$@"
}

# Build depthcharge for the current board.
# Builds the various output files for depthcharge:
#   depthcharge.elf   - normal image
#   dev.elf           - developer image
#   netboot.elf       - network image
# In addition, .map files are produced for each, and a .config file which
# holds the configuration that was used.
# Args
#   $1: board to build for.
make_depthcharge() {
	local board="$1"
	local builddir="$2"
	local defconfig="board/${board}/defconfig"

	if use mocktpm ; then
		echo "CONFIG_MOCK_TPM=y" >> "${defconfig}"
	fi
	if use fwconsole ; then
		echo "CONFIG_CLI=y" >> "${defconfig}"
		echo "CONFIG_SYS_PROMPT=\"${board}: \"" >> "${defconfig}"
	fi
	if use detachable ; then
		echo "CONFIG_DETACHABLE=y" >> "${defconfig}"
	fi
	if use menu_ui ; then
		echo "CONFIG_MENU_UI=y" >> "${defconfig}"
	elif use legacy_menu_ui ; then
		echo "CONFIG_LEGACY_MENU_UI=y" >> "${defconfig}"
	else
		echo "CONFIG_LEGACY_CLAMSHELL_UI=y" >> "${defconfig}"
	fi
	# Using diagnostic payload implies enabling UI to run it
	if use diag_payload ; then
		echo "CONFIG_DIAGNOSTIC_UI=y" >> "${defconfig}"
	fi

	if use physical_presence_power || use physical_presence_recovery ; then
		echo "CONFIG_PHYSICAL_PRESENCE_KEYBOARD=n" >> "${defconfig}"
	fi

	[[ ${PV} == "9999" ]] && dc_make distclean "${builddir}" libpayload
	dc_make defconfig "${builddir}" libpayload BOARD="${board}"
	cp .config "${builddir}/depthcharge.config"

	dc_make depthcharge "${builddir}" libpayload
	dc_make dev "${builddir}" libpayload_gdb
	dc_make netboot "${builddir}" libpayload_gdb
}

src_compile() {
	# Firmware related binaries are compiled with a 32-bit toolchain
	# on 64-bit platforms
	if use amd64 ; then
		export CROSS_COMPILE="i686-pc-linux-gnu-"
		export CC="${CROSS_COMPILE}gcc"
	else
		export CROSS_COMPILE=${CHOST}-
	fi

	if use unibuild; then
		local build_target

		for build_target in $(cros_config_host \
			get-firmware-build-targets depthcharge); do
			make_depthcharge "${build_target}" "${build_target}"
		done
	else
		make_depthcharge "$(get_board)" build
	fi
}

do_install() {
	local board="$1"
	local builddir="$2"
	local dstdir="/firmware"

	if [[ -n "${build_target}" ]]; then
		dstdir+="/${build_target}"
		einfo "Installing depthcharge ${build_target} into ${dest_dir}"
	fi
	insinto "${dstdir}"

	pushd "${builddir}" >/dev/null || \
		die "couldn't access ${builddir}/ directory"

	local files_to_copy=(
		depthcharge.config
		{netboot,depthcharge,dev}.elf{,.map}
	)

	insinto "${dstdir}/depthcharge"
	doins "${files_to_copy[@]}"

	popd >/dev/null
}

src_install() {
	local build_target

	if use unibuild; then
		for build_target in $(cros_config_host \
			get-firmware-build-targets depthcharge); do
			do_install "${build_target}" "${build_target}"
		done
	else
		do_install "$(get_board)" build
	fi
}
