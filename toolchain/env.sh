#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/targets.sh"


pacman_android_prepare_environment() {
  if [[ $# -ne 1 ]]; then
    echo "usage: pacman_android_prepare_environment <target>" >&2
    return 1
  fi

  local target="$1"
  pacman_android_load_target "$target"

  if [[ "${PACMAN_ANDROID_DRY_RUN:-0}" == "1" ]]; then
    export PACMAN_ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT:-<resolved-at-runtime>}"
    export PACMAN_ANDROID_TOOLCHAIN_ROOT="${PACMAN_ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64"
    export PACMAN_ANDROID_SYSROOT="${PACMAN_ANDROID_TOOLCHAIN_ROOT}/sysroot"
    export PACMAN_ANDROID_CC="${PACMAN_ANDROID_TOOLCHAIN_ROOT}/bin/$(pacman_android_compiler_name)"
    export PACMAN_ANDROID_CXX="${PACMAN_ANDROID_TOOLCHAIN_ROOT}/bin/$(pacman_android_cxx_name)"
  else
    export PACMAN_ANDROID_NDK_ROOT="$("$SCRIPT_DIR/fetch-ndk.sh")"
    export PACMAN_ANDROID_TOOLCHAIN_ROOT="$PACMAN_ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64"
    export PACMAN_ANDROID_SYSROOT="$PACMAN_ANDROID_TOOLCHAIN_ROOT/sysroot"
    export PACMAN_ANDROID_CC="$PACMAN_ANDROID_TOOLCHAIN_ROOT/bin/$(pacman_android_compiler_name)"
    export PACMAN_ANDROID_CXX="$PACMAN_ANDROID_TOOLCHAIN_ROOT/bin/$(pacman_android_cxx_name)"
  fi

  export PACMAN_ANDROID_AR="$PACMAN_ANDROID_TOOLCHAIN_ROOT/bin/llvm-ar"
  export PACMAN_ANDROID_RANLIB="$PACMAN_ANDROID_TOOLCHAIN_ROOT/bin/llvm-ranlib"
  export PACMAN_ANDROID_STRIP="$PACMAN_ANDROID_TOOLCHAIN_ROOT/bin/llvm-strip"
  export PACMAN_ANDROID_LD="$PACMAN_ANDROID_TOOLCHAIN_ROOT/bin/ld.lld"
  export PACMAN_ANDROID_NM="$PACMAN_ANDROID_TOOLCHAIN_ROOT/bin/llvm-nm"
  export PACMAN_ANDROID_READELF="$PACMAN_ANDROID_TOOLCHAIN_ROOT/bin/llvm-readelf"
  export PACMAN_ANDROID_OBJCOPY="$PACMAN_ANDROID_TOOLCHAIN_ROOT/bin/llvm-objcopy"
  export PACMAN_ANDROID_OBJDUMP="$PACMAN_ANDROID_TOOLCHAIN_ROOT/bin/llvm-objdump"

  export PACMAN_ANDROID_COMMON_CFLAGS="--sysroot=$PACMAN_ANDROID_SYSROOT -D__ANDROID_API__=$PACMAN_ANDROID_API_LEVEL -fPIC"
  export PACMAN_ANDROID_COMMON_LDFLAGS="-fPIE -pie"

  export CC="$PACMAN_ANDROID_CC"
  export CXX="$PACMAN_ANDROID_CXX"
  export AR="$PACMAN_ANDROID_AR"
  export RANLIB="$PACMAN_ANDROID_RANLIB"
  export STRIP="$PACMAN_ANDROID_STRIP"
  export LD="$PACMAN_ANDROID_LD"
  export NM="$PACMAN_ANDROID_NM"
  export READELF="$PACMAN_ANDROID_READELF"
  export OBJCOPY="$PACMAN_ANDROID_OBJCOPY"
  export OBJDUMP="$PACMAN_ANDROID_OBJDUMP"

  export CPPFLAGS="${CPPFLAGS:-}"
  export CFLAGS="$PACMAN_ANDROID_COMMON_CFLAGS${CFLAGS:+ $CFLAGS}"
  export CXXFLAGS="$PACMAN_ANDROID_COMMON_CFLAGS${CXXFLAGS:+ $CXXFLAGS}"
  export LDFLAGS="$PACMAN_ANDROID_COMMON_LDFLAGS${LDFLAGS:+ $LDFLAGS}"

  export PATH="$PACMAN_ANDROID_TOOLCHAIN_ROOT/bin:$PATH"
}
