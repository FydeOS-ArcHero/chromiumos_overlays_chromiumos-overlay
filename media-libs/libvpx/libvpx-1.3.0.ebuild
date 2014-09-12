# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libvpx/libvpx-1.3.0.ebuild,v 1.13 2012/08/16 18:53:27 vapier Exp $

EAPI=4
inherit multilib toolchain-funcs base

if [[ ${PV} == *9999* ]]; then
	inherit git-2
	EGIT_REPO_URI="https://chromium.googlesource.com/webm/${PN}.git"
	KEYWORDS=""
elif [[ ${PV} == *pre* ]]; then
	SRC_URI="mirror://gentoo/${P}.tar.bz2"
	KEYWORDS="*"
else
	SRC_URI="http://webm.googlecode.com/files/${PN}-v${PV}.tar.bz2"
	KEYWORDS="*"
	S="${WORKDIR}/${PN}-v${PV}"
fi

DESCRIPTION="WebM VP8 Codec SDK"
HOMEPAGE="http://www.webmproject.org"

LICENSE="BSD"
SLOT="0"
IUSE="altivec debug doc mmx postproc sse sse2 sse3 ssse3 sse4_1 static-libs +threads"

RDEPEND=""
DEPEND="amd64? ( dev-lang/yasm )
	x86? ( dev-lang/yasm )
	x86-fbsd? ( dev-lang/yasm )
	doc? (
		app-doc/doxygen
		dev-lang/php
	)
"

REQUIRED_USE="
	sse2? ( mmx )
	"

PATCHES=(
	"${FILESDIR}/${P}-flag.patch"
)

src_configure() {
	#let the build system decide which AS to use (it honours $AS but
	#then feeds it with yasm flags without checking...) bug 345161
	local a
	tc-export AS
	for a in {amd64,x86}{,-{fbsd,linux}} ; do
		use ${a} && unset AS
	done

	# build verbose by default
	MAKEOPTS="${MAKEOPTS} verbose=yes"

	# http://bugs.gentoo.org/show_bug.cgi?id=384585
	addpredict /usr/share/snmp/mibs/.index

	# Build with correct toolchain.
	tc-export CC AR NM CXX
	# Link with gcc by default, the build system should override this if needed.
	export LD="${CC}"

	./configure \
		--prefix="${EPREFIX}"/usr \
		--libdir="${EPREFIX}"/usr/$(get_libdir) \
		--enable-pic \
		--enable-vp8 \
		--enable-vp9 \
		--enable-shared \
		--extra-cflags="${CFLAGS}" \
		$(use_enable altivec) \
		$(use_enable debug debug-libs) \
		$(use_enable debug) \
		$(use_enable doc install-docs) \
		$(use_enable mmx) \
		$(use_enable postproc) \
		$(use_enable sse) \
		$(use_enable sse2) \
		$(use_enable sse3) \
		$(use_enable sse4_1) \
		$(use_enable ssse3) \
		$(use_enable static-libs static ) \
		$(use_enable threads multithread) \
		|| die
}

src_install() {
	# Override base.eclass's src_install.
	default
}
