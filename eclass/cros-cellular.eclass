# Copyright 2017 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: cros-cellular.eclass
# @MAINTAINER:
# ejcaruso@chromium.org
# @BUGREPORTS:
# Please report bugs via https://crbug.com/new
# @VCSURL: https://chromium.googlesource.com/chromiumos/overlays/chromiumos-overlay/+/master/eclass/@ECLASS@
# @BLURB: helper eclass for building cellular helpers for modemfwd
# @DESCRIPTION:
# modemfwd expects a directory containing helpers and a manifest detailing
# which ones are included. This ebuild makes it easier to put everything in
# the right place.

# The modemfwd helper directory.
_cellular_get_helperdir() {
	echo /opt/google/modemfwd-helpers
}

# @FUNCTION: cellular_dohelper
# @DESCRIPTION:
# Installs a helper binary to the modemfwd helper directory
# using doexe.
cellular_dohelper() {
	(
		exeinto "$(_cellular_get_helperdir)"
		doexe "${@}"
	)
}

# @FUNCTION: cellular_newhelper
# @DESCRIPTION:
# Installs a helper binary to the modemfwd helper directory
# using newexe.
cellular_newhelper() {
	(
		exeinto "$(_cellular_get_helperdir)"
		newexe "${@}"
	)
}

# @FUNCTION: cellular_domanifest
# @DESCRIPTION:
# Installs the compiled proto manifest into the modemfwd helper
# directory using doins.
cellular_domanifest() {
	(
		insinto "$(_cellular_get_helperdir)"
		doins "${@}"
	)
}
