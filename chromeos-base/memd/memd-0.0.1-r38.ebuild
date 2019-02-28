# Copyright 2018 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=6
CROS_WORKON_COMMIT="2779be40022b1d5dfb4c23f5b414f6231427a68b"
CROS_WORKON_TREE="02f090e4720f1a89357c21b94432d79db2c3e29e"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_SUBTREE="metrics/memd"
CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_OUTOFTREE_BUILD=1

inherit cros-rust cros-workon toolchain-funcs

DESCRIPTION="Fine-grain memory metrics collector"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE="+seccomp"

DEPEND="chromeos-base/system_api
	sys-apps/dbus
	>=dev-rust/chrono-0.4.2:=
	>=dev-rust/dbus-0.6.1:=
	>=dev-rust/env_logger-0.5.10:=
	>=dev-rust/libc-0.2.40:=
	>=dev-rust/log-0.4.1:=
	>=dev-rust/protobuf-1.4.3:=
	>=dev-rust/protoc-rust-1.4.3:=
	>=dev-rust/syslog-4.0.0:=
	>=dev-rust/time-0.1.40:=
	>=dev-rust/tempdir-0.3.5:=
	"

src_unpack() {
	# Unpack both the project and dependency source code.
	cros-workon_src_unpack

	# The compilation happens in the memd subdirectory.
	S+="/metrics/memd"

	cros-rust_src_unpack
}

src_compile() {
	# pkg-config won't work properly since we're cross-compiling
	# and we're taking care of library dependencies ourselves.
	export PKG_CONFIG_ALLOW_CROSS=1
	ecargo_build
	use test && ecargo_test --no-run
}

src_test() {
	if ! use x86 && ! use amd64 ; then
		elog "Skipping unit tests on non-x86 platform"
	else
		export RUST_BACKTRACE=1
		ecargo_test --all || die "memd test failed"
	fi
}

src_install() {
	# cargo doesn't know how to install cross-compiled binaries.  It will
	# always install native binaries for the host system.  Install manually
	# instead.
	local build_dir="$(cros-rust_get_build_dir)"
	dobin "${build_dir}/memd"
	insinto /etc/init
	doins init/memd.conf
	insinto /usr/share/policy
	use seccomp && \
		newins "init/memd-seccomp-${ARCH}.policy" memd-seccomp.policy
}
