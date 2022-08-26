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
	@echo "=== Packing to tarball"
	@cd ${BUILD_DIR}/${PLATFORM} &&\
	tar -czf \
		${ROOT_DIR}/dist/solaris_exporter-${VERSION}-${PLATFORM}.tar.gz \
		./


binary-distribution: wheel download-deps
	@echo "=== Create binary distribution"
	@mkdir -p ${BUILD_DIR}/${PLATFORM}/dist-packages
	@find \
		${BUILD_DIR}/packages/${PLATFORM} \
		${BUILD_DIR}/wheel \
		${VENDOR_DIR}/${PLATFORM} \
		-maxdepth 1 \
		-type f \
		-name '*.whl' \
		-exec \
			unzip -q -u '{}' -d ${BUILD_DIR}/${PLATFORM}/dist-packages \; 
	

	@cp ${VENDOR_DIR}/run.sh ${BUILD_DIR}/${PLATFORM}
	@chmod +x ${BUILD_DIR}/${PLATFORM}/run.sh


wheel: build-dir
	@echo "=== Create wheel package"
	@poetry build \
		--no-interaction \
		--format wheel 
	@cp dist/*.whl ${BUILD_DIR}
	@cp dist/*.whl ${BUILD_DIR}/wheel


download-deps: requirements-file 
	@echo "=== Downlaod project pependencies"
	@poetry run python -m pip download \
		--no-input ${PIP_EXTRA_OPTIONS} \
		-r ${BUILD_DIR}/requirements-without-vendored.txt \
		--platform ${PLATFORM} \
		--only-binary=:all: \
		--quiet


requirements-file: build-dir
	@echo "=== Create pip requirenments files"
	@poetry export \
		--without-hashes \
		--no-interaction \
		> ${BUILD_DIR}/poetry-requirements.txt
	@poetry run python3 vendor/package_filter.py \
		--input-file ${BUILD_DIR}/poetry-requirements.txt \
		--output-file ${BUILD_DIR}/requirements-without-vendored.txt \
		--vendor-dir vendor/${PLATFORM}


build-dir:
	@echo "=== Create build/ directory"
	@mkdir -p ${BUILD_DIR}/${PLATFORM}
	@mkdir -p ${BUILD_DIR}/packages/${PLATFORM}
	@mkdir -p ${BUILD_DIR}/wheel


clean:
	@echo "=== Clean-up build/ and dist/ directories"
	@rm -rf ${BUILD_DIR} dist/
