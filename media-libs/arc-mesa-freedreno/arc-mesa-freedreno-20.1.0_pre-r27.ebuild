# Copyright 2018 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

EAPI=6

CROS_WORKON_COMMIT="53aa9dc959a9ffdd6da5de9652457a5f526b3f85"
CROS_WORKON_TREE="c63701228c9ed6315792ac0e2e35f76982a7208c"
CROS_WORKON_PROJECT="chromiumos/third_party/mesa"
CROS_WORKON_LOCALNAME="mesa-freedreno"

inherit base meson multilib-minimal flag-o-matic toolchain-funcs cros-workon arc-build

DESCRIPTION="OpenGL-like graphic library for Linux"
HOMEPAGE="http://mesa3d.sourceforge.net/"

KEYWORDS="*"

# Most files are MIT/X11.
# Some files in src/glx are SGI-B-2.0.
LICENSE="MIT SGI-B-2.0"
SLOT="0"

IUSE="
	cheets
	cheets_user
	cheets_user_64
	debug
	-vulkan
"

REQUIRED_USE="
	cheets
"

DEPEND="
	>=x11-libs/arc-libdrm-2.4.82[${MULTILIB_USEDEP}]
	dev-libs/arc-libelf[${MULTILIB_USEDEP}]
"

RDEPEND="${DEPEND}"

pkg_pretend() {
	if use vulkan; then
		die "${PN} does not yet support vulkan"
	fi
}

src_configure() {
	arc-build-select-clang

	multilib-minimal_src_configure
}

multilib_src_configure() {
	# The AOSP build system defines the Make variable PLATFORM_SDK_VERSION,
	# and Mesa's Android.mk files use it to define the macro
	# ANDROID_API_LEVEL. Arc emulates that here.
	if [[ -n "${ARC_PLATFORM_SDK_VERSION}" ]]; then
		CPPFLAGS+=" -DANDROID_API_LEVEL=${ARC_PLATFORM_SDK_VERSION}"
	fi

	tc-getPROG PKG_CONFIG pkg-config

	# Need std=gnu++11 to build with libc++. crbug.com/750831
	append-cxxflags "-std=gnu++11"

	emesonargs+=(
		--prefix="${ARC_PREFIX}/vendor"
		--sysconfdir="/system/vendor/etc"
		-Ddri-search-path="/system/$(get_libdir)/dri:/system/vendor/$(get_libdir)/dri"
		-Dllvm=false
		-Ddri3=false
		-Dshader-cache=false
		-Dglx=disabled
		-Degl=true
		-Dgbm=false
		-Dgles1=true
		-Dgles2=true
		-Dshared-glapi=true
		-Ddri-drivers=
		-Dgallium-drivers=freedreno
		-Dgallium-vdpau=false
		-Dgallium-xa=false
		-Dplatforms=android
		-Degl-lib-suffix=_mesa
		-Dgles-lib-suffix=_mesa
		--buildtype $(usex debug debug release)
		-Dvulkan-drivers=$(usex vulkan freedreno '')
	)

	meson_src_configure
}

# The meson eclass exports src_compile but not multilib_src_compile. src_compile
# gets overridden by multilib-minimal
multilib_src_compile() {
	meson_src_compile
}

multilib_src_install() {
	exeinto "${ARC_PREFIX}/vendor/$(get_libdir)"
	newexe "${BUILD_DIR}/src/mapi/shared-glapi/libglapi.so.0" libglapi.so.0

	exeinto "${ARC_PREFIX}/vendor/$(get_libdir)/egl"
	newexe "${BUILD_DIR}/src/egl/libEGL_mesa.so" libEGL_mesa.so
	newexe "${BUILD_DIR}/src/mapi/es1api/libGLESv1_CM_mesa.so" libGLESv1_CM_mesa.so
	newexe "${BUILD_DIR}/src/mapi/es2api/libGLESv2_mesa.so" libGLESv2_mesa.so

	exeinto "${ARC_PREFIX}/vendor/$(get_libdir)/dri"
	newexe "${BUILD_DIR}/src/gallium/targets/dri/libgallium_dri.so" msm_dri.so
}

multilib_src_install_all() {
	# For documentation on the feature set represented by each XML file
	# installed into /vendor/etc/permissions, see
	# <https://developer.android.com/reference/android/content/pm/PackageManager.html>.
	# For example XML files for each feature, see
	# <https://android.googlesource.com/platform/frameworks/native/+/master/data/etc>.

	# Install init files to advertise supported API versions.
	insinto "${ARC_PREFIX}/vendor/etc/init"
	doins "${FILESDIR}/gles30.rc"

	# Install the dri header for arc-cros-gralloc
	insinto "${ARC_PREFIX}/vendor/include/GL"
	doins -r "${S}/include/GL/internal"
}
