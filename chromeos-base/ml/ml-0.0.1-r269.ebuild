# Copyright 2018 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_COMMIT="1082555b621a0707470a8c3406f635e1aaf4d81f"
CROS_WORKON_TREE=("dea48af07754556aac092c0830de0b1ab410077b" "543df9cc3636a4f1a9adb7bdfbf5cde48b0862a2" "e7dba8c91c1f3257c34d4a7ffff0ea2537aeb6bb")
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
# TODO(amoylan): Set CROS_WORKON_OUTOFTREE_BUILD=1 after crbug.com/833675.
CROS_WORKON_DESTDIR="${S}/platform2"
CROS_WORKON_SUBTREE="common-mk ml .gn"

PLATFORM_SUBDIR="ml"

inherit cros-workon platform user

DESCRIPTION="Machine learning service for Chromium OS"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/master/ml"

# Clients of the ML service should place the URIs of their model files into
# this variable.
MODELS=(
	"gs://chromeos-localmirror/distfiles/mlservice-model-test_add-20180914.tflite"
	"gs://chromeos-localmirror/distfiles/mlservice-model-search_ranker-20190923.tflite"
	"gs://chromeos-localmirror/distfiles/mlservice-model-smart_dim-20181115.tflite"
	"gs://chromeos-localmirror/distfiles/mlservice-model-smart_dim-20190221.tflite"
	"gs://chromeos-localmirror/distfiles/mlservice-model-smart_dim-20190521-v3.tflite"
	"gs://chromeos-localmirror/distfiles/mlservice-model-top_cat-20190722.tflite"
)

SRC_URI="${MODELS[*]}"

LICENSE="BSD-Google"
KEYWORDS="*"
IUSE="fuzzer"

RDEPEND="
	chromeos-base/libbrillo:=
	chromeos-base/metrics:=
	sci-libs/tensorflow:=
"

DEPEND="
	${RDEPEND}
	chromeos-base/system_api:=[fuzzer?]
"

src_install() {
	dobin "${OUT}"/ml_service

	# Install upstart configuration.
	insinto /etc/init
	doins init/*.conf

	# Install seccomp policy file.
	insinto /usr/share/policy
	newins "seccomp/ml_service-seccomp-${ARCH}.policy" ml_service-seccomp.policy

	# Install D-Bus configuration file.
	insinto /etc/dbus-1/system.d
	doins dbus/org.chromium.MachineLearning.conf

	# Install D-Bus service activation configuration.
	insinto /usr/share/dbus-1/system-services
	doins dbus/org.chromium.MachineLearning.service

	# Create distfile array of model filepaths.
	local model_files=( "${MODELS[@]##*/}" )
	local distfile_array=( "${model_files[@]/#/${DISTDIR}/}" )

	# Install system ML models (but not test models).
	insinto /opt/google/chrome/ml_models
	doins "${distfile_array[@]}"

	# Install system ML models to fuzzer dir.
	insinto /usr/libexec/fuzzers
	doins "${distfile_array[@]}"

	# Install fuzzer targets.
	for fuzzer in "${OUT}"/*_fuzzer; do
		platform_fuzzer_install "${S}"/OWNERS "${fuzzer}"
	done
}

pkg_preinst() {
	enewuser "ml-service"
	enewgroup "ml-service"
}

platform_pkg_test() {
	# Recreate model dir in the temp directory (for use in unit tests).
	mkdir "${T}/ml_models" || die
	local distfile_uri
	for distfile_uri in "${MODELS[@]}"; do
		cp "${DISTDIR}/${distfile_uri##*/}" "${T}/ml_models" || die
	done

	platform_test "run" "${OUT}/ml_service_test"
}
