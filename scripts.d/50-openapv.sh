#!/bin/bash

SCRIPT_REPO="https://github.com/AcademySoftwareFoundation/openapv.git"
SCRIPT_COMMIT="9f6fd2a7369db90acec67d99fc57724f1136fb84"  # pre-1.x for n8.1.3 exact-tag builds (1-arg oapvm_create)

ffbuild_enabled() {
    (( $(ffbuild_ffver) > 701 )) || return -1
    return 0
}

ffbuild_dockerdl() {
    default_dl .
    echo "git fetch --unshallow --filter=blob:none"
}

ffbuild_dockerbuild() {
    # No need to build this
    echo > app/CMakeLists.txt

    mkdir build && cd build

    if [[ $TARGET == *32 ]]; then
        export CFLAGS="$CFLAGS -msse -msse2"
        export CXXFLAGS="$CXXFLAGS -msse -msse2"
    fi

    cmake -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN" -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX" -DCMAKE_BUILD_TYPE=Release \
        -DOAPV_APP_STATIC_BUILD=ON -DENABLE_TESTS=OFF ..

    make -j$(nproc)
    make install DESTDIR="$FFBUILD_DESTDIR"

    if [[ -f "$FFBUILD_DESTPREFIX"/lib/oapv/liboapv.a ]]; then
        mv "$FFBUILD_DESTPREFIX"/lib/oapv/liboapv.a "$FFBUILD_DESTPREFIX"/lib/liboapv.a
    fi

    sed -i \
        -e 's#\(includedir=.*\)/oapv#\1#' \
        -e 's#^Libs\.private:.*#Libs.private: -lm#' \
        "$FFBUILD_DESTPREFIX"/lib/pkgconfig/oapv.pc

    rm -rf "$FFBUILD_DESTPREFIX"/{bin,lib/oapv,lib/import,include/oapv/oapv_exports.h,lib/liboapv.so*}
}

ffbuild_configure() {
    echo --enable-liboapv
}

ffbuild_unconfigure() {
    (( $(ffbuild_ffver) > 701 )) || return 0
    echo --disable-liboapv
}
