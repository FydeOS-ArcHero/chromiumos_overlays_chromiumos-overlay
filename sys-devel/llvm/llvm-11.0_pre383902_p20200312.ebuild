# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

: ${CMAKE_MAKEFILE_GENERATOR:=ninja}
PYTHON_COMPAT=( python3_6 )

inherit  cros-constants cmake-utils eutils flag-o-matic git-2 git-r3 \
	multilib multilib-minimal python-single-r1 toolchain-funcs pax-utils

LLVM_HASH="e21b39a86dd6e8d1a5a5fe7e0286f8570732834d" # r383902
LLVM_NEXT_HASH="e21b39a86dd6e8d1a5a5fe7e0286f8570732834d" # r383902

DESCRIPTION="Low Level Virtual Machine"
HOMEPAGE="http://llvm.org/"
SRC_URI="
	!llvm-tot? (
		!llvm-next? ( llvm_pgo_use? ( gs://chromeos-localmirror/distfiles/llvm-profdata-${LLVM_HASH}.tar.xz ) )
		llvm-next? ( llvm-next_pgo_use? ( gs://chromeos-localmirror/distfiles/llvm-profdata-${LLVM_NEXT_HASH}.tar.xz ) )
	)
"
EGIT_REPO_URI="${CROS_GIT_HOST_URL}/external/github.com/llvm/llvm-project"

LICENSE="UoI-NCSA"
SLOT="8"
KEYWORDS="-* amd64"
# FIXME: llvm-tot is somewhat misleading: at the moment, it's essentially
# llvm-next with a few extra checks enabled
IUSE="debug +default-compiler-rt +default-libcxx doc libedit +libffi +llvm-crt
	llvm-next llvm_pgo_generate llvm_pgo_use llvm-next_pgo_use llvm-tot
	multitarget ncurses ocaml python test +thinlto xml video_cards_radeon"

COMMON_DEPEND="
	sys-libs/zlib:0=
	libedit? ( dev-libs/libedit:0=[${MULTILIB_USEDEP}] )
	libffi? ( >=virtual/libffi-3.0.13-r1:0=[${MULTILIB_USEDEP}] )
	ncurses? ( >=sys-libs/ncurses-5.9-r3:0=[${MULTILIB_USEDEP}] )
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
	doc? ( dev-python/sphinx )
	libffi? ( virtual/pkgconfig )
	!!<dev-python/configparser-3.3.0.2
	ocaml? ( test? ( dev-ml/ounit ) )
	${PYTHON_DEPS}"
RDEPEND="${COMMON_DEPEND}
	abi_x86_32? ( !<=app-emulation/emul-linux-x86-baselibs-20130224-r2
		!app-emulation/emul-linux-x86-baselibs[-abi_x86_32(-)] )
	!<=sys-devel/llvm-8.0_pre
	!sys-devel/lld
	!sys-devel/clang"

# pypy gives me around 1700 unresolved tests due to open file limit
# being exceeded. probably GC does not close them fast enough.
REQUIRED_USE="
	${PYTHON_REQUIRED_USE}
	llvm_pgo_generate? ( !llvm_pgo_use )"

check_lld_works() {
	echo 'int main() {return 0;}' > "${T}"/lld.cxx || die
	echo "Trying to link program with lld"
	$(tc-getCXX) -fuse-ld=lld -std=c++11 -o /dev/null "${T}"/lld.cxx
}

apply_pgo_profile() {
	! use llvm-tot && ( \
		( use llvm-next && use llvm-next_pgo_use ) ||
		( ! use llvm-next && use llvm_pgo_use ) )
}

src_unpack() {
	export CMAKE_USE_DIR="${S}/llvm"

	local llvm_hash

	if use llvm-next || use llvm-tot; then
		llvm_hash="${LLVM_NEXT_HASH}"
	else
		llvm_hash="${LLVM_HASH}"
	fi

	# Don't unpack profdata file when calling git-2_src_unpack.
	EGIT_NOUNPACK=1

	# Unpack llvm
	ESVN_PROJECT="llvm"
	EGIT_COMMIT="${llvm_hash}"

	git-2_src_unpack

	if apply_pgo_profile; then
		cd "${WORKDIR}"
		local profile_hash
		if use llvm-next; then
			profile_hash="${LLVM_NEXT_HASH}"
		else
			profile_hash="${LLVM_HASH}"
		fi
		unpack "llvm-profdata-${profile_hash}.tar.xz"
	fi
	EGIT_NOUNPACK=
}

get_most_recent_revision() {
	local subdir="${S}/llvm"

	# Tries to get the revision ID of the most recent commit
	"${FILESDIR}"/patch_manager/git_llvm_rev.py --llvm_dir "${subdir}" --sha "$(git -C "${subdir}" rev-parse HEAD)" | cut -d 'r' -f 2
}

src_prepare() {
	# Make ocaml warnings non-fatal, bug #537308
	sed -e "/RUN/s/-warn-error A//" -i llvm/test/Bindings/OCaml/*ml  || die

	python_setup

	"${FILESDIR}"/patch_manager/patch_manager.py \
		--svn_version "$(get_most_recent_revision)" \
		--patch_metadata_file "${FILESDIR}"/PATCHES.json \
		--filesdir_path "${FILESDIR}" \
		--src_path "${S}" || die

	# User patches
	eapply_user

	# Native libdir is used to hold LLVMgold.so
	NATIVE_LIBDIR=$(get_libdir)
}

enable_asserts() {
	# keep asserts enabled for llvm-tot
	if use llvm-tot; then
		echo yes
	else
		usex debug
	fi
}

multilib_src_configure() {
	append-flags -Wno-poison-system-directories

	local targets
	if use multitarget; then
		targets='host;X86;ARM;AArch64;NVPTX'
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
		"-DLLVM_ENABLE_PROJECTS=llvm;clang;lld;compiler-rt;clang-tools-extra"
		"-DLLVM_LIBDIR_SUFFIX=${libdir#lib}"

		"-DLLVM_BUILD_LLVM_DYLIB=ON"
		# Link LLVM statically
		"-DLLVM_LINK_LLVM_DYLIB=OFF"

		"-DLLVM_ENABLE_TIMESTAMPS=OFF"
		"-DLLVM_TARGETS_TO_BUILD=${targets}"
		"-DLLVM_BUILD_TESTS=$(usex test)"

		"-DLLVM_ENABLE_FFI=$(usex libffi)"
		"-DLLVM_ENABLE_TERMINFO=$(usex ncurses)"
		"-DLLVM_ENABLE_ASSERTIONS=$(enable_asserts)"
		"-DLLVM_ENABLE_EH=ON"
		"-DLLVM_ENABLE_RTTI=ON"

		"-DWITH_POLLY=OFF" # TODO

		"-DLLVM_HOST_TRIPLE=${CHOST}"

		"-DFFI_INCLUDE_DIR=${ffi_cflags#-I}"
		"-DFFI_LIBRARY_DIR=${ffi_ldflags#-L}"
		"-DLLVM_BINUTILS_INCDIR=${SYSROOT}/usr/include"

		"-DHAVE_HISTEDIT_H=$(usex libedit)"
		"-DENABLE_LINKER_BUILD_ID=ON"
		"-DCLANG_VENDOR=Chromium OS ${PVR}"
		# override default stdlib and rtlib
		"-DCLANG_DEFAULT_CXX_STDLIB=$(usex default-libcxx libc++ "")"
		"-DCLANG_DEFAULT_RTLIB=$(usex default-compiler-rt compiler-rt "")"

		# Turn on new pass manager for LLVM
		"-DENABLE_EXPERIMENTAL_NEW_PASS_MANAGER=ON"

		# crbug/855759
		"-DCOMPILER_RT_BUILD_CRT=$(usex llvm-crt)"

		"-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
		"-DCLANG_DEFAULT_UNWINDLIB=libgcc"

		# By default do not enable PGO for compiler-rt
		"-DCOMPILER_RT_ENABLE_PGO=OFF"
	)

	# Update LLVM to 9.0 will cause LLVM to complain GCC
	# version is < 5.1. Add this flag to suppress the error.
	mycmakeargs+=(
		"-DLLVM_TEMPORARILY_ALLOW_OLD_TOOLCHAIN=1"
	)

	if check_lld_works; then
		mycmakeargs+=(
			# We use lld to link llvm, because:
			# 1) Gold has issue with no index for archive,
			# 2) Gold doesn't support instrumented compiler-rt well.
			"-DLLVM_USE_LINKER=lld"
		)
		# The standalone toolchain may be run at places not supporting
		# smallPIE, disabling it for lld.
		# Pass -fuse-ld=lld to make cmake happy.
		append-ldflags "-fuse-ld=lld -Wl,--pack-dyn-relocs=none"
		# Disable warning about profile not matching.
		append-flags "-Wno-backend-plugin"

		if use thinlto; then
			mycmakeargs+=(
				"-DLLVM_ENABLE_LTO=thin"
			)
		fi

		if apply_pgo_profile; then
			mycmakeargs+=(
				"-DLLVM_PROFDATA_FILE=${WORKDIR}/llvm.profdata"
			)
		fi

		if use llvm_pgo_generate; then
			mycmakeargs+=(
				"-DLLVM_BUILD_INSTRUMENTED=IR"
			)
		fi
	fi

	if ! multilib_is_native_abi || ! use ocaml; then
		mycmakeargs+=(
			"-DOCAMLFIND=NO"
		)
	fi
#	Note: go bindings have no CMake rules at the moment
#	but let's kill the check in case they are introduced
#	if ! multilib_is_native_abi || ! use go; then
		mycmakeargs+=(
			"-DGO_EXECUTABLE=GO_EXECUTABLE-NOTFOUND"
		)
#	fi

	if multilib_is_native_abi; then
		mycmakeargs+=(
			"-DLLVM_BUILD_DOCS=$(usex doc)"
			"-DLLVM_ENABLE_SPHINX=$(usex doc)"
			"-DLLVM_ENABLE_DOXYGEN=OFF"
			"-DLLVM_INSTALL_HTML=${EPREFIX}/usr/share/doc/${PF}/html"
			"-DSPHINX_WARNINGS_AS_ERRORS=OFF"
			"-DLLVM_INSTALL_UTILS=ON"
		)
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

	multilib-minimal_src_install
}

multilib_src_install() {
	cmake-utils_src_install

	local use_llvm_next=false
	if use llvm-next || use llvm-tot
	then
		use_llvm_next=true
	fi
	local wrapper_script=clang_host_wrapper

	"${FILESDIR}/compiler_wrapper/build.py" --config=cros.host --use_ccache=false \
		--use_llvm_next="${use_llvm_next}" \
		--output_file="${D}/usr/bin/${wrapper_script}" || die

	newbin "${D}/usr/bin/clang-tidy" "clang-tidy"
	dobin "${FILESDIR}/bisect_driver.py"
	exeinto "/usr/bin"
	dosym "${wrapper_script}" "/usr/bin/${CHOST}-clang"
	dosym "${wrapper_script}" "/usr/bin/${CHOST}-clang++"
	newexe "${FILESDIR}/ldwrapper_lld.host" "${CHOST}-ld.lld"
}

multilib_src_install_all() {
	insinto /usr/share/vim/vimfiles
	doins -r llvm/utils/vim/*/.
	# some users may find it useful
	dodoc llvm/utils/vim/vimrc
	dobin "${S}/compiler-rt/lib/asan/scripts/asan_symbolize.py"
}

pkg_postinst() {
	if has_version ">=dev-util/ccache-3.1.9-r2" ; then
		#add ccache links as clang might get installed after ccache
		"${EROOT}"/usr/bin/ccache-config --install-links
	fi
}

pkg_postrm() {
	if has_version ">=dev-util/ccache-3.1.9-r2" && [[ -z ${REPLACED_BY_VERSION} ]]; then
		# --remove-links would remove all links, --install-links updates them
		"${EROOT}"/usr/bin/ccache-config --install-links
	fi
}
