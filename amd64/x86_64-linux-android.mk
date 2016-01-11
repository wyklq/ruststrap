# x86_64-linux-android configuration
CC_x86_64-linux-android=/opt/ndk/bin/x86_64-linux-android-gcc
CXX_x86_64-linux-android=/opt/ndk/bin/x86_64-linux-android-g++
CPP_x86_64-linux-android=/opt/ndk/bin/x86_64-linux-android-gcc -E
AR_x86_64-linux-android=/opt/ndk/bin/x86_64-linux-android-ar
CFG_LIB_NAME_x86_64-linux-android=lib$(1).so
CFG_STATIC_LIB_NAME_x86_64-linux-android=lib$(1).a
CFG_LIB_GLOB_x86_64-linux-android=lib$(1)-*.so
CFG_LIB_DSYM_GLOB_x86_64-linux-android=lib$(1)-*.dylib.dSYM
CFG_JEMALLOC_CFLAGS_x86_64-linux-android := -D__x86_64__ -DANDROID -D__ANDROID__ $(CFLAGS)
CFG_GCCISH_CFLAGS_x86_64-linux-android := -Wall -g -fPIC -D__x86_64__ -DANDROID -D__ANDROID__ $(CFLAGS)
CFG_GCCISH_CXXFLAGS_x86_64-linux-android := -fno-rtti $(CXXFLAGS)
CFG_GCCISH_LINK_FLAGS_x86_64-linux-android := -shared -fPIC -ldl -g -lm -lstdc++
CFG_GCCISH_DEF_FLAG_x86_64-linux-android := -Wl,--export-dynamic,--dynamic-list=
CFG_LLC_FLAGS_x86_64-linux-android :=
CFG_INSTALL_NAME_x86_64-linux-android =
CFG_EXE_SUFFIX_x86_64-linux-android :=
CFG_WINDOWSY_x86_64-linux-android :=
CFG_UNIXY_x86_64-linux-android := 1
CFG_LDPATH_x86_64-linux-android :=
CFG_RUN_x86_64-linux-android=$(2)
CFG_RUN_TARG_x86_64-linux-android=$(call CFG_RUN_x86_64-linux-android,,$(2))
RUSTC_FLAGS_x86_64-linux-android :=
RUSTC_CROSS_FLAGS_x86_64-linux-android :=
CFG_GNU_TRIPLE_x86_64-linux-android := x86_64-linux-android
