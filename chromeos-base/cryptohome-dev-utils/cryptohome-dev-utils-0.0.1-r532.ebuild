# Copyright 2018 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

CROS_WORKON_COMMIT="ed398e8adbe10533cf3538dad63102f54f37f532"
CROS_WORKON_TREE=("33378ea9ec0ce2140519976d43d90cb944b86813" "e55ec5aa5bd0d7efebb7b9cc93d8301fb25da028" "a6d4fca3db878377b5ababec63bde6714fa580dc" "e7dba8c91c1f3257c34d4a7ffff0ea2537aeb6bb")
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_DESTDIR="${S}/platform2"
CROS_WORKON_INCREMENTAL_BUILD=1
# TODO(crbug.com/809389): Avoid directly including headers from other packages.
CROS_WORKON_SUBTREE="common-mk cryptohome secure_erase_file .gn"

PLATFORM_SUBDIR="cryptohome/dev-utils"

inherit cros-workon platform

DESCRIPTION="Cryptohome developer and testing utilities for Chromium OS"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/master/cryptohome"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE="tpm tpm2"

REQUIRED_USE="tpm2? ( !tpm )"

RDEPEND="
	tpm? (
		app-crypt/trousers
	)
	tpm2? (
		chromeos-base/trunks
	)
	chromeos-base/attestation
	chromeos-base/chaps
	chromeos-base/libscrypt
	chromeos-base/metrics
	chromeos-base/tpm_manager
	chromeos-base/secure-erase-file
	dev-libs/glib
	dev-libs/openssl:=
	dev-libs/protobuf:=
	sys-apps/keyutils
	sys-fs/e2fsprogs
	sys-fs/ecryptfs-utils
"

DEPEND="${RDEPEND}
	chromeos-base/vboot_reference
"

src_install() {
	dosbin "${OUT}"/cryptohome-tpm-live-test
}