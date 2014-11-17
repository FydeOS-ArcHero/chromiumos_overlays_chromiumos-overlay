# Copyright 2014 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="4"
PYTHON_COMPAT=( python2_7 )

inherit cros-board cros-constants gn-chromium multiprocessing python-single-r1

DESCRIPTION="mojo_shell, libraries, and codegen tools for use on CrOS"
SRC_URI=""

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="~*"

RDEPEND="dev-libs/glib
	dev-libs/libevent
	dev-libs/nspr
	dev-libs/nss"
DEPEND="${PYTHON_DEPS}
	${RDEPEND}"

# The git commit-id to build from. Use the special value "HEAD" to
# build from tip-of-tree.
MOJO_REVISION="HEAD"

pkg_setup() {
	gn-chromium_pkg_setup
}

src_unpack() {
	export EGCLIENT="${EGCLIENT:-/mnt/host/depot_tools/gclient}"
	export DEPOT_TOOLS_UPDATE=0  # Prevents gclient from self-updating.
	cat > .gclient <<EOF
solutions = [
  { "name"        : "src",
    "url"         : "https://chromium.googlesource.com/external/mojo",
    "deps_file"   : "DEPS",
    "managed"     : False,
    "safesync_url": "",
  },
]
EOF
	local revopt=""
	if [ "$MOJO_REVISION" != "HEAD" ] ; then
	    revopt="--revision=${MOJO_REVISION}"
	fi
	"${EGCLIENT}" sync -j$(makeopts_jobs) --verbose --nohooks \
	    --transitive --reset --force --delete_unversioned_trees ${revopt}
	ln -s src "${S}"
}

src_configure() {
	gn-chromium_set_args "ui_base_build_ime=false"
	gn-chromium_src_configure
}

src_compile() {
	ninja -C "$(gn-chromium_get_build_dir)" \
	    mojo_shell mojo_launcher libmojo_sdk || die
}

src_install() {
	# Mojo runtime.
	dosbin "$(gn-chromium_get_build_dir)/mojo_launcher"
	dosbin "$(gn-chromium_get_build_dir)/mojo_shell"

	# Mojo SDK library and headers.
	local d header_dirs=(
		mojo/public/cpp/application
		mojo/public/cpp/bindings
		mojo/public/cpp/environment
		mojo/public/cpp/utility
		mojo/public/c/environment
		mojo/public/c/system
		mojo/public/platform/native
	)
	for d in "${header_dirs[@]}" ; do
		insinto /usr/include/${d}
		doins ${d}/*.h
	done
	local generated_dirs=( mojo/public/interfaces/application )
	for d in "${generated_dirs[@]}" ; do
		insinto /usr/include/${d}
		doins "$(gn-chromium_get_build_dir)/gen/${d}/"*.h
	done
	dolib.a "$(gn-chromium_get_build_dir)/obj/mojo/public/libmojo_sdk.a"

	# Code generation tools, including GYP rules for mojom files.
	insinto /build/bin
	doins -r "mojo/public/tools/bindings"
}
