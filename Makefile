# Copyright 2022 ByteDance Ltd. and/or its affiliates. SPDX license identifier: LGPL-2.1-or-later"

.PHONY: all clean lcm lcm-test

# please change to the right local path
# on error "Unknown host CPU architecture: arm64" (maybe Apple M1 Max etc), please copy android_build/ndk-build-for-m1 to your ndk path and use it.
NDK_BUILD := $(ANDROID_HOME)/ndk/24.0.8215888/ndk-build

MPG123_VERSION	:= 1.25.10
MPG123_BUILDDIR	:= temp/mpg123-${MPG123_VERSION}

ANDROID_ARCHS	:= armeabi-v7a arm64-v8a

BDMPG_VERSION	:= 0.1.7

define download_file
	@mkdir -p temp
	: download $(notdir $(1))
	@curl -# $(1) -o temp/$(notdir $(1))
endef

all: $(ANDROID_ARCHS:%=%/libbdmpg123.so)

clean: 
	rm -rf ${MPG123_BUILDDIR}/obj
	rm -rf ${MPG123_BUILDDIR}/libs
	rm -rf android

$(ANDROID_ARCHS:%=%/libbdmpg123.so): ${MPG123_BUILDDIR}/.stamp android_build/Android.mk
	mkdir -p ${MPG123_BUILDDIR}/jni android/include android/libs/armeabi-v7a android/libs/arm64-v8a
	cp -r android_build/bdmpg123.h android/include/
	cp -r android_build/* ${MPG123_BUILDDIR}/jni/
	cd ${MPG123_BUILDDIR}/jni; ${NDK_BUILD}
	cp -r ${MPG123_BUILDDIR}/obj/local/armeabi-v7a/*.so android/libs/armeabi-v7a/
	cp -r ${MPG123_BUILDDIR}/obj/local/arm64-v8a/*.so android/libs/arm64-v8a/

${MPG123_BUILDDIR}.tar.bz2: 
	$(call download_file,https://nchc.dl.sourceforge.net/project/mpg123/mpg123/${MPG123_VERSION}/$(notdir $@))

${MPG123_BUILDDIR}/.stamp: ${MPG123_BUILDDIR}.tar.bz2 
	tar jxf $< -C temp
	sed -i.bak "s/#define PRECALC_TABLES//" ${MPG123_BUILDDIR}/src/libmpg123/mpg123lib_intern.h
	touch $@

lcm:
	lcm package create -c ./lcm.yml -t ${BDMPG_VERSION}

lcm-test:
	lcm package get -r ${BDMPG_VERSION} -d ./temp -f lynx/third_party/bdmpg123/android
