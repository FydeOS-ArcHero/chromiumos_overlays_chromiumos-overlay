# Copyright 2018 The Chromium Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2.

EAPI=7

CROS_WORKON_COMMIT="750656973903f14b2cac408b909f4f4b2e471d3d"
CROS_WORKON_TREE="51af33e92ac8e6d02198de12621917fae09080b9"
CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_SUBTREE="sepolicy"

inherit cros-workon udev

DESCRIPTION="Chrome OS SELinux Policy Package"
LICENSE="BSD-Google"
KEYWORDS="*"
IUSE="
	android-container-qt
	android-container-pi android-container-master-arc-dev
	+combine_chromeos_policy selinux_audit_all selinux_develop selinux_experimental
	arc_first_release_n
	nocheck
	cheets_user cheets_user_64
"
# When developers are doing something not Android. This required use is to let
# the developer know, disabling combine_chromeos_policy flag doesn't change
# anything.
REQUIRED_USE="
	!combine_chromeos_policy? ( ^^ ( android-container-qt android-container-pi android-container-master-arc-dev ) )
"

DEPEND="
	android-container-qt? ( chromeos-base/android-container-qt:0= )
	android-container-pi? ( chromeos-base/android-container-pi:0= )
	android-container-master-arc-dev? ( chromeos-base/android-container-master-arc-dev:0= )
"

RDEPEND="
	${DEPEND}
	sys-apps/restorecon
	sys-process/audit
"

SELINUX_VERSION="30"
SEPOLICY_FILENAME="policy.${SELINUX_VERSION}"

MLS_NUM_SENS=1
MLS_NUM_CATS=1024
CHROME_POLICY_FILES_PATTERN=(
	security_classes
	initial_sids
	access_vectors
	global_macros
	chromeos_macros
	neverallow_macros
	mls_macros
	mls_decl
	mls
	policy_capabilities
	te_macros
	attributes
	ioctl_defines
	ioctl_macros
	"*.te"
	roles_decl
	roles
	users
	initial_sid_contexts
	fs_use
	genfs_contexts
)

# Files under $SEPATH are built by android-container-* in DEPEND.
SEPATH="${SYSROOT}/etc/selinux/intermediates/"

# -M Build MLS policy.
# -G expand and remove auto-generated attributes.
# -N ignore neverallow rules (checked during Android build)
# -m allow multiple declaration (combination of rules of multiple source)
SECILC_ARGS=(
	-M true -G -N -m
	-c "${SELINUX_VERSION}"
	-o "${SEPOLICY_FILENAME}"
	-f /dev/null
)

SECILC_ARGS_CHECK_NEVERALLOW=(
	-M true -G -m
	-c "${SELINUX_VERSION}"
	-o /dev/null
	-f /dev/null
)

# Common flags for m4
M4_COMMON_FLAGS=(
)

# Remove all lines existed in $1 from /dev/stdin.
# and remove all lines begin with "^;" (cil comment)
# remove cil comment is necessary for clearing unmatched line marker
# after base policy definitions are removed.
# Also preserve type definitions since secilc can handle duplicates on
# definition of types.
filter_file_line_by_line() {
	perl -e '
		my @reflines;
		open(my $ref, "<", $ARGV[0]);
		while(<$ref>) { push @reflines, $_; }
		while(<STDIN>) {
			if ( m/^\(type / ) { print; next; }
			if ( m/^;/ ) { next; }
			if ($_ ~~ @reflines) { next; }
			print
		}
	' "$1"
}

# Quick hack for conflicting generated base_typeattr_XX with
# non-versioned Android cil.
# A better solution could be to use libsepol to parse and process
# cil to modify it.
version_cil() {
	sed -e 's/base_typeattr_\([0-9]*\)/base_typeattr_cros_\1/g'
}

has_arc() {
	use android-container-qt || use android-container-pi || use android-container-master-arc-dev
}

gen_m4_flags() {
	M4_COMMON_FLAGS=()
	local arc_version="none"
	if use android-container-qt; then
		arc_version="q"
	elif use android-container-pi; then
		arc_version="p"
	elif use android-container-master-arc-dev; then
		arc_version="master"
	fi
	M4_COMMON_FLAGS+=(
		"-Darc_version=${arc_version}"
		"-Duse_selinux_develop=$(usex selinux_develop y n)"
		"-Duse_arc_first_release_n=$(usex arc_first_release_n y n)"
	)
	einfo "m4 flags: ${M4_COMMON_FLAGS[*]}"
}

# Build SELinux intermediate language files.
# Look into SELinux policies in given directories, and
# pre-compile with m4 macro preprocessor, and merge them into
# a monothilic SELinux policy, and then compile it into
# intermediate files using checkpolicy compiler.
build_cil() {
	local policy_files=()
	local ciltype="$1"
	shift
	local output="$1"
	shift
	local pattern
	for pattern in "${CHROME_POLICY_FILES_PATTERN[@]}"; do
		local path
		for path in "$@"; do
			local file
			while read -r -d $'\0' file; do
				policy_files+=("${file}")
			done < <(find "${path}" -xtype f -name "${pattern}" -print0)
		done
	done
	m4 "-Dmls_num_sens=${MLS_NUM_SENS}" "-Dmls_num_cats=${MLS_NUM_CATS}" \
		"${M4_COMMON_FLAGS[@]}" \
		"-Dciltype=${ciltype}" \
		-s "${policy_files[@]}" > "${output}.conf" \
		|| die "failed to generate ${output}.conf"
	checkpolicy -M -C -c "${SELINUX_VERSION}" "${output}.conf" \
		-o "${output}" || die "failed to build $output"
}

build_android_reqd_cil() {
	build_cil reqd "android_reqd.cil" "sepolicy/policy/base/" "sepolicy/policy/mask_only/"
}

build_chromeos_policy() {
	build_android_reqd_cil

	build_cil cros "chromeos.raw.cil" "sepolicy/policy/base/" "sepolicy/policy/chromeos_base" "sepolicy/policy/chromeos/"
	version_cil < chromeos.raw.cil > chromeos.raw.versioned.cil
	secilc "${SECILC_ARGS_CHECK_NEVERALLOW[@]}" chromeos.raw.cil ||
		die "some Chrome OS neverallows are not satisfied"
	filter_file_line_by_line android_reqd.cil < chromeos.raw.versioned.cil > chromeos.cil ||
		die "failed to convert raw cil to filtered cil"
}

build_file_contexts() {
	einfo "Compiling chromeos_file_contexts"
	m4 "${M4_COMMON_FLAGS[@]}" "sepolicy/file_contexts/macros" \
		"sepolicy/file_contexts/chromeos_file_contexts" > chromeos_file_contexts ||
		die "failed to build chromeos file contexts"
}

check_filetrans_defined_in_file_contexts() {
	einfo "Verifying policy and file_contexts for filetrans_pattern"
	_is_empty() {
		local err=0
		while read line; do
			if [[ "$err" -eq "0" ]]; then
				ewarn "Expected to find these lines in file_contexts, but were not found:"
				err=1
			fi
			ewarn "$line"
		done
		return $err
	}
	# filetrans is a kind of typetransition. Typetrasition is described like
	# the following in a .cil file:
	# (typetransition source target class new_type) or
	# (typetransition source target class object_name new_type)
	# We only want to verify where
	#  - both source and target are not tmpfs-related.
	#  - source is not unconfined domain: chromeos
	#  - type is not process since we only care file typetransition.
	cat chromeos.cil | awk '
		/^\(typetransition/	{
						context=substr($NF,0,length($NF)-1)
						if ($4=="process"||$2=="chromeos") next;
						if(context ~/cros_.*tmp_file/) next; # Created an cros_.*_tmp_file
						if(context ~/(device|rootfs|tmpfs)/) next; # Created a file labeled as device, tmpfs, or rootfs.
						if($3 ~/^(cros_run(_.*)?|cros_.*tmp_file|tmpfs|arc_dir)$/) next; # Create a file in tmpfs.
						if(NF==6) { print substr($5,2,length($5)-2) ".*u:object_r:" context ":s0" }
						else { print "u:object_r:" context ":s0" }
					}
	' | sort -u | xargs -d'\n' -n 1 sh -c 'grep $0 file_contexts >/dev/null || echo $0' | _is_empty
}

# cat cil-file | get_attributed_type(attribute) => types separated by spaces
get_attributed_type() {
	local attr="$1"
	grep "(typeattributeset ${attr} (" | sed -e "s/^(typeattributeset ${attr} (//g" | sed -e 's/ ))$//g'
}

# check_attribute_include attr subattr1 subattr2 subattr3 ... excluded_type1 excluded_type2 ...
check_attribute_include() {
	local poolname="$1"
	shift 1
	einfo "Checking type set (attribute ${poolname}) equals to union of type sets of (attribute $@)"
	local pool="$(cat chromeos.cil | get_attributed_type "${poolname}" | tr ' ' '\n')"
	local remaining_types="$pool"
	for attr in $@; do
		remaining_types="$(echo "$remaining_types" | egrep -v "^$attr$")"
		for t in `cat chromeos.cil | get_attributed_type "${attr}"`; do
			if ! grep "$t" <(echo "$pool") >/dev/null; then
				die "${t} type should have attribute ${poolname} to have attribute ${attr}"
			fi
			remaining_types="$(echo "$remaining_types" | egrep -v "^$t$")"
		done
	done
	if ! [[ -z "$remaining_types" ]]; then
		die "Types with attribute $poolname should have at least one of $@, but these doesn't: \n$(echo "${remaining_types}" | tr '\n' ' ')"
	fi
}

check_file_type_and_attribute() {
	einfo "Checking file types and their attributes"
	check_attribute_include file_type cros_file_type unlabeled system_data_file media_data_file android_file_type
	check_attribute_include cros_file_type cros_system_file_type cros_tmpfile_type cros_home_file_type cros_var_file_type cros_run_file_type cros_uncategorized_file_type
}

src_compile() {
	gen_m4_flags

	build_chromeos_policy
	build_file_contexts

	cp -r "${SEPATH}" intermediate_policy

	if use selinux_audit_all; then
		find intermediate_policy/ -xtype f -name '*.cil' -exec \
			sed -i 's/^(dontaudit .*//g' {} \;
		sed -i 's/^(dontaudit .*//g' chromeos.cil
		sed -i 's/^(dontaudit .*//g' chromeos.raw.cil
	fi

	local cilpath="$(pwd)/intermediate_policy"

	if has_arc; then
		if use combine_chromeos_policy; then
			einfo "Removing duplicate nnp_nosuid_transition policycap from Android cil"
			sed -i '/^(policycap nnp_nosuid_transition)$/d' "${cilpath}"/*.cil || die

			einfo "Combining Chrome OS and Android SELinux policy"
			secilc "${SECILC_ARGS[@]}" "${cilpath}/plat_sepolicy.cil" \
				"${cilpath}/mapping.cil" \
				"${cilpath}/plat_pub_versioned.cil" \
				"${cilpath}/vendor_sepolicy.cil" \
				chromeos.cil || die "fail to build sepolicy"
		else
			einfo "use ARC++ policy"

			secilc "${SECILC_ARGS[@]}" "${cilpath}/plat_sepolicy.cil" \
				"${cilpath}/mapping.cil" \
				"${cilpath}/plat_pub_versioned.cil" \
				"${cilpath}/vendor_sepolicy.cil" || die "fail to build sepolicy"
		fi

		# Add header/footer around ARC++ contexts, so they can be
		# correctly replaced when pushing new Android builds using
		# push_to_device.py.
		(
			cat "chromeos_file_contexts" &&
			echo -e "\n# BEGIN_ARC_FILE_CONTEXTS" &&
			cat "${SYSROOT}/etc/selinux/intermediates/arc_file_contexts" &&
			echo -e "\n# END_ARC_FILE_CONTEXTS"
		) > file_contexts || die "failed to combine *_file_contexts files"

	else
		# Chrome OS without ARC++ only. Chrome OS with Android N doesn't
		# fall here. Chrome OS with Android N currently has Android
		# policy only.
		einfo "Use Chrome OS-only SELinux policy."

		secilc "${SECILC_ARGS[@]}" chromeos.raw.cil || die "fail to build sepolicy"
		cp "chromeos_file_contexts" file_contexts \
			|| die "didn't find chromeos_file_contexts for file_contexts"
	fi

	check_filetrans_defined_in_file_contexts \
		|| die "failed to check consistency between filetrans_pattern and file_contexts"

	if use nocheck; then
		ewarn "Some post-compile checks are skipped. Please remove nocheck from your USE flag"
	else
		einfo 'Use USE="$USE nocheck" emerge-$BOARD selinux-policy to speed up emerge for development purpose'.
		check_file_type_and_attribute
	fi
}

src_install() {
	insinto /etc/selinux/arc/contexts/files
	doins file_contexts

	insinto /etc/selinux
	if use selinux_experimental; then
		newins "${FILESDIR}/selinux_config_experimental" config
	else
		newins "${FILESDIR}/selinux_config" config
	fi

	insinto /etc/selinux/arc/policy
	doins "${SEPOLICY_FILENAME}"

	if use selinux_develop; then
		insinto /etc/init
		doins "${FILESDIR}/selinux_debug.conf"
		dobin "${FILESDIR}/audit_log_since_boot"
	fi

	if has_arc; then
		# Install ChromeOS cil so push_to_device.py can compile a new
		# version of SELinux policy.
		insinto /etc/selinux/intermediates.raw/
		doins chromeos.cil
	fi

	udev_dorules "${FILESDIR}/50-selinux.rules"
}

src_test() {
	local neverallowjava="${SYSROOT}/etc/selinux/intermediates/SELinuxNeverallowRulesTest.java"
	if [ ! -f "${SYSROOT}/etc/selinux/intermediates/SELinuxNeverallowRulesTest.java" ]; then
		ewarn "No SELinuxNeverallowRulesTest.java found. CTS neverallow pre-test is skipped."
		return
	fi
	if use android-container-master-arc-dev; then
		ewarn "master-arc-dev is known to include policies that breaks CTS neverallow rules."
		ewarn "search arc_cts_fails_release in platform2/sepolicy for more details."
		ewarn "CTS pre-test is skipped."
		return
	fi
	(
		grep "boolean compatiblePropertyOnly = false;" -B 2 |
		grep "boolean fullTrebleOnly = false;" -B 1 |
		grep neverallowRule |
		sed -E 's/.*"(neverallow.*)";/\1/g'
	) < "${neverallowjava}" > neverallows
	local loc="$(wc -l neverallows | awk '{print $1;}')"
	if [[ "${loc}" -lt "100" ]]; then
		die "too few test cases. something is wrong."
	fi
	local cur=0
	while read -r rule; do
		cur=$((cur+1))
		printf "Checking neverallow rules: %d/%d\r" "$cur" "$loc"
		sepolicy-analyze "${SEPOLICY_FILENAME}" neverallow -n "$rule" || (echo failed for "$rule"; die)
	done < neverallows
}
