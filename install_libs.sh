#!/bin/bash
set -e #-x uncomment for verbose output

if [ $# -lt 1 ]
then
  echo "Usage : install_libs.sh [stable|experimental]"
  echo "No/invalid parameter provided, assuming you want to get stable versions."
  STABLE=true
else
  if [ "$1" = "stable" ]
  then
    STABLE=true
  else if [ "$1" = "experimental" ]
    then
      echo -e "You chose \"experimental\" meaning you will be using the latest version of every library available.\nYou will break compatibility for other programs in case of major revision.\nYou will most likely have to adapt the zlib patch for the nth time.\nYou will suffer adapting harfbuzz from autotools to meson.\nYou will regret it."
      read -p "Press Enter to confirm your suffering."
    else
      echo "No/invalid parameter provided, assuming you want to get stable versions."
    fi
  fi
fi

LIBDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# path to cross tools root; another popular path is ${HOME}/x-tools
CROSS_TC_PATH=${SYSROOT:=${HOME}/x-tools}
CROSS_TC=${CROSS_TC:=arm-kobo-linux-gnueabihf}

if [ ! -z "${SYSROOT}" ];
then
  SYSROOT=${CROSS_TC_PATH}/${CROSS_TC}/${CROSS_TC}/sysroot
else
  echo "[UB] SYSROOT already set and non empty, assuming its value is correct"
  read -p "Press any key to continue"
fi
CROSS=${CROSS:=${CROSS_TC_PATH}/${CROSS_TC}/bin/${CROSS_TC}}
PREFIX=${PREFIX:=${SYSROOT}/usr}

PARALLEL_JOBS=$(($(getconf _NPROCESSORS_ONLN 2> /dev/null || sysctl -n hw.ncpu 2> /dev/null || echo 0) + 1))

export AR=${CROSS}-ar
export AS=${CROSS}-as
export CC=${CROSS}-gcc
export CXX=${CROSS}-g++
export LD=${CROSS}-ld
export RANLIB=${CROSS}-ranlib

export PKG_CONFIG_PATH=""
export PKG_CONFIG_LIBDIR="${SYSROOT}/usr/lib/pkgconfig:${SYSROOT}/usr/share/pkgconfig"
export PKG_CONFIG="pkg-config"

CFLAGS_BASE="-O3 -march=armv7-a -mtune=cortex-a8 -mfpu=neon -mfloat-abi=hard -mthumb -pipe -D__arm__ -D__ARM_NEON__ -fPIC -fpie -pie -fno-omit-frame-pointer -funwind-tables -Wl,--no-merge-exidx-entries"
CFLAGS_OPT1="${CFLAGS_BASE} -ftree-vectorize -ffast-math -frename-registers -funroll-loops "
CFLAGS_LTO="${CFLAGS_OPT1} -fdevirtualize-at-ltrans -flto=5"

get_clean_repo()
{
    mkdir -p ${LIBDIR}/libs
    cd ${LIBDIR}/libs
    git clone --recurse-submodules $REPO $LOCALREPO || git -C $LOCALREPO pull
    cd ${LIBDIR}/libs/${LOCALREPO}
    if "$STABLE"
    then
	git reset --hard $STABLE_COMMIT
    else
	git reset --hard
    fi
    git clean -fdx
    if test -f ${LIBDIR}/patches/${LOCALREPO}.patch; then
        git apply ${LIBDIR}/patches/${LOCALREPO}.patch
    fi
}

## build zlib-ng without LTO
export CFLAGS=$CFLAGS_OPT1

#zlib-ng
#patch: zlib configure line 314: ARCH=armv7-a
REPO=https://github.com/zlib-ng/zlib-ng
LOCALREPO=zlib-ng
STABLE_COMMIT=94aacd8bd69b7bfafce14fbe7639274e11d92d51
get_clean_repo

./configure --prefix=${PREFIX} --zlib-compat
make -j$PARALLEL_JOBS && make install

export CFLAGS=$CFLAGS_LTO

#libb2
REPO=https://github.com/BLAKE2/libb2
LOCALREPO=libb2
STABLE_COMMIT=643decfbf8ae600c3387686754d74c84144950d1
get_clean_repo
sh autogen.sh --prefix=${PREFIX} --host=${CROSS_TC}
./configure --prefix=${PREFIX} --host=${CROSS_TC}
make -j$PARALLEL_JOBS && make install

#zstd
REPO=https://github.com/facebook/zstd
LOCALREPO=zstd
STABLE_COMMIT=5bae43b41130f5dd500b0dc8d427a2de4b4555e9
get_clean_repo

mkdir -p ${LIBDIR}/libs/${LOCALREPO}/build/cmake/build
cd ${LIBDIR}/libs/${LOCALREPO}/build/cmake/build
cmake -D ADDITIONAL_CXX_FLAGS="-lrt -fPIC" -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=${PREFIX} -DCMAKE_TOOLCHAIN_FILE=${LIBDIR}/${CROSS_TC}.cmake -DENABLE_NEON=ON -DNEON_INTRINSICS=ON ..
make -j$PARALLEL_JOBS && make install

#openssl
REPO="--single-branch --branch openssl-3.0 https://github.com/openssl/openssl"
LOCALREPO=openssl-3.0
STABLE_COMMIT=60dd10a535bb3b975a0302808e994f2ff250e9c9
get_clean_repo

./Configure linux-elf no-comp no-tests no-asm shared --prefix=${PREFIX} --openssldir=${PREFIX}
make -j$PARALLEL_JOBS && make install_sw

#pnglib
REPO=git://git.code.sf.net/p/libpng/code
LOCALREPO=pnglib
STABLE_COMMIT=c1cc0f3f4c3d4abd11ca68c59446a29ff6f95003
get_clean_repo

./configure --prefix=${PREFIX} --host=${CROSS_TC} --enable-arm-neon=yes
make -j$PARALLEL_JOBS && make install

#libjpeg-turbo
#needed: toolchain.cmake
REPO=https://github.com/libjpeg-turbo/libjpeg-turbo
LOCALREPO=libjpeg-turbo
STABLE_COMMIT=d7932a270921391c303b6ede6f1dfbd94290a3d8
get_clean_repo

mkdir -p ${LIBDIR}/libs/${LOCALREPO}/build
cd ${LIBDIR}/libs/${LOCALREPO}/build
cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=${PREFIX} -DCMAKE_TOOLCHAIN_FILE=${LIBDIR}/${CROSS_TC}.cmake -DENABLE_NEON=ON -DNEON_INTRINSICS=ON ..
make -j$PARALLEL_JOBS && make install

#expat
REPO=https://github.com/libexpat/libexpat
LOCALREPO=expat
STABLE_COMMIT=ef485e96a609565317ec8695bb7b18fdcf084217
get_clean_repo

cd ${LIBDIR}/libs/${LOCALREPO}/expat
./buildconf.sh
./configure --prefix=${PREFIX} --host=${CROSS_TC}
make -j$PARALLEL_JOBS && make install

#pcre
REPO=https://github.com/rurban/pcre
LOCALREPO=pcre
STABLE_COMMIT=24f9d8df0b8ddabc217ec4e7856a678e09f52773
get_clean_repo

./autogen.sh
./configure --prefix=${PREFIX} --host=${CROSS_TC} --enable-pcre2-16 --enable-jit --with-sysroot=${SYSROOT}
make -j$PARALLEL_JOBS && make install

#libfreetype without harfbuzz
REPO=https://github.com/freetype/freetype
LOCALREPO=freetype
STABLE_COMMIT=0ae7e607370cc66218ccfacf5de4db8a35424c2f
get_clean_repo

sh autogen.sh
./configure --prefix=${PREFIX} --host=${CROSS_TC} --enable-shared=yes --enable-static=yes --without-bzip2 --without-brotli --without-harfbuzz --without-png --disable-freetype-config
make -j$PARALLEL_JOBS && make install

#harfbuzz
REPO=https://github.com/harfbuzz/harfbuzz
LOCALREPO=harfbuzz
STABLE_COMMIT=93930fb1c49b851541e25870b25f77daed0fb5fe # reverting to last known working version, cf https://github.com/harfbuzz/harfbuzz/issues/4818
get_clean_repo

sh autogen.sh --prefix=${PREFIX} --host=${CROSS_TC} --enable-shared=yes --enable-static=yes --without-coretext --without-uniscribe --without-cairo --without-glib  --without-gobject --without-graphite2 --without-icu --with-freetype
make -j$PARALLEL_JOBS && make install

#libfreetype with harfbuzz
REPO=https://github.com/freetype/freetype
LOCALREPO=freetype
STABLE_COMMIT=0ae7e607370cc66218ccfacf5de4db8a35424c2f
get_clean_repo

sh autogen.sh 
./configure --prefix=${PREFIX} --host=${CROSS_TC} --enable-shared=yes --enable-static=yes --without-bzip2 --without-brotli --with-harfbuzz --with-png --disable-freetype-config
make -j$PARALLEL_JOBS && make install
