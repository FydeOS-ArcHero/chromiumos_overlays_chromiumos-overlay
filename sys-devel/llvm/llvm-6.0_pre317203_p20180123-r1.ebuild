# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

: ${CMAKE_MAKEFILE_GENERATOR:=ninja}
PYTHON_COMPAT=( python2_7 )

inherit  cros-constants check-reqs cmake-utils eutils flag-o-matic git-2 git-r3 \
	multilib multilib-minimal python-single-r1 toolchain-funcs pax-utils

DESCRIPTION="Low Level Virtual Machine"
HOMEPAGE="http://llvm.org/"
SRC_URI=""
EGIT_REPO_URI="http://llvm.org/git/llvm.git
	https://github.com/llvm-mirror/llvm.git"
LICENSE="UoI-NCSA"

# For this version of the ebuild, llvm and llvm-next are the same. We need to roll
# a new llvm-next.
if use llvm-next; then

# llvm:r321490 https://critique.corp.google.com/#review/181250307
EGIT_REPO_URIS=(
	"llvm"
		""
		"${CROS_GIT_HOST_URL}/chromiumos/third_party/llvm.git"
		"7e6fcc775f56cdeeae061f6f8071f5c103087330" # EGIT_COMMIT r321490
	"compiler-rt"
		"projects/compiler-rt"
		"${CROS_GIT_HOST_URL}/chromiumos/third_party/compiler-rt.git"
		"3bd6c8e44cf530bbf8c0e57b571f4bfc7d48b698" # EGIT_COMMIT r321485
	"clang"
		"tools/clang"
		"${CROS_GIT_HOST_URL}/chromiumos/third_party/clang.git"
		"7e0bf617fb110ad1e246f7cb09e20e293d3b429e"  # EGIT_COMMIT r321487
	"clang-tidy"
		"tools/clang/tools/extra"
		"https://git.llvm.org/git/clang-tools-extra.git"
		"057470116210d2e6bf5e726361e641c8c5de9b35" # EGIT_COMMIT r321412
)
else
# llvm:r317203 https://critique.corp.google.com/#review/175206381
EGIT_REPO_URIS=(
	"llvm"
		""
		"${CROS_GIT_HOST_URL}/chromiumos/third_party/llvm.git"
		"66af8bde13a515b8d0fa76201f0d5b428187fd13" # EGIT_COMMIT r317203
	"compiler-rt"
		"projects/compiler-rt"
		"${CROS_GIT_HOST_URL}/chromiumos/third_party/compiler-rt.git"
		"bcc227ee4af1ef3e63033b35dcb1d5627a3b2941" # EGIT_COMMIT r317186
	"clang"
		"tools/clang"
		"${CROS_GIT_HOST_URL}/chromiumos/third_party/clang.git"
		"4d085086c74a8fbce197f61548f488a63f300933"  # EGIT_COMMIT r317200
	"clang-tidy"
		"tools/clang/tools/extra"
		"https://git.llvm.org/git/clang-tools-extra.git"
		"47651f3221d4ae4d2fcc274f7730e1ac853d86b8" # EGIT_COMMIT r316094
)
fi

LICENSE="UoI-NCSA"
SLOT="0/${PV%%_*}"
KEYWORDS="-* amd64"
IUSE="clang debug +default-compiler-rt +default-libcxx doc gold libedit +libffi
	lldb multitarget ncurses ocaml python +static-analyzer llvm-next llvm-tot
	test xml video_cards_radeon kernel_Darwin"

COMMON_DEPEND="
	sys-libs/zlib:0=
	clang? (
		static-analyzer? ( dev-lang/perl:* )
		xml? ( dev-libs/libxml2:2=[${MULTILIB_USEDEP}] )
		${PYTHON_DEPS}
	)
	gold? ( >=sys-devel/binutils-2.22:*[cxx] )
	libedit? ( dev-libs/libedit:0=[${MULTILIB_USEDEP}] )
	libffi? ( >=virtual/libffi-3.0.13-r1:0=[${MULTILIB_USEDEP}] )
	ncurses? ( >=sys-libs/ncurses-5.9-r3:5=[${MULTILIB_USEDEP}] )
	ocaml? (
		>=dev-lang/ocaml-4.00.0:0=
		dev-ml/findlib
		dev-ml/ocaml-ctypes )"
# configparser-3.2 breaks the build (3.3 or none at all are fine)
DEPEND="${COMMON_DEPEND}
	dev-lang/perl
	>=sys-devel/make-3.81
	>=sys-devel/flex-2.5.4
	>=sys-devel/bison-1.875d
	|| ( >=sys-devel/gcc-3.0 >=sys-devel/llvm-3.5
		( >=sys-freebsd/freebsd-lib-9.1-r10 sys-libs/libcxx )
	)
	|| ( >=sys-devel/binutils-2.18 >=sys-devel/binutils-apple-5.1 )
	kernel_Darwin? ( sys-libs/libcxx )
	clang? ( xml? ( virtual/pkgconfig ) )
	doc? ( dev-python/sphinx )
	gold? ( sys-libs/binutils-libs )
	libffi? ( virtual/pkgconfig )
	lldb? ( dev-lang/swig )
	!!<dev-python/configparser-3.3.0.2
	ocaml? ( test? ( dev-ml/ounit ) )
	${PYTHON_DEPS}"
RDEPEND="${COMMON_DEPEND}
	clang? ( !<=sys-devel/clang-${PV}-r99 )
	abi_x86_32? ( !<=app-emulation/emul-linux-x86-baselibs-20130224-r2
		!app-emulation/emul-linux-x86-baselibs[-abi_x86_32(-)] )"
PDEPEND="clang? ( =sys-devel/clang-${PV}-r100 )"

# pypy gives me around 1700 unresolved tests due to open file limit
# being exceeded. probably GC does not close them fast enough.
REQUIRED_USE="${PYTHON_REQUIRED_USE}
	lldb? ( clang xml )"

pkg_pretend() {
	# in megs
	# !clang !debug !multitarget -O2       400
	# !clang !debug  multitarget -O2       550
	#  clang !debug !multitarget -O2       950
	#  clang !debug  multitarget -O2      1200
	# !clang  debug  multitarget -O2      5G
	#  clang !debug  multitarget -O0 -g  12G
	#  clang  debug  multitarget -O2     16G
	#  clang  debug  multitarget -O0 -g  14G

	local build_size=550
	use clang && build_size=1200

	if use debug; then
		ewarn "USE=debug is known to increase the size of package considerably"
		ewarn "and cause the tests to fail."
		ewarn

		(( build_size *= 14 ))
	elif is-flagq '-g?(gdb)?([1-9])'; then
		ewarn "The C++ compiler -g option is known to increase the size of the package"
		ewarn "considerably. If you run out of space, please consider removing it."
		ewarn

		(( build_size *= 10 ))
	fi

	# Multiply by number of ABIs :).
	local abis=( $(multilib_get_enabled_abis) )
	(( build_size *= ${#abis[@]} ))

	local CHECKREQS_DISK_BUILD=${build_size}M
	check-reqs_pkg_pretend

	if [[ ${MERGE_TYPE} != binary ]]; then
		echo 'int main() {return 0;}' > "${T}"/test.cxx || die
		ebegin "Trying to build a C++11 test program"
		if ! $(tc-getCXX) -std=c++11 -o /dev/null "${T}"/test.cxx; then
			eerror "LLVM-${PV} requires C++11-capable C++ compiler. Your current compiler"
			eerror "does not seem to support -std=c++11 option. Please upgrade your compiler"
			eerror "to gcc-4.7 or an equivalent version supporting C++11."
			die "Currently active compiler does not support -std=c++11"
		fi
		eend ${?}
	fi
}

pkg_setup() {
	pkg_pretend
}

trunk_src_unpack() {
	git-r3_fetch "http://llvm.org/git/compiler-rt.git
		https://github.com/llvm-mirror/compiler-rt.git"
	git-r3_fetch "http://llvm.org/git/clang.git
		https://github.com/llvm-mirror/clang.git"
	git-r3_fetch "http://llvm.org/git/clang-tools-extra.git
		https://github.com/llvm-mirror/clang-tools-extra.git"
	git-r3_fetch

	git-r3_checkout http://llvm.org/git/compiler-rt.git \
		"${S}"/projects/compiler-rt
	git-r3_checkout http://llvm.org/git/clang.git \
		"${S}"/tools/clang
	git-r3_checkout http://llvm.org/git/clang-tools-extra.git \
		"${S}"/tools/clang/tools/extra
	git-r3_checkout
}

src_unpack() {
	if use llvm-tot ; then
		trunk_src_unpack
		return
	fi
	set -- "${EGIT_REPO_URIS[@]}"
		while [[ $# -gt 0 ]]; do
			ESVN_PROJECT=$1 \
			EGIT_SOURCEDIR="${S}/$2" \
			EGIT_REPO_URI=$3 \
			EGIT_COMMIT=$4 \
			git-2_src_unpack
			shift 4
		done
}

pick_cherries() {
	# clang
	local CHERRIES=""
	pushd "${S}"/tools/clang >/dev/null || die
	for cherry in ${CHERRIES}; do
		epatch "${FILESDIR}/cherry/${cherry}.patch"
	done
	popd >/dev/null || die

	# llvm
	CHERRIES=""
	CHERRIES+=" f1cb8efedeb65da55ff87449a6c83ad7e839b090 " # r320764
	pushd "${S}" >/dev/null || die
	for cherry in ${CHERRIES}; do
		epatch "${FILESDIR}/cherry/${cherry}.patch"
	done
	popd >/dev/null || die

	# compiler-rt
	CHERRIES=""
	pushd "${S}"/projects/compiler-rt >/dev/null || die
	for cherry in ${CHERRIES}; do
		epatch "${FILESDIR}/cherry/${cherry}.patch"
	done
	popd >/dev/null || die
}

pick_next_cherries() {
	# clang
	local CHERRIES=""
	CHERRIES+=" 0d816739a82da29748caf88570affb9715e18b69" # r323155
	pushd "${S}"/tools/clang >/dev/null || die
	for cherry in ${CHERRIES}; do
		epatch "${FILESDIR}/cherry/${cherry}.patch"
	done
	popd >/dev/null || die

	# llvm
	CHERRIES=""
	CHERRIES+=" fd5a8723ce9f2a6b250e85972ef859e4253ea95d" # r323155
	CHERRIES+=" 1e7ad1c95ade6d20d3e0544772e55e45d2e6edb9" # r321510
	pushd "${S}" >/dev/null || die
	for cherry in ${CHERRIES}; do
		epatch "${FILESDIR}/cherry/${cherry}.patch"
	done
	popd >/dev/null || die

	# compiler-rt
	CHERRIES=""
	pushd "${S}"/projects/compiler-rt >/dev/null || die
	for cherry in ${CHERRIES}; do
		epatch "${FILESDIR}/cherry/${cherry}.patch"
	done
	popd >/dev/null || die
}

src_prepare() {
	if ! use llvm-tot ; then
		use llvm-next || pick_cherries
		use llvm-next && pick_next_cherries
	fi
	epatch "${FILESDIR}"/llvm-6.0-gnueabihf.patch
	epatch "${FILESDIR}"/llvm-next-leak-whitelist.patch
	epatch "${FILESDIR}"/clang-4.0-asan-default-path.patch

	# Make ocaml warnings non-fatal, bug #537308
	sed -e "/RUN/s/-warn-error A//" -i test/Bindings/OCaml/*ml  || die

	# Allow custom cmake build types (like 'Gentoo')
	epatch "${FILESDIR}"/cmake/${PN}-3.8-allow_custom_cmake_build_types.patch

	# crbug/591436
	epatch "${FILESDIR}"/clang-executable-detection.patch

	# crbug/606391
	epatch "${FILESDIR}"/${PN}-3.8-invocation.patch

	epatch "${FILESDIR}"/llvm-3.9-dwarf-version.patch

	# Link libgcc_eh when using compiler-rt as default rtlib.
	# https://llvm.org/bugs/show_bug.cgi?id=28681
	epatch "${FILESDIR}"/clang-6.0-enable-libgcc-with-compiler-rt.patch

	if use clang; then
		# Automatically select active system GCC's libraries, bugs #406163 and #417913
		epatch "${FILESDIR}"/clang-3.5-gentoo-runtime-gcc-detection-v3.patch

		# Install clang runtime into /usr/lib/clang
		# https://llvm.org/bugs/show_bug.cgi?id=23792
		epatch "${FILESDIR}"/cmake/clang-0001-Install-clang-runtime-into-usr-lib-without-suffix-3.8.patch
		epatch "${FILESDIR}"/cmake/compiler-rt-0001-cmake-Install-compiler-rt-into-usr-lib-without-suffi.patch

		# Make it possible to override CLANG_LIBDIR_SUFFIX
		# (that is used only to find LLVMgold.so)
		# https://llvm.org/bugs/show_bug.cgi?id=23793
		epatch "${FILESDIR}"/cmake/clang-0002-cmake-Make-CLANG_LIBDIR_SUFFIX-overridable.patch

		# Fix WX sections, bug #421527
		find "${S}"/projects/compiler-rt/lib/builtins -type f -name \*.S -exec sed \
			-e '$a\\n#if defined(__linux__) && defined(__ELF__)\n.section .note.GNU-stack,"",%progbits\n#endif' \
			-i {} \; || die
	fi

	if use lldb; then
		# Do not install dummy readline.so module from
		# https://llvm.org/bugs/show_bug.cgi?id=18841
		sed -e 's/add_subdirectory(readline)/#&/' \
			-i tools/lldb/scripts/Python/modules/CMakeLists.txt || die
	fi

	python_setup

	# User patches
	epatch_user

	# Native libdir is used to hold LLVMgold.so
	NATIVE_LIBDIR=$(get_libdir)
}

enable_asserts() {
	# Enable assertions for llvm-next build
	if use llvm-next || use llvm-tot; then
		echo yes
	else
		usex debug
	fi
}

multilib_src_configure() {
	local targets
	if use multitarget; then
		targets=all
	else
		targets='host;CppBackend'
		use video_cards_radeon && targets+=';AMDGPU'
	fi

	local ffi_cflags ffi_ldflags
	if use libffi; then
		ffi_cflags=$(pkg-config --cflags-only-I libffi)
		ffi_ldflags=$(pkg-config --libs-only-L libffi)
	fi

	local libdir=$(get_libdir)
	local mycmakeargs=(
		"${mycmakeargs[@]}"
		-DLLVM_LIBDIR_SUFFIX=${libdir#lib}

		-DLLVM_BUILD_LLVM_DYLIB=ON
		-DLLVM_LINK_LLVM_DYLIB=ON
		-DLLVM_ENABLE_TIMESTAMPS=OFF
		-DLLVM_TARGETS_TO_BUILD="${targets}"
		-DLLVM_BUILD_TESTS=$(usex test)

		-DLLVM_ENABLE_FFI=$(usex libffi)
		-DLLVM_ENABLE_TERMINFO=$(usex ncurses)
		-DLLVM_ENABLE_ASSERTIONS=$(enable_asserts)
		-DLLVM_ENABLE_EH=ON
		-DLLVM_ENABLE_RTTI=ON

		-DWITH_POLLY=OFF # TODO

		-DLLVM_HOST_TRIPLE="${CHOST}"

		-DFFI_INCLUDE_DIR="${ffi_cflags#-I}"
		-DFFI_LIBRARY_DIR="${ffi_ldflags#-L}"
		-DLLVM_BINUTILS_INCDIR="${SYSROOT}"/usr/include

		-DHAVE_HISTEDIT_H=$(usex libedit)
		-DENABLE_LINKER_BUILD_ID=ON
		-DCLANG_VENDOR="Chromium OS ${PVR}"
		# override default stdlib and rtlib
		-DCLANG_DEFAULT_CXX_STDLIB=$(usex default-libcxx libc++ "")
		-DCLANG_DEFAULT_RTLIB=$(usex default-compiler-rt compiler-rt "")
	)

	if use clang; then
		mycmakeargs+=(
			-DCMAKE_DISABLE_FIND_PACKAGE_LibXml2=$(usex !xml)
			# libgomp support fails to find headers without explicit -I
			# furthermore, it provides only syntax checking
			-DCLANG_DEFAULT_OPENMP_RUNTIME=libomp
		)
	fi

	if use lldb; then
		mycmakeargs+=(
			-DLLDB_DISABLE_LIBEDIT=$(usex !libedit)
			-DLLDB_DISABLE_CURSES=$(usex !ncurses)
			-DLLDB_ENABLE_TERMINFO=$(usex ncurses)
		)
	fi

	if ! multilib_is_native_abi || ! use ocaml; then
		mycmakeargs+=(
			-DOCAMLFIND=NO
		)
	fi
#	Note: go bindings have no CMake rules at the moment
#	but let's kill the check in case they are introduced
#	if ! multilib_is_native_abi || ! use go; then
		mycmakeargs+=(
			-DGO_EXECUTABLE=GO_EXECUTABLE-NOTFOUND
		)
#	fi

	if multilib_is_native_abi; then
		mycmakeargs+=(
			-DLLVM_BUILD_DOCS=$(usex doc)
			-DLLVM_ENABLE_SPHINX=$(usex doc)
			-DLLVM_ENABLE_DOXYGEN=OFF
			-DLLVM_INSTALL_HTML="${EPREFIX}/usr/share/doc/${PF}/html"
			-DSPHINX_WARNINGS_AS_ERRORS=OFF
			-DLLVM_INSTALL_UTILS=ON
		)

		if use clang; then
			mycmakeargs+=(
				-DCLANG_INSTALL_HTML="${EPREFIX}/usr/share/doc/${PF}/clang"
			)
		fi

		if use gold; then
			mycmakeargs+=(
				-DLLVM_BINUTILS_INCDIR="${EPREFIX}"/usr/include
			)
		fi

		if use lldb; then
			mycmakeargs+=(
				-DLLDB_DISABLE_PYTHON=$(usex !python)
			)
		fi

	else
		if use clang; then
			mycmakeargs+=(
				# disable compiler-rt on non-native ABI because:
				# 1. it fails to configure because of -m32
				# 2. it is shared between ABIs so no point building
				# it multiple times
				-DLLVM_EXTERNAL_COMPILER_RT_BUILD=OFF
				-DLLVM_EXTERNAL_CLANG_TOOLS_EXTRA_BUILD=OFF
			)
		fi
		if use lldb; then
			mycmakeargs+=(
				# only run swig on native abi
				-DLLDB_DISABLE_PYTHON=ON
			)
		fi
	fi

	if use clang; then
		mycmakeargs+=(
			-DCLANG_ENABLE_ARCMT=$(usex static-analyzer)
			-DCLANG_ENABLE_STATIC_ANALYZER=$(usex static-analyzer)
			-DCLANG_LIBDIR_SUFFIX="${NATIVE_LIBDIR#lib}"
		)

		# -- not needed when compiler-rt is built with host compiler --
		# cmake passes host C*FLAGS to compiler-rt build
		# which is performed using clang, so we need to filter out
		# some flags clang does not support
		# (if you know some more flags that don't work, let us know)
		#filter-flags -msahf -frecord-gcc-switches
	fi

	cmake-utils_src_configure
}

multilib_src_compile() {
	cmake-utils_src_compile
	# TODO: not sure why this target is not correctly called
	multilib_is_native_abi && use doc && use ocaml && cmake-utils_src_make docs/ocaml_doc

	pax-mark m "${BUILD_DIR}"/bin/llvm-rtdyld
	pax-mark m "${BUILD_DIR}"/bin/lli
	pax-mark m "${BUILD_DIR}"/bin/lli-child-target

	if use test; then
		pax-mark m "${BUILD_DIR}"/unittests/ExecutionEngine/Orc/OrcJITTests
		pax-mark m "${BUILD_DIR}"/unittests/ExecutionEngine/MCJIT/MCJITTests
		pax-mark m "${BUILD_DIR}"/unittests/Support/SupportTests
	fi
}

multilib_src_test() {
	# respect TMPDIR!
	local -x LIT_PRESERVES_TMP=1
	local test_targets=( check )
	# clang tests won't work on non-native ABI because we skip compiler-rt
	multilib_is_native_abi && use clang && test_targets+=( check-clang )
	cmake-utils_src_make "${test_targets[@]}"
}

src_install() {
	local MULTILIB_CHOST_TOOLS=(
		/usr/bin/llvm-config
	)

	local MULTILIB_WRAPPED_HEADERS=(
		/usr/include/llvm/Config/config.h
		/usr/include/llvm/Config/llvm-config.h
	)

	if use clang; then
		# note: magic applied in multilib_src_install()!
		CLANG_VERSION=3.8

		MULTILIB_CHOST_TOOLS+=(
			/usr/bin/clang
			/usr/bin/clang++
			/usr/bin/clang-cl
			/usr/bin/clang-${CLANG_VERSION}
			/usr/bin/clang++-${CLANG_VERSION}
			/usr/bin/clang-cl-${CLANG_VERSION}
		)

		MULTILIB_WRAPPED_HEADERS+=(
			/usr/include/clang/Config/config.h
		)
	fi

	multilib-minimal_src_install
}

multilib_src_install() {
	cmake-utils_src_install

	if multilib_is_native_abi; then
		# Install docs.
		#use doc && dohtml -r "${S}"/docs/_build/html/

		# Symlink the gold plugin.
		if use gold; then
			dodir "/usr/${CHOST}/binutils-bin/lib/bfd-plugins"
			dosym "../../../../$(get_libdir)/LLVMgold.so" \
				"/usr/${CHOST}/binutils-bin/lib/bfd-plugins/LLVMgold.so"
		fi
	fi

	# apply CHOST and CLANG_VERSION to clang executables
	# they're statically linked so we don't have to worry about the lib
	if use clang; then
		local clang_tools=( clang clang++ clang-cl )
		local i

		# cmake gives us:
		# - clang-X.Y
		# - clang -> clang-X.Y
		# - clang++, clang-cl -> clang
		# we want to have:
		# - clang-X.Y
		# - clang++-X.Y, clang-cl-X.Y -> clang-X.Y
		# - clang, clang++, clang-cl -> clang*-X.Y
		# so we need to fix the two tools
		for i in "${clang_tools[@]:1}"; do
			rm "${ED%/}/usr/bin/${i}" || die
			dosym "clang-${CLANG_VERSION}" "/usr/bin/${i}-${CLANG_VERSION}"
			dosym "${i}-${CLANG_VERSION}" "/usr/bin/${i}"
		done

		# now prepend ${CHOST} and let the multilib-build.eclass symlink it
		if ! multilib_is_native_abi; then
			# non-native? let's replace it with a simple wrapper
			for i in "${clang_tools[@]}"; do
				rm "${ED%/}/usr/bin/${i}-${CLANG_VERSION}" || die
				cat > "${T}"/wrapper.tmp <<-_EOF_
					#!${EPREFIX}/bin/sh
					exec "${i}-${CLANG_VERSION}" $(get_abi_CFLAGS) "\${@}"
				_EOF_
				newbin "${T}"/wrapper.tmp "${i}-${CLANG_VERSION}"
			done
		fi
	fi

	local wrapper_script=clang_host_wrapper
	cat "${FILESDIR}/clang_host_wrapper.header" \
		"${FILESDIR}/wrapper_script_common" \
		"${FILESDIR}/clang_host_wrapper.body" > \
		"${D}/usr/bin/${wrapper_script}" || die
	chmod 755 "${D}/usr/bin/${wrapper_script}" || die
	newbin "${D}/usr/bin/clang-tidy" "clang-tidy"
	dobin "${FILESDIR}/bisect_driver.py"
	exeinto "/usr/bin"
	dosym "${wrapper_script}" "/usr/bin/${CHOST}-clang"
	dosym "${wrapper_script}" "/usr/bin/${CHOST}-clang++"
}

multilib_src_install_all() {
	insinto /usr/share/vim/vimfiles
	doins -r utils/vim/*/.
	# some users may find it useful
	dodoc utils/vim/vimrc
	dobin "${S}/projects/compiler-rt/lib/asan/scripts/asan_symbolize.py"

	if use clang; then
		pushd tools/clang >/dev/null || die

		if use python ; then
			pushd bindings/python/clang >/dev/null || die

			python_moduleinto clang
			python_domodule *.py

			popd >/dev/null || die
		fi

		# AddressSanitizer symbolizer (currently separate)
		dobin "${S}"/projects/compiler-rt/lib/asan/scripts/asan_symbolize.py

		popd >/dev/null || die

		python_fix_shebang "${ED}"
		if use static-analyzer; then
			python_optimize "${ED}"usr/share/scan-view
		fi
	fi
}

pkg_postinst() {
	if use clang && ! has_version 'sys-libs/libomp'; then
		elog "To enable OpenMP support in clang, install sys-libs/libomp."
	fi
}
