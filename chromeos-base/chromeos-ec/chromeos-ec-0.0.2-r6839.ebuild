# Copyright (C) 2012 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE.makefile file.

# A note about this ebuild: this ebuild is Unified Build enabled but
# not in the way in which most other ebuilds with Unified Build
# knowledge are: the primary use for this ebuild is for engineer-local
# work or firmware builder work. In both cases, the build might be
# happening on a branch in which only one of many of the models are
# available to build. The logic in this ebuild succeeds so long as one
# of the many models successfully builds.

# Increment the "eclass bug workaround count" below when you change
# "cros-ec.eclass" to work around http://crbug.com/220902.
#
# eclass bug workaround count: 1

EAPI=7

CROS_WORKON_COMMIT=("35bb4afa2a1d69b12f77e74c77dfa65cc350781a" "0be7f8dcc9bc3d082036fbab8c1caa67715a11f4" "51c319ff23b6e5d6b3d8deb539a063edffb24483")
CROS_WORKON_TREE=("a3e6dd92cf09e493e51725d8c7ea82f02296928d" "a4c56d3bb4c4f359199854c87e06b4af06cf05ce" "5b25e42c84714218b06757c9d47399820bb64da5")
CROS_WORKON_PROJECT=(
	"chromiumos/platform/ec"
	"chromiumos/third_party/tpm2"
	"chromiumos/third_party/cryptoc"
)
CROS_WORKON_LOCALNAME=(
	"platform/ec"
	"third_party/tpm2"
	"third_party/cryptoc"
)
CROS_WORKON_DESTDIR=(
	"${S}/platform/ec"
	"${S}/third_party/tpm2"
	"${S}/third_party/cryptoc"
)

inherit cros-ec cros-workon

# Make sure config tools use the latest schema.
BDEPEND=">=chromeos-base/chromeos-config-host-0.0.2"

MIRROR_PATH="gs://chromeos-localmirror/distfiles/"
DESCRIPTION="Embedded Controller firmware code"
KEYWORDS="*"