# Copyright 2014 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=5
CROS_WORKON_COMMIT="ef9e0a5f54134128cac76882cc85526d3b849a21"
CROS_WORKON_TREE="3edf9cbf70831d3cdf990a47a09669afd2c7c93b"
CROS_WORKON_PROJECT="chromiumos/third_party/autotest"
CROS_WORKON_LOCALNAME="third_party/autotest/files"

inherit cros-sanitizers cros-workon autotest

DESCRIPTION="Graphics autotests"
HOMEPAGE="http://www.chromium.org/"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
# Enable autotest by default.
IUSE="+autotest"

RDEPEND="
	!<chromeos-base/autotest-tests-0.0.3
	chromeos-base/autotest-deps-graphics
	tests_graphics_Gbm? ( media-libs/minigbm )
	tests_graphics_GLBench? ( chromeos-base/glbench )
	tests_graphics_GLMark2? ( chromeos-base/autotest-deps-glmark2 )
	tests_graphics_SanAngeles? ( media-libs/waffle )
"
DEPEND="${RDEPEND}"

IUSE_TESTS="
	+tests_graphics_dEQP
	+tests_graphics_Gbm
	+tests_graphics_GLAPICheck
	+tests_graphics_GLBench
	+tests_graphics_GLMark2
	+tests_graphics_KernelConfig
	+tests_graphics_KernelMemory
	+tests_graphics_LibDRM
	+tests_graphics_PerfControl
	+tests_graphics_SanAngeles
	+tests_graphics_SyncControlTest
"

IUSE="${IUSE} ${IUSE_TESTS}"

AUTOTEST_FILE_MASK="*.a *.tar.bz2 *.tbz2 *.tgz *.tar.gz"

src_configure() {
	sanitizers-setup-env
	cros-workon_src_configure
}