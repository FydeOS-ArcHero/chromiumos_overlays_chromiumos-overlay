# Copyright (c) 2011 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit cros-debug cros-unibuild

DESCRIPTION="ChromeOS firmware image builder"
HOMEPAGE="http://www.chromium.org"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
# TODO(sjg@chromium.org): Remove when x86 can build all boards
BOARDS="alex aplrvp atlas auron bayleybay beltino bolt butterfly"
BOARDS="${BOARDS} chell cnlrvp coral cyan dedede dragonegg drallion emeraldlake2 eve"
BOARDS="${BOARDS} endeavour falco fizz fox glados glkrvp grunt hatch jecht kalista"
BOARDS="${BOARDS} kblrvp kunimitsu link lumpy lumpy64 mario meowth mushu nasher nami"
BOARDS="${BOARDS} nautilus nocturne octopus palkia panther parrot peppy poppy puff pyro"
BOARDS="${BOARDS} rambi rammus reef samus sand sarien sklrvp slippy snappy"
BOARDS="${BOARDS} soraka squawks stout strago stumpy sumo volteer zoombini zork tglrvp"
IUSE="${BOARDS} diag_payload seabios wilco_ec"
IUSE="${IUSE} fsp unibuild u-boot tianocore cros_ec pd_sync +bmpblk"
IUSE="${IUSE} generated_cros_config"

# 'ec_ro_sync' can be a solution for devices that will fail to complete recovery
# due to TCPC reset (crbug.com/782427#c4), but may not work for every devices
# (crbug.com/1024401, and MT8183 family). Please double check before turning on
# this option.
IUSE="${IUSE} ec_ro_sync"
IUSE="${IUSE} +depthcharge"

REQUIRED_USE="
	^^ ( ${BOARDS} arm mips )
"

BDEPEND="chromeos-base/vboot_reference"

# TODO(sjg@chromium.org): Drop this zork stuff when the code is upstream
DEPEND="
	zork? ( sys-boot/coreboot-zork:= )
	!zork? ( sys-boot/coreboot:= )
	depthcharge? ( sys-boot/depthcharge:= )
	bmpblk? ( sys-boot/chromeos-bmpblk:= )
	tianocore? ( sys-boot/edk2:= )
	seabios? ( sys-boot/chromeos-seabios:= )
	unibuild? (
		!generated_cros_config? ( chromeos-base/chromeos-config )
		generated_cros_config? ( chromeos-base/chromeos-config-bsp:= )
	)
	u-boot? ( sys-boot/u-boot:= )
	cros_ec? ( chromeos-base/chromeos-ec:= )
	pd_sync? ( chromeos-base/chromeos-ec:= )
	"

# Directory where the generated files are looked for and placed.
CROS_FIRMWARE_IMAGE_DIR="/firmware"
CROS_FIRMWARE_ROOT="${SYSROOT}${CROS_FIRMWARE_IMAGE_DIR}"

S=${WORKDIR}

do_cbfstool() {
	local output
	output=$(cbfstool "$@" 2>&1)
	if [ $? != 0 ]; then
		die "Failed cbfstool invocation: cbfstool $@\n${output}"
	fi
	printf "${output}"
}

sign_region() {
	local fw_image=$1
	local keydir=$2
	local slot=$3

	local tmpfile=`mktemp`
	local cbfs=FW_MAIN_${slot}
	local vblock=VBLOCK_${slot}

	do_cbfstool ${fw_image} read -r ${cbfs} -f ${tmpfile}
	local size=$(do_cbfstool ${fw_image} print -k -r ${cbfs} | \
		tail -1 | \
		sed "/(empty).*null/ s,^(empty)[[:space:]]\(0x[0-9a-f]*\)\tnull\t.*$,\1,")
	size=$(printf "%d" ${size})

	# If the last entry is called "(empty)" and of type "null", remove it from
	# the section so it isn't part of the signed data, to improve boot speed
	# if (as often happens) there's a large unused suffix.
	if [ -n "${size}" ] && [ ${size} -gt 0 ]; then
		head -c ${size} ${tmpfile} > ${tmpfile}.2
		mv ${tmpfile}.2 ${tmpfile}
		# Use 255 (aka 0xff) as the filler, this greatly reduces
		# memory areas which need to be programmed for spi flash
		# chips, because the erase value is 0xff.
		do_cbfstool ${fw_image} write --force -u -i 255 \
			-r ${cbfs} -f ${tmpfile}
	fi

	futility vbutil_firmware \
		--vblock ${tmpfile}.out \
		--keyblock ${keydir}/firmware.keyblock \
		--signprivate ${keydir}/firmware_data_key.vbprivk \
		--version 1 \
		--fv ${tmpfile} \
		--kernelkey ${keydir}/kernel_subkey.vbpubk \
		--flags 0

	do_cbfstool ${fw_image} write -u -i 255 -r ${vblock} -f ${tmpfile}.out

	rm -f ${tmpfile} ${tmpfile}.out
}

sign_image() {
	local fw_image=$1
	local keydir=$2

	sign_region "${fw_image}" "${keydir}" A
	sign_region "${fw_image}" "${keydir}" B
}

add_payloads() {
	local fw_image=$1
	local ro_payload=$2
	local rw_payload=$3

	if [ -n "${ro_payload}" ]; then
		do_cbfstool "${fw_image}" add-payload \
			-f "${ro_payload}" -n fallback/payload -c lzma
	fi

	if [ -n "${rw_payload}" ]; then
		do_cbfstool "${fw_image}" add-payload -f "${rw_payload}" \
			-n fallback/payload -c lzma -r FW_MAIN_A,FW_MAIN_B
	fi
}

# Returns true if EC supports EFS.
is_ec_efs_enabled() {
	local depthcharge_config="$1"

	grep -q "^CONFIG_EC_EFS=y$" "${depthcharge_config}"
}

# Returns true if coreboot is set up to perform EC software sync
is_early_ec_sync_enabled() {
	local coreboot_config="$1"

	grep -q "^CONFIG_VBOOT_EARLY_EC_SYNC=y$" "${coreboot_config}"
}

# Adds EC{ro,rw} images to CBFS
add_ec() {
	local depthcharge_config="$1"
	local coreboot_config="$2"
	local rom="$3"
	local name="$4"
	local ecroot="$5"
	local pad="0"
	local comp_type="lzma"

	# The initial implementation of EC software sync in coreboot does
	# not support decompression of the EC firmware images.  There is
	# not enough CAR/SRAM space available to store the entire image
	# decompressed, so it would have to be decompressed in a "streaming"
	# fashion.  See crbug.com/1023830.
	if [[ "${name}" != "pd" ]] && is_early_ec_sync_enabled "${coreboot_config}"; then
		einfo "Adding uncompressed EC image"
		comp_type="none"
	fi

	# When EFS is enabled, the payloads here may be resigned and enlarged so
	# extra padding is needed.
	if use depthcharge; then
		is_ec_efs_enabled "${depthcharge_config}" && pad="128"
	fi
	einfo "Padding ${name}{ro,rw} ${pad} byte."

	do_cbfstool "${rom}" add -r FW_MAIN_A,FW_MAIN_B -t raw -c "${comp_type}" \
		-f "${ecroot}/ec.RW.bin" -n "${name}rw" -p "${pad}"
	do_cbfstool "${rom}" add -r FW_MAIN_A,FW_MAIN_B -t raw -c none \
		-f "${ecroot}/ec.RW.hash" -n "${name}rw.hash"

	if ! use ec_ro_sync; then
		einfo "Skip packing EC RO."
	elif [[ -f "${ecroot}/ec.RO.bin" ]]; then
		do_cbfstool "${rom}" add -r COREBOOT -t raw -c "${comp_type}" \
			-f "${ecroot}/ec.RO.bin" -n "${name}ro" -p "${pad}"
		do_cbfstool "${rom}" add -r COREBOOT -t raw -c none \
			-f "${ecroot}/ec.RO.hash" -n "${name}ro.hash"
	else
		ewarn "Missing ${ecroot}/ec.RO.bin, skip packing EC RO."
	fi

	# Add EC version file for Wilco EC
	if use wilco_ec; then
		do_cbfstool "${rom}" add -r FW_MAIN_A,FW_MAIN_B -t raw -c none \
			-f "${ecroot}/ec.RW.version" -n "${name}rw.version"
	fi
}

# Add payloads and sign the image.
# This takes the base image and creates a new signed one with the given
# payloads added to it.
# The image is placed in directory ${outdir} ("" for current directory).
# An image suffix is added is ${suffix} is non-empty (e.g. "dev", "net").
# Args:
#   $1: Image type (e,g. "" for standard image, "dev" for dev image)
#   $2: Source image to start from.
#   $3: Payload to add to read-only image portion
#   $4: Payload to add to read-write image portion
build_image() {
	local image_type=$1
	local src_image=$2
	local ro_payload=$3
	local rw_payload=$4
	local devkeys_dir="${BROOT}/usr/share/vboot/devkeys"

	[ -n "${image_type}" ] && image_type=".${image_type}"
	local dst_image="${outdir}image${suffix}${image_type}.bin"

	einfo "Building image ${dst_image}"
	cp ${src_image} ${dst_image}
	add_payloads ${dst_image} ${ro_payload} ${rw_payload}
	sign_image ${dst_image} "${devkeys_dir}"
}

# Hash the payload of an altfw alternative bootloader
# Loads the payload from $rom on RW_LEGACY under:
#   altfw/<name>
# Stores the hash into $rom on RW-A and RW-B as:
#   altfw/<name>.sha256
# Args:
#   $1: rom file where the payload can be found
#   $2: name of the alternative bootloader
hash_altfw_payload() {
	local rom="$1"
	local name="$2"
	local payload_file="altfw/${name}"
	local hash_file="${payload_file}.sha256"
	local tmpfile="$(mktemp)"
	local tmphash="$(mktemp)"
	local rom

	einfo "  Hashing ${payload_file}"

	# Grab the raw uncompressed payload (-U) and hash it into $tmphash.
	do_cbfstool "${rom}" extract -r RW_LEGACY -n "${payload_file}" \
		-f "${tmpfile}" -U >/dev/null
	openssl dgst -sha256 -binary "${tmpfile}" > "${tmphash}"

	# Copy $tmphash into RW-A and RW-B.
	do_cbfstool "${rom}" add -r FW_MAIN_A,FW_MAIN_B \
		-f "${tmphash}" -n "${hash_file}" -t raw
}

# Set up alternative bootloaders
#
# This creates a new CBFS in the RW_LEGACY area and puts bootloaders into it,
# based on USE flags. A list is written to an "altfw/list" file so that there
# is a record of what is available.
# Args:
#   $1: coreboot build target to use for prefix on target-specific payloads
#   $2: coreboot file to add alternative bootloaders to
setup_altfw() {
	local target="$1"
	local rom="$2"
	local bl_list="${T}/altfw"

	einfo "Adding alternative firmware"

	# Add master header to the RW_LEGACY section
	printf "ptr_" > "${T}/ptr"
	do_cbfstool "${rom}" add -r RW_LEGACY -f "${T}/ptr" -n "header pointer" \
		-t "cbfs header" -b -4
	do_cbfstool "${rom}" add-master-header -r RW_LEGACY
	rm "${T}/ptr"
	> "${bl_list}"

	# Add U-Boot if enabled
	if use u-boot; then
		einfo "- Adding U-Boot"

		do_cbfstool "${rom}" add-flat-binary -r RW_LEGACY -n altfw/u-boot \
			-c lzma -l 0x1110000 -e 0x1110000 \
			-f "${CROS_FIRMWARE_ROOT}/u-boot.bin"
		hash_altfw_payload "${rom}" u-boot
		echo "1;altfw/u-boot;U-Boot;U-Boot bootloader" >> "${bl_list}"
	fi

	# Add TianoCore if enabled
	if use tianocore; then
		einfo "- Adding TianoCore"

		do_cbfstool "${rom}" add-payload -r RW_LEGACY -n altfw/tianocore -c \
			lzma -f "${CROS_FIRMWARE_ROOT}/tianocore/UEFIPAYLOAD.fd"
		hash_altfw_payload "${rom}" tianocore
		echo "2;altfw/tianocore;TianoCore;TianoCore bootloader" \
			>> "${bl_list}"

		# For now, use TianoCore as the default
		echo "0;altfw/tianocore;TianoCore;TianoCore bootloader" \
			>> "${bl_list}"
	fi

	# Add SeaBIOS if enabled
	if use seabios; then
		local root="${CROS_FIRMWARE_ROOT}/seabios/"
		einfo "- Adding SeaBIOS"

		do_cbfstool "${rom}" add-payload -r RW_LEGACY -n altfw/seabios -c lzma \
			-f "${root}/seabios.elf"
		hash_altfw_payload "${rom}" seabios
		for f in "${root}oprom/"*; do
			if [[ -f "${f}" ]]; then
				do_cbfstool "${rom}" add -r RW_LEGACY -f "${f}" \
					-n "${f#${root}oprom/}" -t optionrom
			fi
		done
		for f in "${root}cbfs/"*; do
			if [[ -f "${f}" ]]; then
				do_cbfstool "${rom}" add -r RW_LEGACY -f "${f}" \
					-n "${f#${root}cbfs/}" -t raw
			fi
		done
		for f in "${root}"etc/*; do
			do_cbfstool "${rom}" add -r RW_LEGACY -f "${f}" \
				-n "${f#$root}" -t raw
		done
		echo "3;altfw/seabios;SeaBIOS;SeaBIOS bootloader" \
			>> "${bl_list}"
	fi

	# Add Diagnostic Payload if enabled
	if use diag_payload; then
		einfo "- Adding Diagnostic Payload"

		do_cbfstool "${rom}" add-payload -r RW_LEGACY -n altfw/diag -c lzma -f \
			"${CROS_FIRMWARE_ROOT}/diag_payload/${target}-diag.bin"
		hash_altfw_payload "${rom}" diag
		echo "5;altfw/diag;Diagnostics;System Diagnostics" \
			>> "${bl_list}"

		# Use Diag as the default if tianocore is not enabled
		if ! use tianocore; then
			echo "0;altfw/diag;Diagnostics;System Diagnostics" \
				>> "${bl_list}"
		fi
	fi

	# Add the list
	einfo "- adding firmware list"
	do_cbfstool "${rom}" add -r RW_LEGACY -n altfw/list -t raw -f "${bl_list}"

	# Add the tag for silent updating.
	do_cbfstool "${rom}" add-int -r RW_LEGACY -i 1 -n "cros_allow_auto_update"

	# TODO(kitching): Get hash and sign.
}

# Add Chrome OS assets to the base and serial images:
#       compressed-assets-ro/*   - fonts, images and screens for recovery mode
#                                  originally from cbfs-ro-compress/*,
#                                  pre-compressed in src_compile
#       compressed-assets-rw/*   - files originally from cbfs-rw-compress/*,
#                                  pre-compressed in src_compile
#                                  used for vbt*.bin
#       raw-assets-rw/* -          files originally from
#                                  cbfs-rw-raw/*,
#                                  used for extra wifi_sar files
# Args:
#  $1: Filename of image to add to

add_assets() {
	local rom="$1"

	while IFS= read -r -d '' file; do
		do_cbfstool "${rom}" add -r COREBOOT -f "${file}" \
			-n "$(basename "${file}")" -t raw -c precompression
	done < <(find compressed-assets-ro -type f -print0)

	while IFS= read -r -d '' file; do
		do_cbfstool "${rom}" add -r COREBOOT,FW_MAIN_A,FW_MAIN_B \
			-f "${file}" -n "$(basename "${file}")" -t raw \
			-c precompression
	done < <(find compressed-assets-rw -type f -print0)

	while IFS= read -r -d '' file; do
		do_cbfstool "${rom}" add -r COREBOOT,FW_MAIN_A,FW_MAIN_B \
			-f "${file}" -n "$(basename "${file}")" -t raw
	done < <(find "raw-assets-rw/${build_name}" -type f -print0)
}

# Build firmware images for a given board
# Creates image*.bin for the following images:
#    image.bin          - production image (no serial console)
#    image.serial.bin   - production image with serial console enabled
#    image.dev.bin      - developer image with serial console enabled
#    image.net.bin      - netboot image with serial console enabled
#
# If $2 is set, then it uses "image-$2" instead of "image" and puts images in
# the $2 subdirectory.
#
# If outdir
# Args:
#   $1: Directory containing the input files:
#       coreboot.rom             - coreboot ROM image containing various pieces
#       coreboot.rom.serial      - same, but with serial console enabled
#       depthcharge/depthcharge.elf - depthcharge ELF payload
#       depthcharge/dev.elf      - developer version of depthcharge
#       depthcharge/netboot.elf  - netboot version of depthcharge
#       depthcharge/depthcharge.config - configuration used to build depthcharge image
#       (plus files mentioned above in add_assets)
#   $2: Name to use when naming output files (see note above, can be empty)
#
#   $3: Name of target to build for coreboot (can be empty)
#
#   $4: Name of target to build for depthcharge (can be empty)
#
#   $5: Name of target to build for ec (can be empty)
build_images() {
	local froot="$1"
	local build_name="$2"
	local coreboot_build_target="$3"
	local depthcharge_build_target="$4"
	local ec_build_target="$5"
	local outdir
	local suffix
	local file
	local rom

	local coreboot_orig
	local depthcharge_prefix
	local coreboot_config

	if [ -n "${build_name}" ]; then
		einfo "Building firmware images for ${build_name}"
		outdir="${build_name}/"
		mkdir "${outdir}"
		suffix="-${build_name}"
		coreboot_orig="${froot}/${coreboot_build_target}/coreboot.rom"
		coreboot_config="${froot}/${coreboot_build_target}/coreboot.config"
		depthcharge_prefix="${froot}/${depthcharge_build_target}/depthcharge"
	else
		coreboot_orig="${froot}/coreboot.rom"
		coreboot_config="${froot}/coreboot.config"
		depthcharge_prefix="${froot}/depthcharge"
	fi

	local coreboot_file="coreboot.rom"
	cp "${coreboot_orig}" "${coreboot_file}"
	cp "${coreboot_orig}.serial" "${coreboot_file}.serial"

	local depthcharge
	local depthcharge_dev
	local netboot
	local depthcharge_config

	if use depthcharge; then
		depthcharge="${depthcharge_prefix}/depthcharge.elf"
		depthcharge_dev="${depthcharge_prefix}/dev.elf"
		netboot="${depthcharge_prefix}/netboot.elf"
		depthcharge_config="${depthcharge_prefix}/depthcharge.config"
	fi

	add_assets "${coreboot_file}"
	add_assets "${coreboot_file}.serial"

	if [[ -d ${froot}/cbfs ]]; then
		die "something is still using ${froot}/cbfs, which is deprecated."
	fi

	if use cros_ec || use wilco_ec; then
		if use unibuild; then
			einfo "Adding EC for ${ec_build_target}"
			add_ec "${depthcharge_config}" "${coreboot_config}" "${coreboot_file}" "ec" "${froot}/${ec_build_target}"
			add_ec "${depthcharge_config}" "${coreboot_config}" "${coreboot_file}.serial" "ec" "${froot}/${ec_build_target}"
		else
			add_ec "${depthcharge_config}" "${coreboot_config}" "${coreboot_file}" "ec" "${froot}"
			add_ec "${depthcharge_config}" "${coreboot_config}" "${coreboot_file}.serial" "ec" "${froot}"
		fi
	fi

	local pd_folder="${froot}/"
	if use unibuild; then
		pd_folder+="${ec_build_target}_pd"
	else
		# For non-unibuild boards this must match PD_FIRMWARE in board
		# overlay make.defaults.
		pd_folder+="${PD_FIRMWARE:-$(basename "${ROOT}")_pd}"
	fi

	if use pd_sync; then
		add_ec "${depthcharge_config}" "${coreboot_config}" "${coreboot_file}" "pd" "${pd_folder}"
		add_ec "${depthcharge_config}" "${coreboot_config}" "${coreboot_file}.serial" "pd" "${pd_folder}"
	fi

	setup_altfw "${coreboot_build_target}" "${coreboot_file}"
	setup_altfw "${coreboot_build_target}" "${coreboot_file}.serial"

	build_image "" "${coreboot_file}" "${depthcharge}" "${depthcharge}"

	build_image serial "${coreboot_file}.serial" \
		"${depthcharge}" "${depthcharge}"

	build_image dev "${coreboot_file}.serial" \
		"${depthcharge_dev}" "${depthcharge_dev}"

	# Build a netboot image.
	#
	# The readonly payload is usually depthcharge and the read/write
	# payload is usually netboot. This way the netboot image can be used
	# to boot from USB through recovery mode if necessary.
	build_image net "${coreboot_file}.serial" "${depthcharge}" "${netboot}"

	# Set convenient netboot parameter defaults for developers.
	local bootfile="${PORTAGE_USERNAME}/${BOARD_USE}/vmlinuz"
	local argsfile="${PORTAGE_USERNAME}/${BOARD_USE}/cmdline"
	netboot_firmware_settings.py \
		-i "${outdir}image${suffix}.net.bin" \
		--bootfile="${bootfile}" --argsfile="${argsfile}" &&
		netboot_firmware_settings.py \
			-i "${outdir}image${suffix}.dev.bin" \
			--bootfile="${bootfile}" --argsfile="${argsfile}" ||
		die "failed to preset netboot parameter defaults."
	einfo "Netboot configured to boot ${bootfile}, fetch kernel command" \
		"line from ${argsfile}, and use the DHCP-provided TFTP server IP."
}

src_compile() {
	local froot="${CROS_FIRMWARE_ROOT}"
	einfo "Copying static rw assets"

	if [[ -d "${froot}"/cbfs-rw-raw ]]; then
		mkdir raw-assets-rw
		cp -R "${froot}"/cbfs-rw-raw/* raw-assets-rw/ ||
			die "unable to copy files cbfw-rw-raw files"
	fi

	einfo "Compressing static assets"

	if [[ -d ${froot}/rocbfs ]]; then
		die "something is still using ${froot}/rocbfs, which is deprecated."
	fi

	# files from cbfs-ro-compress/ are installed in
	# all images' RO CBFS, compressed
	mkdir compressed-assets-ro
	find ${froot}/cbfs-ro-compress -mindepth 1 -maxdepth 1 -printf "%P\0" \
		2>/dev/null | \
		xargs -0 -n 1 -P $(nproc) -I '{}' \
		cbfs-compression-tool compress ${froot}/cbfs-ro-compress/'{}' \
			compressed-assets-ro/'{}' LZMA

	# files from cbfs-rw-compress/ are installed in
	# all images' RO/RW CBFS, compressed
	mkdir compressed-assets-rw
	find ${froot}/cbfs-rw-compress -mindepth 1 -maxdepth 1 -printf "%P\0" \
		2>/dev/null | \
		xargs -0 -n 1 -P $(nproc) -I '{}' \
		cbfs-compression-tool compress ${froot}/cbfs-rw-compress/'{}' \
			compressed-assets-rw/'{}' LZMA

	if use unibuild; then
		local fields="coreboot,depthcharge,ec"
		local cmd="get-firmware-build-combinations"
		(cros_config_host "${cmd}" "${fields}" || die) |
		while read -r name; do
			read -r coreboot
			read -r depthcharge
			read -r ec
			einfo "Building image for: ${name}"
			build_images ${froot} ${name} ${coreboot} ${depthcharge} ${ec}
		done
	else
		build_images "${froot}" "" "" "" ""
	fi
}

src_install() {
	insinto "${CROS_FIRMWARE_IMAGE_DIR}"
	if use unibuild; then
		local fields="coreboot,depthcharge"
		local cmd="get-firmware-build-combinations"
		(cros_config_host "${cmd}" "${fields}" || die) |
		while read -r name; do
			read -r coreboot
			read -r depthcharge
			doins "${name}"/image-${name}*.bin
		done
	else
		doins image*.bin
	fi
}
