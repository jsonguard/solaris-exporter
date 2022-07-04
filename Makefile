# target platform for which the standalone package is built
PLATFORM=macosx-12-arm64

# extra options for pip
PIP_EXTRA_OPTIONS=

# build directory
BUILD_DIR=build

# directory with vendored packages
VENDOR_DIR=vendor

### serivce variables
VERSION=$(shell poetry version --short)
ROOT_DIR=$(shell pwd)


all: wheel tarball


tarball: binary-distribution
	@cd ${BUILD_DIR}/${PLATFORM} &&\
	tar -czf \
		${ROOT_DIR}/dist/solaris_exporter-${VERSION}-${PLATFORM}.tar.gz \
		./

binary-distribution: wheel download-deps
	@mkdir -p ${BUILD_DIR}/${PLATFORM}/dist-packages
	@find ${BUILD_DIR}/packages/${PLATFORM} \
		-type f \
		-name '*.whl' \
		-exec \
			unzip -u '{}' -d ${BUILD_DIR}/${PLATFORM}/dist-packages \; 
	
	@unzip -u dist/*.whl -d ${BUILD_DIR}/${PLATFORM}/dist-packages

	@cp ${VENDOR_DIR}/run.sh ${BUILD_DIR}/${PLATFORM}
	@chmod +x ${BUILD_DIR}/${PLATFORM}/run.sh


wheel:
	@poetry build \
		--no-interaction \
		--format wheel


download-deps: requirements-file 
	poetry run pip download \
		--no-input ${PIP_EXTRA_OPTIONS} \
		-r ${BUILD_DIR}/requirements.txt \
		--platform ${PLATFORM} \
		--only-binary=:all: \
		--dest ${BUILD_DIR}/packages/${PLATFORM} \
		${VENDOR_DIR}/${PLATFORM}/*


requirements-file: build-dir
	@poetry export \
		--without-hashes \
		--no-interaction \
		> ${BUILD_DIR}/requirements.txt


build-dir:
	@mkdir -p ${BUILD_DIR}/${PLATFORM}
	@mkdir -p ${BUILD_DIR}/packages/${PLATFORM}


clean:
	@rm -rf ${BUILD_DIR} dist/
