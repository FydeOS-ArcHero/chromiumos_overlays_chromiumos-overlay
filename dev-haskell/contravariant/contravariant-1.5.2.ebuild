# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=5

# ebuild generated by hackport 0.4.7.9999

CABAL_FEATURES="lib profile haddock hoogle hscolour"
inherit haskell-cabal

DESCRIPTION="Contravariant functors"
HOMEPAGE="https://github.com/ekmett/contravariant/"
SRC_URI="mirror://hackage/packages/archive/${PN}/${PV}/${P}.tar.gz"

LICENSE="BSD"
SLOT="0/${PV}"
KEYWORDS="*"
IUSE="safe +semigroups +statevar +tagged"

RDEPEND=">=dev-haskell/transformers-0.2:=[profile?] <dev-haskell/transformers-0.6:=[profile?]
	>=dev-haskell/transformers-compat-0.3:=[profile?] <dev-haskell/transformers-compat-1:=[profile?]
	>=dev-haskell/void-0.6:=[profile?] <dev-haskell/void-1:=[profile?]
	>=dev-lang/ghc-7.4.1:=
	semigroups? ( >=dev-haskell/semigroups-0.15.2:=[profile?] <dev-haskell/semigroups-1:=[profile?] )
	statevar? ( >=dev-haskell/statevar-1.1:=[profile?] <dev-haskell/statevar-1.3:=[profile?] )
	tagged? ( >=dev-haskell/tagged-0.4.4:=[profile?] <dev-haskell/tagged-1:=[profile?] )
"
DEPEND="${RDEPEND}
	>=dev-haskell/cabal-1.6
"

src_configure() {
	haskell-cabal_src_configure \
		$(cabal_flag safe safe) \
		$(cabal_flag semigroups semigroups) \
		$(cabal_flag statevar statevar) \
		$(cabal_flag tagged tagged)
}
