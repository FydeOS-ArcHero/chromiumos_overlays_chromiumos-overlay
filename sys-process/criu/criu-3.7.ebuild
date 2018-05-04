# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python2_7 )

inherit eutils toolchain-funcs linux-info flag-o-matic python-r1 python-utils-r1

DESCRIPTION="utility to checkpoint/restore a process tree"
HOMEPAGE="http://criu.org/"
SRC_URI="http://download.openvz.org/criu/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="python selinux setproctitle static-libs"

REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

RDEPEND="
	dev-libs/protobuf-c
	python? ( dev-python/protobuf-python[${PYTHON_USEDEP}] )
	dev-libs/libnl:3
	net-libs/libnet:1.1
	sys-libs/libcap
	python? ( ${PYTHON_DEPS} )
	selinux? ( sys-libs/libselinux )
	setproctitle? ( dev-libs/libbsd )"
DEPEND="${RDEPEND}
	app-text/asciidoc
	app-text/xmlto
	"

RDEPEND="${RDEPEND}
	python? (
		|| (
			dev-python/protobuf-python[${PYTHON_USEDEP}]
			dev-libs/protobuf[python,${PYTHON_USEDEP}]
		)
		dev-python/ipaddr[${PYTHON_USEDEP}]
	)"


PATCHES=(
	"${FILESDIR}"/2.2/${PN}-2.2-flags.patch
	"${FILESDIR}"/2.3/${PN}-2.3-no-git.patch
	"${FILESDIR}"/${PN}-2.8-automagic-libbsd.patch
	"${FILESDIR}"/2.0/${PN}-2.0-sysroot.patch
)

CONFIG_CHECK="~CHECKPOINT_RESTORE ~NAMESPACES ~PID_NS ~FHANDLE ~EVENTFD ~EPOLL ~INOTIFY_USER ~IA32_EMULATION ~UNIX_DIAG ~INET_DIAG ~INET_UDP_DIAG ~PACKET_DIAG ~NETLINK_DIAG"

criu_arch() {
	# criu infers the arch from $(uname -m).  We never want this to happen.
	case ${ARCH} in
	amd64) echo "x86";;
	arm64) echo "aarch64";;
	*)     echo "${ARCH}";;
	esac
}

src_prepare() {
	default

	if ! use selinux; then
		sed \
			-e 's:libselinux:no_libselinux:g' \
			-i Makefile.config || die
	fi
}

src_configure() {
	# Gold linker generates invalid object file when used with criu's custom
	# linker script.  Use the bfd linker instead. See https://crbug.com/839665#c3
	tc-ld-disable-gold
}

src_compile() {
	RAW_LDFLAGS="$(raw-ldflags)" emake \
		HOSTCC="$(tc-getCC)" \
		CC="$(tc-getCC)" \
		LD="$(tc-getLD)" \
		OBJCOPY="$(tc-getOBJCOPY)" \
		LIBDIR="${EPREFIX}/usr/$(get_libdir)" \
		ARCH="$(criu_arch)" \
		V=1 WERROR=0 DEBUG=0 \
		SETPROCTITLE=$(usex setproctitle) \
		PYCRIU=$(usex python) \
		all docs
}


install_crit() {
	"${PYTHON:-python}" ../scripts/crit-setup.py install --root="${D}" --prefix="${EPREFIX}/usr/"
}

src_install() {
	sed -e "s#-lnet#-L${EROOT}/usr/$(get_libdir) -lnet#g" -i criu/Makefile.packages
	emake \
		ARCH="$(criu_arch)" \
		CC="$(tc-getCC)" \
		PREFIX="${EPREFIX}"/usr \
		LOGROTATEDIR="${EPREFIX}"/etc/logrotate.d \
		DESTDIR="${D}" \
		LIBDIR="${EPREFIX}/usr/$(get_libdir)" \
		install

	dodoc CREDITS README.md

	if use python ; then
		cd lib
		python_foreach_impl install_crit
	fi

	if ! use static-libs; then
		find "${D}" -name "*.a" -delete || die
	fi
}
