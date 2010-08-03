# Copyright (c) 2010 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

#
# Original Author: The Chromium OS Authors <chromium-os-dev@chromium.org>
# Purpose: Eclass for handling autotest test packages
#

RDEPEND=">=chromeos-base/autotest-0.0.2"
DEPEND="${RDEPEND}"

IUSE="buildcheck"

# Ensure the configures run by autotest pick up the right config.site
export CONFIG_SITE=/usr/share/config.site

# Pythonify the list of packages
function pythonify_test_list() {
	local result

	# NOTE: shell-like commenting of individual tests using grep
	result=$(for test in ${AUTOTEST_TEST_LIST}; do echo "${test},"|grep -v "^#"; done)

	echo ${result}|sed  -e 's/ //g'
}

# Create python package init files for top level test case dirs.
function touch_init_py() {
	local dirs=${1}
	for base_dir in $dirs
	do
		local sub_dirs="$(find ${base_dir} -maxdepth 1 -type d)"
		for sub_dir in ${sub_dirs}
		do
			touch ${sub_dir}/__init__.py
		done
		touch ${base_dir}/__init__.py
	done
}

function setup_cross_toolchain() {
	if tc-is-cross-compiler ; then
		tc-export CC CXX AR RANLIB LD NM STRIP
		export PKG_CONFIG_PATH="${ROOT}/usr/lib/pkgconfig/"
		export CCFLAGS="$CFLAGS"
	fi

	# TODO(fes): Check for /etc/hardened for now instead of the hardened
	# use flag because we aren't enabling hardened on the target board.
	# Rather, right now we're using hardened only during toolchain compile.
	# Various tests/etc. use %ebx in here, so we have to turn off PIE when
	# using the hardened compiler
	if use x86 ; then
		if use hardened ; then
			#CC="${CC} -nopie"
			append-flags -nopie
		fi
	fi
}

function create_autotest_workdir() {
	local dst=${1}

	# create a working enviroment for pre-building
	ln -sf "${SYSROOT}"/usr/local/autotest/{conmux,tko,utils} "${dst}"/
	# NOTE: in order to make autotest not notice it's running from /usr/local/, we need
	# to make sure the binaries are real, because they do the path magic
	local root_path base_path
	for base_path in client client/bin; do
		root_path="${SYSROOT}/usr/local/autotest/${base_path}"
		mkdir -p "${dst}/${base_path}"

		# skip bin, because it is processed separately, and test-provided dirs
		for entry in $(ls "${root_path}" |grep -v "\(bin\|tests\|site_tests\|deps\|profilers\|config\)$"); do
			ln -sf "${root_path}/${entry}" "${dst}/${base_path}/"
		done
	done
	# replace the important binaries with real copies
	for base_path in autotest autotest_client; do
		root_path="${SYSROOT}/usr/local/autotest/client/bin/${base_path}"
		rm "${dst}/client/bin/${base_path}"
		cp -f ${root_path} "${dst}/client/bin/${base_path}"
	done
	
}

function print_test_dirs() {
	local testroot="${1}"

	pushd "${testroot}" 1> /dev/null
	for test in *; do
		if [ -d "${test}" ] && [ -f "${test}/${test}".py ]; then
			echo "${test}"
		fi
	done
	popd 1> /dev/null
}

function autotest_src_configure() {
	sed "/^enable_server_prebuild/d" "${AUTOTEST_SRC}/global_config.ini" > \
		"${S}/global_config.ini"

	touch_init_py client/tests client/site_tests
	touch __init__.py

	# Cleanup checked-in binaries that don't support the target architecture
	[[ ${E_MACHINE} == "" ]] && return 0;
	rm -fv $( scanelf -RmyBF%a . | grep -v -e ^${E_MACHINE} )
}

function autotest_src_compile() {
	setup_cross_toolchain

	if use opengles ; then
		graphics_backend=OPENGLES
	else
		graphics_backend=OPENGL
	fi

	TESTS=$(pythonify_test_list)
	einfo "Tests enabled: ${TESTS}"

	# Do not use sudo, it'll unset all your environment
	GRAPHICS_BACKEND="$graphics_backend" LOGNAME=${SUDO_USER} \
		client/bin/autotest_client --quiet --client_test_setup=${TESTS} \
		|| ! use buildcheck || die "Tests failed to build."

	# Cleanup some temp files after compiling
	find . -name '*.[ado]' -delete
}

function autotest_src_install() {
	insinto /usr/local/autotest/client/
	doins -r "${S}"/client/{tests,site_tests,deps,profilers,config}
	insinto /usr/local/autotest/server/
	doins -r "${S}"/server/{tests,site_tests}
}

EXPORT_FUNCTIONS src_configure src_compile src_install
