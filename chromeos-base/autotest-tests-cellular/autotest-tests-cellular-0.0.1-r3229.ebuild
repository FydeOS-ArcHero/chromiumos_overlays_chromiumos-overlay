# Copyright 2014 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_COMMIT="3593b5cf9f9d5b51df4068d0c95c3bb3b52d1e47"
CROS_WORKON_TREE="510a965c45080e46745f91ff289f2779c81668ab"
CROS_WORKON_PROJECT="chromiumos/third_party/autotest"

inherit cros-workon autotest

DESCRIPTION="Cellular autotests"
HOMEPAGE="http://www.chromium.org/"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
# Enable autotest by default.
IUSE="${IUSE} +autotest"

RDEPEND="
	!<chromeos-base/autotest-tests-0.0.2
	chromeos-base/autotest-deps-cellular
	chromeos-base/shill-test-scripts
	dev-python/pygobject
	dev-python/pyusb
	sys-apps/ethtool
"
DEPEND="${RDEPEND}"

IUSE_TESTS="
	+tests_cellular_ActivateLTE
	+tests_cellular_ConnectFailure
	+tests_cellular_DeferredRegistration
	+tests_cellular_DisableWhileConnecting
	+tests_cellular_DisconnectFailure
	+tests_cellular_Identifiers
	+tests_cellular_OutOfCreditsSubscriptionState
	+tests_cellular_SIMLocking
	+tests_cellular_SafetyDance
	+tests_cellular_ScanningProperty
	+tests_cellular_ServiceName
	+tests_cellular_Smoke
	+tests_cellular_StressEnable
"

IUSE_MBIM_TESTS="
	+tests_cellular_MbimComplianceControlCommand
	+tests_cellular_MbimComplianceControlRequest
	+tests_cellular_MbimComplianceDataTransfer
	+tests_cellular_MbimComplianceDescriptor
	+tests_cellular_MbimComplianceError
"

IUSE_TESTS="${IUSE_TESTS} ${IUSE_MBIM_TESTS}"

IUSE="${IUSE} ${IUSE_TESTS}"

CROS_WORKON_LOCALNAME="third_party/autotest/files"

AUTOTEST_DEPS_LIST=""
AUTOTEST_CONFIG_LIST=""
AUTOTEST_PROFILERS_LIST=""

AUTOTEST_FILE_MASK="*.a *.tar.bz2 *.tbz2 *.tgz *.tar.gz"
