# Copyright (c) 2011 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT=("2633712387ab0ad683b021b64ee25921a3217dbb" "8048ece6c16c91acfe0d36d1d3cc0890ab6e945c")
CROS_WORKON_TREE=("8f373247a7f9d740e315ee39f0f03a02021cd3b8" "84dd0fabdc4d0729885dc7ce3ac35903504ba5e6")
CROS_WORKON_PROJECT=(
	"chromiumos/platform/google-breakpad"
	"linux-syscall-support"
)
CROS_WORKON_LOCALNAME=(
	"third_party/breakpad"
	"third_party/breakpad/src/third_party/lss"
)
CROS_WORKON_DESTDIR=(
	"${S}"
	"${S}/src/third_party/lss"
)

inherit cros-i686 cros-workon flag-o-matic multiprocessing

DESCRIPTION="Google crash reporting"
HOMEPAGE="https://chromium.googlesource.com/breakpad/breakpad"
SRC_URI=""

LICENSE="BSD-Google"
KEYWORDS="*"
IUSE="-alltests cros_host test"

COMMON_DEPEND="net-misc/curl:="
RDEPEND="${COMMON_DEPEND}"
DEPEND="${COMMON_DEPEND}
	test? (
		dev-cpp/gtest:=
	)
"

src_prepare() {
	default
	find "${S}" -type f -exec touch -r "${S}"/configure {} +
}

src_configure() {
	append-flags -g

	# Disable flaky tests by default.  Do it here because the CPPFLAGS
	# are recorded at configure time and not read on the fly.
	# http://crbug.com/359999
	use alltests && append-cppflags -DENABLE_FLAKY_TESTS

	multijob_init

	mkdir build
	pushd build >/dev/null || die
	ECONF_SOURCE=${S} multijob_child_init econf --enable-system-test-libs
	popd >/dev/null || die

	if use cros_host || use_i686; then
		# The mindump code is still wordsize specific.  Needs to be redone
		# like https://code.google.com/p/google-breakpad/source/detail?r=987.
		einfo "Configuring 32-bit build"
		mkdir work32
		pushd work32 >/dev/null
		use cros_host && append-flags "-m32"
		use_i686 && push_i686_env
		# Can be dropped once this is merged upstream:
		# https://breakpad.appspot.com/619002/
		append-lfs-flags # crbug.com/266064
		ECONF_SOURCE=${S} multijob_child_init econf
		filter-lfs-flags
		use_i686 && pop_i686_env
		use cros_host && filter-flags "-m32"
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

	if use_i686; then
		einfo "Building 32-bit library"
		push_i686_env
		emake -C work32 src/client/linux/libbreakpad_client.a
		pop_i686_env
	fi
}

src_test() {
	if ! use x86 && ! use amd64 ; then
		einfo Skipping unit tests on non-x86 platform
		return
	fi
	emake -C build check
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

	if use_i686; then
		push_i686_env
		dolib.a work32/src/client/linux/libbreakpad_client.a
		pop_i686_env
	fi
}
