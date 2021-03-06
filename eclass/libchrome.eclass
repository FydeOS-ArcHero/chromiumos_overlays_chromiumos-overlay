# Copyright 2014 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: libchrome.eclass
# @MAINTAINER:
# ChromiumOS Build Team
# @BUGREPORTS:
# Please report bugs via http://crbug.com/new (with label Build)
# @VCSURL: https://chromium.googlesource.com/chromiumos/overlays/chromiumos-overlay/+/master/eclass/@ECLASS@
# @BLURB: helper eclass for managing dependencies on libchrome
# @DESCRIPTION:
# Our base library libchrome is slotted and is used by a lot of packages. All
# the version numbers need to be updated whenever we uprev libchrome. This
# eclass centralizes the logic used to depend on libchrome and sets up the
# environment variables to reduce the amount of change needed.

inherit cros-debug libchrome-version

RDEPEND="
	chromeos-base/libchrome:=[cros-debug=]
"

DEPEND="${RDEPEND}"
