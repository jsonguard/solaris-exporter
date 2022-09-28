# target platform for which the standalone package is built
PLATFORM=solaris-2.10-sun4v

# extra options for pip
PIP_EXTRA_OPTIONS=

### serivce variables
VERSION=$(shell poetry version --short)
ROOT_DIR=$(shell pwd)

### variables for ips packaging
IPS_PACKAGE_CATEGORY=monitoring
IPS_PACKAGE_NAME=solaris_exporter
IPS_PACKAGE_VERSION=${VERSION}
IPS_PACKAGE_RELEASE_BUILD=5.10

# root directory where pkg will place package files
# starts with /pub/ 
PREFIX=site/${IPS_PACKAGE_NAME}
IPS_ROOT_DIR=${PREFIX}
# grep pattern for directories which pkg will create
# all the previos folders will be removed from the package manifest
IPS_MKDIR_STARTING_FROM=${IPS_ROOT_DIR}

# group and owner for package files in target machine
# these entries nust exist, pkg will not create its
IPS_FILES_OWNER=root
IPS_FILES_GROUP=bin

### internal
# package frmi for p5m manifest and publishing
IPS_PACKAGE_FMRI=${IPS_PACKAGE_CATEGORY}/${IPS_PACKAGE_NAME}@${IPS_PACKAGE_VERSION},${IPS_PACKAGE_RELEASE_BUILD}
# build directory
BUILD_DIR=build
# directory with vendored packages
VENDOR_DIR=vendor

all: wheel tarball
	@echo "=== Done! Results available in dist/ directory"


ips-publish: ips-manifest
	@echo "=== Publish IPS package"
	@cd ${BUILD_DIR}/ips/${PLATFORM}/root	&&\
		pkgsend publish \
			${IPS_PACKAGE_FMRI}	\
			../${IPS_PACKAGE_NAME}.p5m	 


ips-manifest: ips-buildroot
	@echo "=== Generate IPS manifest"

	@cd ${BUILD_DIR}/ips/${PLATFORM}	&&\
		export PKG_REPO=${IPS_PKG_REPO} &&\
		pkgsend generate \
			./root \
			| \
				grep "${IPS_MKDIR_STARTING_FROM}" > ${IPS_PACKAGE_NAME}.struct \
			&& \
		sed -i "s#owner=root#owner=${IPS_FILES_OWNER}#g" ${IPS_PACKAGE_NAME}.struct &&\
		sed -i "s#group=bin#group=${IPS_FILES_GROUP}#g" ${IPS_PACKAGE_NAME}.struct &&\
	echo "Generate contents structure: ${BUILD_DIR}/ips/${PLATFORM}/${IPS_PACKAGE_NAME}.struct"

	@export \
	 	PKG_FMRI=${IPS_PACKAGE_FMRI} \
		PKG_SUMMARY="Some summary" \
		PKG_DESCRIPTION="Some description" \
		PKG_ARCH=sparc \
		&& \
	envsubst \
		< vendor/ips-manifest.mod.tempalte \
		> ${BUILD_DIR}/ips/${PLATFORM}/${IPS_PACKAGE_NAME}.mod \
		&& \
	echo "Generate pkmod: ${BUILD_DIR}/ips/${PLATFORM}/${IPS_PACKAGE_NAME}.mod"

	@cd ${BUILD_DIR}/ips/${PLATFORM}	&&\
		cat ${IPS_PACKAGE_NAME}.mod > ${IPS_PACKAGE_NAME}.p5m  &&\
		echo "\n\n" >> ${IPS_PACKAGE_NAME}.p5m  &&\
		cat ${IPS_PACKAGE_NAME}.struct >> ${IPS_PACKAGE_NAME}.p5m  &&\
		echo "\n\n" >> ${IPS_PACKAGE_NAME}.p5m  &&\
		\
	echo "Generate manifest: ${BUILD_DIR}/ips/${PLATFORM}/${IPS_PACKAGE_NAME}.p5m"


ips-buildroot: build-dir
	@echo "=== Creatte IPS buildroot"
	@cd ${BUILD_DIR}/ips/${PLATFORM}/root/ &&\
		mkdir -p ${IPS_ROOT_DIR}
	@tar -xzf \
		${ROOT_DIR}/dist/solaris_exporter-${VERSION}-${PLATFORM}.tar.gz \
		-C ${BUILD_DIR}/ips/${PLATFORM}/root/${IPS_ROOT_DIR}
 

tarball: binary-distribution
	@echo "=== Packing to tarball"
	@rm -f ${ROOT_DIR}/dist/solaris_exporter-${VERSION}-${PLATFORM}.tar.gz
	@cd ${BUILD_DIR}/${PLATFORM} &&\
	tar -czf \
		${ROOT_DIR}/dist/solaris_exporter-${VERSION}-${PLATFORM}.tar.gz \
		./


binary-distribution: wheel download-deps
	@echo "=== Create binary distribution"
	@rm -rf ${BUILD_DIR}/${PLATFORM}/dist-packages
	@mkdir -p ${BUILD_DIR}/${PLATFORM}/dist-packages
	@find \
		${BUILD_DIR}/packages/${PLATFORM} \
		${BUILD_DIR}/wheel \
		${VENDOR_DIR}/${PLATFORM} \
		-maxdepth 1 \
		-type f \
		-name '*.whl' \
		-exec \
			unzip -q -o -u '{}' -d ${BUILD_DIR}/${PLATFORM}/dist-packages \; 
	
	@mkdir ${BUILD_DIR}/${PLATFORM}/bin
	@cp ${VENDOR_DIR}/init.sh ${BUILD_DIR}/${PLATFORM}/bin
	@chmod +x ${BUILD_DIR}/${PLATFORM}/bin/init.sh


wheel: build-dir
	@echo "=== Create wheel package"
	@poetry build \
		--no-interaction \
		--format wheel 
	@cp dist/*.whl ${BUILD_DIR}
	@cp dist/*.whl ${BUILD_DIR}/wheel


download-deps: requirements-file 
	@echo "=== Downlaod project dependencies"
	@poetry run python -m pip download \
		--no-input ${PIP_EXTRA_OPTIONS} \
		-r ${BUILD_DIR}/requirements-without-vendored.txt \
		--platform ${PLATFORM} \
		--only-binary=:all: \
		--dest ${BUILD_DIR}/packages/${PLATFORM} \
		--exists-action w \
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
	@echo "=== Create build directory"
	@mkdir -p ${BUILD_DIR}/${PLATFORM}
	@mkdir -p ${BUILD_DIR}/packages/${PLATFORM}
	@mkdir -p ${BUILD_DIR}/wheel
	@mkdir -p ${BUILD_DIR}/ips/${PLATFORM}/root


clean:
	@echo "=== Clean-up build/ and dist/ directories"
	@rm -rf ${BUILD_DIR} dist/
