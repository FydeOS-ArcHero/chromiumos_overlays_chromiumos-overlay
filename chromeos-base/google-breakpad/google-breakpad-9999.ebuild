# Copyright (c) 2011 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=4
CROS_WORKON_PROJECT="chromiumos/platform/google-breakpad"

inherit cros-workon toolchain-funcs flag-o-matic multiprocessing

DESCRIPTION="Google crash reporting"
HOMEPAGE="http://code.google.com/p/google-breakpad"
SRC_URI=""

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
IUSE="cros_host"

RDEPEND="net-misc/curl"
DEPEND="${RDEPEND}"

src_prepare() {
	[[ ${ABI} == "x32" ]] && epatch "${FILESDIR}"/lss-x32.patch

	find "${S}" -type f -exec touch -r "${S}"/configure {} +
}

src_configure() {
	append-flags -g

	tc-export CC CXX LD PKG_CONFIG

	multijob_init

	mkdir build
	pushd build >/dev/null
	ECONF_SOURCE=${S} multijob_child_init cros-workon_src_configure
	popd >/dev/null

	if use cros_host; then
		# The mindump code is still wordsize specific.  Needs to be redone
		# like https://code.google.com/p/google-breakpad/source/detail?r=987.
		einfo "Building a 32-bit version of tools"
		mkdir work32
		pushd work32 >/dev/null
		append-flags "-m32"
		# Can be dropped once this is merged upstream:
		# https://breakpad.appspot.com/619002/
		append-lfs-flags # crbug.com/266064
		ECONF_SOURCE=${S} multijob_child_init cros-workon_src_configure
		filter-lfs-flags
		filter-flags "-m32"
		popd >/dev/null
	fi

	multijob_finish
}

src_compile() {
	emake -C build

	if use cros_host; then
		einfo "Building 32-bit tools"
		emake -C work32 \
			src/tools/linux/md2core/minidump-2-core
	fi
}

src_test() {
	if ! use x86 && ! use amd64 ; then
		einfo Skipping unit tests on non-x86 platform
	else
		emake -C build check
	fi
}

src_install() {
	pushd build >/dev/null
	emake DESTDIR="${D}" install
	dobin src/tools/linux/core2md/core2md \
	      src/tools/linux/md2core/minidump-2-core \
	      src/tools/linux/dump_syms/dump_syms \
	      src/tools/linux/symupload/sym_upload \
	      src/tools/linux/symupload/minidump_upload
	popd >/dev/null

	insinto /usr/include/google-breakpad/client/linux/handler
	doins src/client/linux/handler/*.h
	insinto /usr/include/google-breakpad/client/linux/crash_generation
	doins src/client/linux/crash_generation/*.h
	insinto /usr/include/google-breakpad/common/linux
	doins src/common/linux/*.h
	insinto /usr/include/google-breakpad/processor
	doins src/processor/*.h

	if use cros_host; then
		newbin work32/src/tools/linux/md2core/minidump-2-core \
		       minidump-2-core.32
	fi
}
