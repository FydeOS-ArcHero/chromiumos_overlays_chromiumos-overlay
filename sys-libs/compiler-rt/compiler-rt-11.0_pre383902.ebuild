# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit eutils toolchain-funcs cros-constants cmake-utils git-2 cros-llvm

EGIT_REPO_URI="${CROS_GIT_HOST_URL}/external/github.com/llvm/llvm-project"

LLVM_HASH="e21b39a86dd6e8d1a5a5fe7e0286f8570732834d" # r383902
LLVM_NEXT_HASH="e21b39a86dd6e8d1a5a5fe7e0286f8570732834d" # r383902

DESCRIPTION="Compiler runtime library for clang"
HOMEPAGE="http://compiler-rt.llvm.org/"

LICENSE="UoI-NCSA"
SLOT="0"
KEYWORDS="*"
IUSE="+llvm-crt llvm-next llvm-tot"
DEPEND="sys-devel/llvm"
if [[ ${CATEGORY} == cross-* ]] ; then
	DEPEND+="
		${CATEGORY}/binutils
		${CATEGORY}/gcc
		"
fi

pkg_setup() {
	export CMAKE_USE_DIR="${S}/compiler-rt"
}

src_unpack() {
	if use llvm-next || use llvm-tot; then
		export EGIT_COMMIT="${LLVM_NEXT_HASH}"
	else
		export EGIT_COMMIT="${LLVM_HASH}"
	fi
	git-2_src_unpack
}

src_prepare() {
	"${FILESDIR}"/patch_manager/patch_manager.py \
		--svn_version "$(get_most_recent_revision)" \
		--patch_metadata_file "${FILESDIR}"/PATCHES.json \
		--filesdir_path "${FILESDIR}" \
		--src_path "${S}" || die
	eapply_user
}

src_configure() {
	setup_cross_toolchain
	# Need libgcc for bootstrapping.
	append-flags "-rtlib=libgcc"
	# Compiler-rt libraries need to be built before libc++ when
	# libc++ is default in clang.
	# Compiler-rt builtins are C only.
	# Even though building compiler-rt libraries does not require C++ compiler,
	# CMake does not like a non-working C++ compiler.
	# Avoid CMake complains about non-working C++ compiler
	# by using libstdc++ since libc++ is built after compiler-rt in crossdev.
	append-cxxflags "-stdlib=libstdc++"
	append-flags "-fomit-frame-pointer"
	if [[ ${CTARGET} == armv7a* ]]; then
		# Use vfpv3 to be able to target non-neon targets
		append-flags -mfpu=vfpv3
	elif [[ ${CTARGET} == armv7m* ]]; then
		# Some of the arm32 assembly builtins in compiler-rt need vfpv2.
		# Passing this flag should not be required but currently
		# upstream compiler-rt's cmake config does not provide a way to
		# exclude these asm files.
		append-flags -Wa,-mfpu=vfpv2
	fi
	BUILD_DIR=${WORKDIR}/${P}_build

	local mycmakeargs=(
		"-DLLVM_ENABLE_PROJECTS=compiler-rt"

		# crbug/855759
		"-DCOMPILER_RT_BUILD_CRT=$(usex llvm-crt)"
	)

	if [[ ${CTARGET} == *-eabi ]]; then
		mycmakeargs+=(
			"-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY"
			"-DCOMPILER_RT_OS_DIR=baremetal"
			"-DCOMPILER_RT_BAREMETAL_BUILD=yes"
			"-DCMAKE_C_COMPILER_TARGET=${CTARGET}"
			"-DCOMPILER_RT_DEFAULT_TARGET_ONLY=yes"
		)
	else
		mycmakeargs+=(
			"-DCOMPILER_RT_TEST_TARGET_TRIPLE=${CTARGET}"
		)
	fi
	mycmakeargs+=(
		"-DCOMPILER_RT_INSTALL_PATH=${EPREFIX}$(${CC} --print-resource-dir)"
	)
	cmake-utils_src_configure
}

src_install() {
	# There is install conflict between cross-armv7a-cros-linux-gnueabihf
	# and cross-armv7a-cros-linux-gnueabi. Remove this once we are ready to
	# move to cross-armv7a-cros-linux-gnueabihf.
	if [[ ${CTARGET} == armv7a-cros-linux-gnueabi ]] ; then
		return
	fi
	cmake-utils_src_install

	# includes and docs are installed for all sanitizers and xray
	# These files conflict with files provided in llvm ebuild
	local libdir=$(llvm-config --libdir)
	rm -rf "${ED}"usr/share || die
	rm -rf "${ED}${libdir}"/clang/*/include || die
	rm -f "${ED}${libdir}"/clang/*/*_blacklist.txt || die
	rm -f "${ED}${libdir}"/clang/*/*/*_blacklist.txt || die
	rm -f "${ED}${libdir}"/clang/*/dfsan_abilist.txt || die
	rm -f "${ED}${libdir}"/clang/*/*/dfsan_abilist.txt || die
	rm -f "${ED}${libdir}"/clang/*/bin/* || die

	# Copy compiler-rt files to a new clang version to handle llvm updates gracefully.
	local llvm_version=$(llvm-config --version)
	local clang_version=${llvm_version%svn*}
	clang_version=${clang_version%git*}
	local compiler_rt_version=${clang_version%%.*}
	new_version="$((compiler_rt_version + 1)).0.0"
	old_version="$((compiler_rt_version - 1)).0.0"
	cp -r  "${D}${libdir}/clang/${clang_version}" "${D}${libdir}/clang/${new_version}"
	cp -r  "${D}${libdir}/clang/${clang_version}" "${D}${libdir}/clang/${old_version}"
}
