# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-lang/python/python-2.7.10.ebuild,v 1.2 2015/06/29 17:26:27 floppym Exp $

EAPI="5"
WANT_LIBTOOL="none"

inherit autotools eutils flag-o-matic multilib pax-utils python-utils-r1 toolchain-funcs multiprocessing

MY_P="Python-${PV}"
PATCHSET_VERSION="2.7.10-0"

DESCRIPTION="An interpreted, interactive, object-oriented programming language"
HOMEPAGE="http://www.python.org/"

# The version of Python our PGO profile was generated with. Using ${PV} makes
# updates difficult, and we have tricks below to catch a mismatched profile
# version.
PROF_VERSION="2.7.10"

SRC_URI="http://www.python.org/ftp/python/${PV}/${MY_P}.tar.xz
	http://dev.gentoo.org/~floppym/python/python-gentoo-patches-${PATCHSET_VERSION}.tar.xz
	pgo_use? ( gs://chromeos-localmirror/distfiles/python-${PROF_VERSION}-pgo-prof.profdata.tar.xz )"

LICENSE="PSF-2"
SLOT="2.7"
KEYWORDS="*"
IUSE="-berkdb build doc elibc_uclibc examples gdbm hardened ipv6 pgo_generate +pgo_use +ncurses +readline sqlite +ssl +threads tk +wide-unicode wininst +xml"

REQUIRED_USE="pgo_generate? ( !pgo_use )"

# Workaround: re-emerging this after emerging a `pgo_generate` Python gives us
# a really bad time, since we'll try to write to profiles in "restricted"
# places somehow. Specifying this profile file has LLVM write profiles to
# /dev/null, which is always available.
export LLVM_PROFILE_FILE="/dev/null"

# Do not add a dependency on dev-lang/python to this ebuild.
# If you need to apply a patch which requires python for bootstrapping, please
# run the bootstrap code on your dev box and include the results in the
# patchset. See bug 447752.

RDEPEND="app-arch/bzip2
	>=sys-libs/zlib-1.1.3
	virtual/libffi
	virtual/libintl
	!build? (
		berkdb? ( || (
			sys-libs/db:5.3
			sys-libs/db:5.2
			sys-libs/db:5.1
			sys-libs/db:5.0
			sys-libs/db:4.8
			sys-libs/db:4.7
			sys-libs/db:4.6
			sys-libs/db:4.5
			sys-libs/db:4.4
			sys-libs/db:4.3
			sys-libs/db:4.2
		) )
		gdbm? ( sys-libs/gdbm )
		ncurses? (
			>=sys-libs/ncurses-5.2
			readline? ( >=sys-libs/readline-4.1 )
		)
		sqlite? ( >=dev-db/sqlite-3.3.8:3 )
		ssl? ( dev-libs/openssl )
		tk? (
			>=dev-lang/tk-8.0
			dev-tcltk/blt
			dev-tcltk/tix
		)
		xml? ( >=dev-libs/expat-2.1 )
	)
	!!<sys-apps/portage-2.1.9"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	>=sys-devel/autoconf-2.65
	!sys-devel/gcc[libffi]"
RDEPEND+=" !build? ( app-misc/mime-types )
	doc? ( dev-python/python-docs:${SLOT} )"
PDEPEND="app-eselect/eselect-python
	app-admin/python-updater"

S="${WORKDIR}/${MY_P}"

pkg_setup() {
	if use berkdb; then
		ewarn "'bsddb' module is out-of-date and no longer maintained inside"
		ewarn "dev-lang/python. 'bsddb' and 'dbhash' modules have been additionally"
		ewarn "removed in Python 3. A maintained alternative of 'bsddb3' module"
		ewarn "is provided by dev-python/bsddb3."
	else
		if has_version "=${CATEGORY}/${PN}-${PV%%.*}*[berkdb]"; then
			ewarn "You are migrating from =${CATEGORY}/${PN}-${PV%%.*}*[berkdb]"
			ewarn "to =${CATEGORY}/${PN}-${PV%%.*}*[-berkdb]."
			ewarn "You might need to migrate your databases."
		fi
	fi
}

src_prepare() {
	# According to the comments at the top of cgi.py, Linux vendors need to
	# patch the shebang in cgi.py. We'll ignore the comment about not using
	# "/usr/bin/env python" and use it anyway.
	sed -i -e '1 s:^#!.*$:#! /usr/bin/env python:' Lib/cgi.py || die

	# Ensure that internal copies of expat, libffi and zlib are not used.
	rm -r Modules/expat || die
	rm -r Modules/_ctypes/libffi* || die
	rm -r Modules/zlib || die

	if tc-is-cross-compiler; then
		local EPATCH_EXCLUDE="*_regenerate_platform-specific_modules.patch"
	fi

	EPATCH_SUFFIX="patch" epatch "${WORKDIR}/patches"

	#
	# START: ChromiumOS specific changes
	#
	if tc-is-cross-compiler ; then
		epatch "${FILESDIR}"/python-2.7.10-cross-h2py.patch
		epatch "${FILESDIR}"/python-2.7.10-cross-hack-compiler.patch
		sed -i 's:^python$EXE:${HOSTPYTHON}:' Lib/*/regen || die
	fi
	epatch "${FILESDIR}"/python-2.7.10-cross-setup-sysroot.patch
	epatch "${FILESDIR}"/python-2.7.10-cross-distutils.patch
	epatch "${FILESDIR}"/python-2.7.3-unique-semaphore-name.patch
	epatch "${FILESDIR}"/python-2.7.10-ldshared.patch
	epatch "${FILESDIR}"/python-2.7.17-getentropy.patch
	epatch "${FILESDIR}"/2.7-disable-nis.patch
	# Undo the @libdir@ change for portage's pym folder as it is always
	# installed into /usr/lib/ and not the abi libdir.
	sed -i \
		-e '/portage.*pym/s:@@GENTOO_LIBDIR@@:lib:g' \
		Lib/site.py || die

	sed -i -e "s:sys.exec_prefix]:sys.exec_prefix, '/usr/local']:g" \
		Lib/site.py || die "sed failed to add /usr/local to prefixes"

	# Enable stealthy profile application; with this, `sysconfig` won't
	# report on any CFLAGS in EXTRA_CFLAGS
	epatch "${FILESDIR}"/python-2.7-clear-extra-cflags.patch
	#
	# END: ChromiumOS specific changes
	#

	# Fix for cross-compiling.
	epatch "${FILESDIR}/python-2.7.5-nonfatal-compileall.patch"
	epatch "${FILESDIR}/python-2.7.9-ncurses-pkg-config.patch"

	sed -i -e "s:@@GENTOO_LIBDIR@@:$(get_libdir):g" \
		Lib/distutils/command/install.py \
		Lib/distutils/sysconfig.py \
		Lib/site.py \
		Lib/sysconfig.py \
		Lib/test/test_site.py \
		Makefile.pre.in \
		Modules/Setup.dist \
		Modules/getpath.c \
		setup.py || die "sed failed to replace @@GENTOO_LIBDIR@@"

	epatch_user

	eautoreconf
}

# There's a sad story behind this. When we've built our `python` and
# `libpython.so` objects, we'll go to build all of our Python modules. This is
# done with LD_LIBRARY_PATH set to our workdir, and is generally
# well-sandboxed. Sadly, the compiler is a wrapper written in Python and
# invoked via #!/usr/bin/python2, so **the compiler invocations will link to
# the new, not-yet-installed libpython.so**.
#
# Usually, this isn't much of a problem. However, when we're building Python
# with instrumentation enabled, libpython.so is where some of the key
# instrumentation functions end up. Since everything links to libpython.so, and
# since libpython.so shows up in link lines before libclang_rt.profile (where
# these "key instrumentation functions" come from), the only binary we built
# with USE=pgo_generate that has an actual definition for these functions is
# libpython.so.
#
# Hence, the old python invoked by the wrapper looks for its profiling symbols
# in the *new* libpython.so, doesn't find them, and gets sad.
#
# This can all be fixed by moving libclang_rt.profiles up before -lpython2.7 in
# the commandline, which is easily doable. Doing so puts these profiling
# symbols in every binary we produce, but only in pgo_generate builds. They're
# all dynamic symbols, so keeping multiple definitions around should be OK.
#
# Clang is good about moving libclangrt_profile around, so we just parse its
# output to determine where this static lib is located today.
detect_libprofile_rt_location() {
	local result
	# Clang always gives quoted output. We're picking out the single arg
	# with libclang_rt.profile from it, and discarding the quotes.
	result=$(echo | \
			$(tc-getCC) -### -fprofile-generate -x c - |& \
			grep -oE '"[^"]+libclang_rt.profile[^"]+"' | \
			tr -d '"')
	[[ -n "${result}" ]] || die "libclangrt detection failed"
	echo "${result}"
}

src_configure() {
	if use build; then
		# Disable extraneous modules with extra dependencies.
		export PYTHON_DISABLE_MODULES="dbm _bsddb gdbm _curses _curses_panel readline _sqlite3 _tkinter _elementtree pyexpat"
		export PYTHON_DISABLE_SSL="1"
	else
		# dbm module can be linked against berkdb or gdbm.
		# Defaults to gdbm when both are enabled, #204343.
		local disable
		use berkdb   || use gdbm || disable+=" dbm"
		use berkdb   || disable+=" _bsddb"
		use gdbm     || disable+=" gdbm"
		use ncurses  || disable+=" _curses _curses_panel"
		use readline || disable+=" readline"
		use sqlite   || disable+=" _sqlite3"
		use ssl      || export PYTHON_DISABLE_SSL="1"
		use tk       || disable+=" _tkinter"
		use xml      || disable+=" _elementtree pyexpat" # _elementtree uses pyexpat.
		export PYTHON_DISABLE_MODULES="${disable}"

		if ! use xml; then
			ewarn "You have configured Python without XML support."
			ewarn "This is NOT a recommended configuration as you"
			ewarn "may face problems parsing any XML documents."
		fi
	fi

	if [[ -n "${PYTHON_DISABLE_MODULES}" ]]; then
		einfo "Disabled modules: ${PYTHON_DISABLE_MODULES}"
	fi

	if [[ "$(gcc-major-version)" -ge 4 ]]; then
		append-flags -fwrapv
	fi

	filter-flags -malign-double

	[[ "${ARCH}" == "alpha" ]] && append-flags -fPIC

	# https://bugs.gentoo.org/show_bug.cgi?id=50309
	if is-flagq -O3; then
		is-flagq -fstack-protector-all && replace-flags -O3 -O2
		use hardened && replace-flags -O3 -O2
	fi

	if tc-is-cross-compiler; then
		# Force some tests that try to poke fs paths.
		export ac_cv_file__dev_ptc=no
		export ac_cv_file__dev_ptmx=yes
	fi

	# Export CXX so it ends up in /usr/lib/python2.X/config/Makefile.
	tc-export CXX
	# The configure script fails to use pkg-config correctly.
	# http://bugs.python.org/issue15506
	export ac_cv_path_PKG_CONFIG=$(tc-getPKG_CONFIG)

	# Set LDFLAGS so we link modules with -lpython2.7 correctly.
	# Needed on FreeBSD unless Python 2.7 is already installed.
	# Please query BSD team before removing this!
	append-ldflags "-L."

	tc-export CC
	if use pgo_generate; then
		tc-is-clang || die "Instrumentation is only supported when using clang"
		# tc_extra_flags is an invention used to make cflags apply
		# equally to Python's C modules and Python itself. This also
		# prevents duplication between CFLAGS and LDFLAGS, which is a
		# build error with -mllvm -options.
		#
		# This is a functional change in Python that breaks subversion
		# (SWIG Python bindings rely on distutils.sysconfigs' ${CC}),
		# so you should consider re-emerge'ing before trying to emerge
		# anything else.
		#
		# We explicitly use /tmp here because this path is *baked into
		# Python* as the place where profiles should go when Python is
		# run. Hence, it has to be a well-known place that lives after
		# `emerge`.
		CC+=" -fprofile-generate=/tmp/python_profiles"

		# LLVM intentionally low-balls vp-counters-per-site to save some
		# binary size. If left to its default of 1, we get a diagnostic
		# asking for it to be raised. Instead of tweaking it and having
		# the issue silently appear again in the future, force dynamic
		# allocation of counters. It's marginally slower, but less
		# error-prone.
		CC+=" -mllvm -vp-static-alloc=false"

		append-ldflags "$(detect_libprofile_rt_location)"
	fi

	local dbmliborder
	if use gdbm; then
		dbmliborder+="${dbmliborder:+:}gdbm"
	fi
	if use berkdb; then
		dbmliborder+="${dbmliborder:+:}bdb"
	fi

	BUILD_DIR="${WORKDIR}/${CHOST}"
	mkdir -p "${BUILD_DIR}" || die
	cd "${BUILD_DIR}" || die

	ECONF_SOURCE="${S}" OPT="" \
	econf \
		--with-fpectl \
		--enable-shared \
		$(use_enable ipv6) \
		$(use_with threads) \
		$(use wide-unicode && echo "--enable-unicode=ucs4" || echo "--enable-unicode=ucs2") \
		--infodir='${prefix}/share/info' \
		--mandir='${prefix}/share/man' \
		--with-dbmliborder="${dbmliborder}" \
		--with-libc="" \
		--enable-loadable-sqlite-extensions \
		--with-system-expat \
		--with-system-ffi \
		--without-ensurepip

	if use threads && grep -q "#define POSIX_SEMAPHORES_NOT_ENABLED 1" pyconfig.h; then
		eerror "configure has detected that the sem_open function is broken."
		eerror "Please ensure that /dev/shm is mounted as a tmpfs with mode 1777."
		die "Broken sem_open function (bug 496328)"
	fi
}

src_compile() {
	# Avoid invoking pgen for cross-compiles.
	touch Include/graminit.h Python/graminit.c

	# CFLAGS specified in configure get baked into the `sysconfig` module,
	# which is consulted when building e.g. SWIG bindings for subversion.
	# OPT, which we wiped out during configuration time anyway, allows us
	# to pass flags that `sysconfig` doesn't see.
	local extra_cflags=()
	if use pgo_use && tc-is-clang; then
		# If you're upgrading Python, please also run
		# ./files/python2_gen_pgo.sh to build a new PGO profile.
		if [[ "${PV}" != "${PROF_VERSION}" ]]; then
			die "Please generate a new profile. Details in comments."
		fi

		extra_cflags=(
			"-fprofile-use=${WORKDIR}/python-${PROF_VERSION}-pgo-prof.profdata"
			"-Wno-backend-plugin"
		)

		# LTO only buys us ~2%, it increases binary size around 750KB,
		# and it's entirely broken on aarch64 (LTO prompts clang to use
		# its built-in assembler, which has issues with inline assembly
		# in Python, apparently.)
	fi

	cd "${BUILD_DIR}" || die
	EXTRA_CFLAGS="${extra_cflags[*]}" emake

	# Work around bug 329499. See also bug 413751 and 457194.
	if has_version dev-libs/libffi[pax_kernel]; then
		pax-mark E python
	else
		pax-mark m python
	fi
}

src_test() {
	# Tests will not work when cross compiling.
	if tc-is-cross-compiler; then
		elog "Disabling tests due to crosscompiling."
		return
	fi

	cd "${BUILD_DIR}" || die

	# Skip failing tests.
	local skipped_tests="distutils gdb"

	for test in ${skipped_tests}; do
		mv "${S}"/Lib/test/test_${test}.py "${T}"
	done

	# Rerun failed tests in verbose mode (regrtest -w).
	emake test EXTRATESTOPTS="-w" < /dev/tty
	local result="$?"

	for test in ${skipped_tests}; do
		mv "${T}/test_${test}.py" "${S}"/Lib/test
	done

	elog "The following tests have been skipped:"
	for test in ${skipped_tests}; do
		elog "test_${test}.py"
	done

	elog "If you would like to run them, you may:"
	elog "cd '${EPREFIX}/usr/$(get_libdir)/python${SLOT}/test'"
	elog "and run the tests separately."

	python_disable_pyc

	if [[ "${result}" -ne 0 ]]; then
		die "emake test failed"
	fi
}

src_install() {
	local libdir=${ED}/usr/$(get_libdir)/python${SLOT}

	cd "${BUILD_DIR}" || die
	emake DESTDIR="${D}" altinstall

	sed -e "s/\(LDFLAGS=\).*/\1/" -i "${libdir}/config/Makefile" || die "sed failed"

	# Backwards compat with Gentoo divergence.
	dosym python${SLOT}-config /usr/bin/python-config-${SLOT}

	# Fix collisions between different slots of Python.
	mv "${ED}usr/bin/2to3" "${ED}usr/bin/2to3-${SLOT}"
	mv "${ED}usr/bin/pydoc" "${ED}usr/bin/pydoc${SLOT}"
	mv "${ED}usr/bin/idle" "${ED}usr/bin/idle${SLOT}"
	rm -f "${ED}usr/bin/smtpd.py"

	local abiver="python2.7"

	if use build; then
		rm -fr "${ED}usr/bin/idle${SLOT}" "${libdir}/"{bsddb,dbhash.py,idlelib,lib-tk,sqlite3,test}
	else
		use berkdb || rm -r "${libdir}/"{bsddb,dbhash.py,test/test_bsddb*} || die
		use sqlite || rm -r "${libdir}/"{sqlite3,test/test_sqlite*} || die
		use tk || rm -r "${ED}usr/bin/idle${SLOT}" "${libdir}/"{idlelib,lib-tk} || die
		use elibc_uclibc && rm -fr "${libdir}/"{bsddb/test,test}
	fi

	use threads || rm -r "${libdir}/multiprocessing" || die
	use wininst || rm -r "${libdir}/distutils/command/"wininst-*.exe || die

	dodoc "${S}"/Misc/{ACKS,HISTORY,NEWS}

	if use examples; then
		insinto /usr/share/doc/${PF}/examples
		doins -r "${S}"/Tools
	fi
	insinto /usr/share/gdb/auto-load/usr/$(get_libdir) #443510
	local libname=$(printf 'e:\n\t@echo $(INSTSONAME)\ninclude Makefile\n' | \
		emake --no-print-directory -s -f - 2>/dev/null)
	newins "${S}"/Tools/gdb/libpython.py "${libname}"-gdb.py

	newconfd "${FILESDIR}/pydoc.conf" pydoc-${SLOT}
	newinitd "${FILESDIR}/pydoc.init" pydoc-${SLOT}
	sed \
		-e "s:@PYDOC_PORT_VARIABLE@:PYDOC${SLOT/./_}_PORT:" \
		-e "s:@PYDOC@:pydoc${SLOT}:" \
		-i "${ED}etc/conf.d/pydoc-${SLOT}" "${ED}etc/init.d/pydoc-${SLOT}" || die "sed failed"

	# for python-exec
	python_export python${SLOT} EPYTHON PYTHON PYTHON_SITEDIR PYTHON_SCRIPTDIR

	# if not using a cross-compiler, use the fresh binary
	if ! tc-is-cross-compiler; then
		local PYTHON=./python
		local -x LD_LIBRARY_PATH=${LD_LIBRARY_PATH+${LD_LIBRARY_PATH}:}.
	fi

	echo "EPYTHON='${EPYTHON}'" > epython.py
	python_domodule epython.py

	# python-exec wrapping support
	local pymajor=${SLOT%.*}
	mkdir -p "${D}${PYTHON_SCRIPTDIR}" || die

	# python-exec: python, pythonX
	dosym "../../../bin/${abiver}" \
		"${PYTHON_SCRIPTDIR}/python${pymajor}"
	dosym "python${pymajor}" "${PYTHON_SCRIPTDIR}/python"

	# python-exec: python-config, python-configX
	#
	# Note: we need to create a wrapper rather than symlinking it due
	# to some random dirname(argv[0]) magic performed by python-config.
	cat > "${D}${PYTHON_SCRIPTDIR}/python${pymajor}-config" <<-EOF || die
		#!/bin/sh
		exec "${abiver}-config" "\${@}"
	EOF
	# Must strip EPREFIX because fperms prepends ED.
	fperms 755 "${PYTHON_SCRIPTDIR#$EPREFIX}/python${pymajor}-config"
	dosym "python${pymajor}-config" \
		"${PYTHON_SCRIPTDIR}/python-config"

	# python-exec: pydoc, pydocX
	dosym "../../../bin/pydoc${SLOT}" \
		"${PYTHON_SCRIPTDIR}/pydoc${pymajor}"
	dosym "pydoc${pymajor}" "${PYTHON_SCRIPTDIR}/pydoc"

	# python-exec: 2to3
	dosym "../../../bin/2to3-${SLOT}" \
		"${PYTHON_SCRIPTDIR}/2to3"

	# The sysconfig module will actually read the pyconfig.h at runtime to see what kind
	# of functionality is enabled in the build.  Deploy it behind the back of portage as
	# need be.
	ln "${ED}/usr/include/python${SLOT}/pyconfig.h" "${libdir}/pyconfig_h" || die

	# Workaround https://bugs.gentoo.org/380569
	keepdir /etc/env.d/python
}

pkg_preinst() {
	if has_version "<${CATEGORY}/${PN}-${SLOT}" && ! has_version "${CATEGORY}/${PN}:2.7"; then
		python_updater_warning="1"
	fi
}

eselect_python_update() {
	if [[ -z "$(eselect python show)" || ! -f "${EROOT}usr/bin/$(eselect python show)" ]]; then
		eselect python update
	fi

	if [[ -z "$(eselect python show --python${PV%%.*})" || ! -f "${EROOT}usr/bin/$(eselect python show --python${PV%%.*})" ]]; then
		eselect python update --python${PV%%.*}
	fi
}

pkg_postinst() {
	eselect_python_update

	if [[ "${python_updater_warning}" == "1" ]]; then
		ewarn "You have just upgraded from an older version of Python."
		ewarn "You should switch active version of Python ${PV%%.*} and run"
		ewarn "'python-updater [options]' to rebuild Python modules."
	fi

	local pyconfig="${EROOT}/usr/$(get_libdir)/python${SLOT}/pyconfig_h"
	if [[ ! -e ${EROOT}/usr/include/python${SLOT}/pyconfig.h ]] ; then
		# See pkg_preinst above for details.
		install -D -m644 "${pyconfig}" "${EROOT}/usr/include/python${SLOT}/pyconfig.h" || die
	fi
	rm "${pyconfig}" || die
}

pkg_postrm() {
	eselect_python_update
}
