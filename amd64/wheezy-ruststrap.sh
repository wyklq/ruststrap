#!/bin/bash

# Cross compiles an x86_64-linux-android rust compiler (build=host=x86_64-unknown-linux-gnu  target=x86_64-unknown-linux-gnu, x86_64-linux-android)
# Based on japaric/ruststrap/amd64/wheezy-ruststrap.sh
#
# Based on the blog post "Cross bootstrapping Rust" by Riad Wahby
# (http://github.jfet.org/Rust_cross_bootstrapping.html)

# only manual execution in the bash is successfully executed, not really working on the script
# line 11 to 24 are not covered.

# Run this script in a freshly debootstrapped Debian Wheezy rootfs
#
# $ cd /chroot
# $ debootstrap wheezy wheezy
# $ cd wheezy
# $ wget https://raw.githubusercontent.com/japaric/ruststrap/master/amd64/wheezy-ruststrap.sh
# $ chmod +x wheezy-ruststrap.sh
# $ systemd-nspawn ./wheezy-ruststrap.sh
# $ ls rust-*
# rust-2015-01-27-7774359-arm-unknown-linux-gnueabihf-38d44aaf0da4e5c359ff3551f3a88643ef5ca6e2.tar.gz

set -e
set -x

: ${DIST_DIR:=/dist}
: ${SRC_DIR:=/rust}
: ${TARGET:=x86_64-linux-android}
: ${TOOLCHAIN_TARGET:=x86_64-linux-android}   # Android NDK 10e provides the standalone tool with make-standalone-tools 

# install C cross compiler
#    install Android NDK 10e to, e.g. /opt/ndk
# install native C compiler
#    gcc-5  (NOTE: Android NDK 10e comes with GCC 4.9, and GCC 5 by default support a different ABI - c++11)
#             in order to make the ABI compatible, both gcc-5 and clang++ shall have CXXFLAGS=-D_GLIBCXX_USE_CXX11_ABI=0 defined.

# set default compilers -  lines 38 - 47 are not needed, because rust has defined options for Android cross compilation.
update-alternatives \
  --install /usr/bin/gcc gcc /usr/bin/gcc-4.7 50 \
  --slave /usr/bin/g++ g++ /usr/bin/g++-4.7 \
  --slave /usr/bin/arm-linux-gnueabihf-gcc arm-linux-gnueabihf-gcc /usr/bin/arm-linux-gnueabihf-gcc-4.7 \
  --slave /usr/bin/arm-linux-gnueabihf-g++ arm-linux-gnueabihf-g++ /usr/bin/arm-linux-gnueabihf-g++-4.7
gcc -v
g++ -v

# install Rust build dependencies
apt-get install -qq --force-yes curl file git python

# fetch rust
git clone --recursive https://github.com/rust-lang/rust $SRC_DIR
cd $SRC_DIR
git checkout $1

# Get information about HEAD
HEAD_HASH=$(git rev-parse --short HEAD)
HEAD_DATE=$(TZ=UTC date -d @$(git show -s --format=%ct HEAD) +'%Y-%m-%d')
TARBALL=rust-${HEAD_DATE}-${HEAD_HASH}-${TARGET}

# configure Rust
mkdir build
cd build
CXXFLAGS=-D_GLIBCXX_USE_CXX11_ABI=0 ../configure \
    --build=x86_64-unknown-linux-gnu \
    --host=x86_64-unknown-linux-gnu \
    --target=x86_64-unknown-linux-gnu,${TARGET}
cd x86_64-unknown-linux-gnu
find . -type d -exec mkdir -p ../${TARGET}/\{\} \;

# build cross LLVM
cd "$SRC_DIR"/build/x86_64-unknown-linux-gnu/llvm
CXXFLAGS=-D_GLIBCXX_USE_CXX11_ABI=0 "$SRC_DIR"/src/llvm/configure \
    --enable-targets=x86,x86_64,arm,aarch64,mips,powerpc \
    --enable-optimized \
    --enable-assertions \
    --disable-docs \
    --enable-bindings=none \
    --disable-terminfo \
    --disable-zlib \
    --disable-libffi \
    --with-python=/usr/bin/python2.7 \
    --build=x86_64-unknown-linux-gnu \
    --host=x86_64-unknown-linux-gnu \
    --target=x86_64-unknown-linux-gnu
make -j$(nproc)
cd "$SRC_DIR"/build/${TARGET}/llvm
CXXFLAGS=-D_GLIBCXX_USE_CXX11_ABI=0 "$SRC_DIR"/src/llvm/configure \
    --enable-targets=x86,x86_64,arm,aarch64,mips,powerpc \
    --enable-optimized \
    --enable-assertions \
    --disable-docs \
    --enable-bindings=none \
    --disable-terminfo \
    --disable-zlib \
    --disable-libffi \
    --with-python=/usr/bin/python2.7 \
    --build=x86_64-unknown-linux-gnu \
    --host=${TOOLCHAIN_TARGET} \
    --target=${TOOLCHAIN_TARGET}
make -j$(nproc)

# enable llvm-config for the cross build
cd "$SRC_DIR"/build/${TARGET}/llvm/Release+Asserts/bin

# because of same arch x86_64, the following 3 lines are not needed.
mv llvm-config llvm-config-arm
ln -s ../../BuildTools/Release+Asserts/bin/llvm-config
./llvm-config --cxxflags

# make Rust Build System use our LLVM build
TGT_STR=`echo ${TARGET} | sed 's/-/\\\\1/g'`
cd "$SRC_DIR"/build/
chmod 0644 config.mk
grep 'CFG_LLVM_[BI]' config.mk |                                          \
    sed "s/x86_64\(.\)unknown.linux.gnu/$TGT_STR/g" \
    >> config.mk

cd "$SRC_DIR"

#the following line doesn't work with the latest nightly build
#sed -i.bak 's/\([\t]*\)\(.*\$(MAKE).*\)/\1#\2/' mk/llvm.mk
#  following changes instead
#   < $(foreach host,$(CFG_HOST), \
#   ---
#   > $(foreach host,$(CFG_HOST) x86_64-linux-android, \
#   96a97
#   >

#the following line doesn't work
#sed -i.bak 's/^\(CROSS_PREFIX_'${TARGET}'=\)\(.*\)-$/\1'${TOOLCHAIN_TARGET}'-/' mk/platform.mk
# following changes instead:
#248a249,256
#> CROSS_PREFIX_x86_64-linux-android=/opt/ndk/bin/
#> CC_x86_64-linux-android=x86_64-linux-android-gcc
#> CXX_x86_64-linux-android=x86_64-linux-android-c++
#> CPP_x86_64-linux-android=x86_64-linux-android-cpp
#> AR_x86_64-linux-android=x86_64-linux-android-ar
#> LINK_x86_64-linux-android=x86_64-linux-android-ld
#> RUSTC_CROSS_FLAGS_x86_64-linux-android=-C linker=x86_64-linux-android-gcc -C ar=x86_64-linux-android-ar
#>

# build a working librustc for the cross architecture
cd "$SRC_DIR"

#the crates.mk still works, change the original host crates only into a target crates with both host and target
sed -i.bak \
    's/^CRATES := .*/TARGET_CRATES += $(HOST_CRATES)\nCRATES := $(TARGET_CRATES)/' \
    mk/crates.mk
    
#the main.mk works, it defines necessary LLVM variables for a new rustc target    
sed -i.bak \
    's/\(.*call DEF_LLVM_VARS.*\)/\1\n$(eval $(call DEF_LLVM_VARS,'${TARGET}'))/' \
    mk/main.mk
    
# changes to mk/llvm.mk
# sed -i.bak 's/foreach host,$(CFG_HOST)/foreach host,$(CFG_HOST) $(TARGET)/' mk/llvm.mk
# 95c95
# < $(foreach host,$(CFG_HOST), \
# ---
# > $(foreach host,$(CFG_HOST) x86_64-linux-android, \
# 96a97
# >

# the following line works
sed -i.bak 's/foreach host,$(CFG_HOST)/foreach host,$(CFG_TARGET)/' mk/rustllvm.mk
# and to workaround the ABI mismatch, one method to add CFLAGS is here
# 40a41,42
# > EXTRA_RUSTLLVM_CXXFLAGS_$(1) := -D_GLIBCXX_USE_CXX11_ABI=0
# >
# 60c62

cd "$SRC_DIR"
# the following change is not needed anymore in the latest nightly build
sed -i.bak 's/.*target_arch = .*//' src/etc/mklldeps.py

# the lines 176-181 are not necessary
cd "$SRC_DIR"/build
${TARGET}/llvm/Release+Asserts/bin/llvm-config --libs \
    | tr '-' '\n' | sort > arm
x86_64-unknown-linux-gnu/llvm/Release+Asserts/bin/llvm-config --libs \
    | tr '-' '\n' | sort > x86
diff arm x86 >/dev/null

#before making the build for x86_64-linux-android, adding a new target is required to do source code changes
$SRC_DIR/mk/cfg/x86_64-linux-android.mk  # this is needed for configurator to support a new target
$SRC_DIR/src/librustc_back/target/mod.rs # load a new target "x86_64-linux-android" shall be added, one line change
$SRC_DIR/src/librustc_back/target/x86_64_linux_android.rs  # a new target definition file, base.has_elf_tls=False;
$SRC_DIR/src/libstd/os/android/raw.rs   # a new arch variant of android os needs some special configuration
$SRC_DIR/src/librustdoc/flock.rs        # general bug of android support, patch specific to linux os is also application to android
$SRC_DIR/src/liblibc/src/unix/mod.rs    # bsd_signal is changed to signal in later revision of android

# build it, part 1
cd "$SRC_DIR"/build
make -j$(nproc)

# build it, part 2
cd "$SRC_DIR"/build
LD_LIBRARY_PATH=$PWD/x86_64-unknown-linux-gnu/stage2/lib/rustlib/x86_64-unknown-linux-gnu/lib:$LD_LIBRARY_PATH \
    ./x86_64-unknown-linux-gnu/stage2/bin/rustc --cfg stage2 -O --cfg rtopt                                    \
    -C linker=${TOOLCHAIN_TARGET}-g++ -C ar=${TOOLCHAIN_TARGET}-ar                                             \
    --cfg debug -C prefer-dynamic --target=${TARGET}                                         \
    -o x86_64-unknown-linux-gnu/stage2/lib/rustlib/${TARGET}/bin/rustc --cfg rustc           \
    $PWD/../src/driver/driver.rs
LD_LIBRARY_PATH=$PWD/x86_64-unknown-linux-gnu/stage2/lib/rustlib/x86_64-unknown-linux-gnu/lib:$LD_LIBRARY_PATH \
    ./x86_64-unknown-linux-gnu/stage2/bin/rustc --cfg stage2 -O --cfg rtopt                                    \
    -C linker=${TOOLCHAIN_TARGET}-g++ -C ar=${TOOLCHAIN_TARGET}-ar                                             \
    --cfg debug -C prefer-dynamic --target=${TARGET}                                         \
    -o x86_64-unknown-linux-gnu/stage2/lib/rustlib/${TARGET}/bin/rustdoc --cfg rustdoc       \
    $PWD/../src/driver/driver.rs

# ship it
mkdir -p "$DIST_DIR"/lib/rustlib/${TARGET}
cd "$DIST_DIR"
cp -R "$SRC_DIR"/build/x86_64-unknown-linux-gnu/stage2/lib/rustlib/${TARGET}/* \
    lib/rustlib/${TARGET}
mv lib/rustlib/${TARGET}/bin .
cd lib
for i in rustlib/${TARGET}/lib/*.so; do
  ln -s $i .
done
cd ..
tar czf ../${TARBALL}.tar.gz .
cd ..
RUST_HASH=$(sha1sum ${TARBALL}.tar.gz | cut -f 1 -d ' ')
mv ${TARBALL}.tar.gz ${TARBALL}-${RUST_HASH}.tar.gz
