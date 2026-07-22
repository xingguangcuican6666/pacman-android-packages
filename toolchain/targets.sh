#!/usr/bin/env bash
set -euo pipefail

pacman_android_load_target() {
  if [[ $# -ne 1 ]]; then
    echo "usage: pacman_android_load_target <target>" >&2
    return 1
  fi

  local target="$1"
  : "${ANDROID_API_LEVEL:=24}"
  : "${PACMAN_ROOTDIR:=/data/adb/pacman}"

  export PACMAN_ANDROID_TARGET="$target"
  export PACMAN_ANDROID_API_LEVEL="$ANDROID_API_LEVEL"
  export PACMAN_ROOTDIR
  export PACMAN_ANDROID_PREFIX="/usr"
  export PACMAN_ANDROID_SYSCONFDIR="/etc"

  case "$target" in
    x86_64)
      export PACMAN_ANDROID_ABI="x86_64"
      export PACMAN_ANDROID_CLANG_TRIPLE="x86_64-linux-android"
      export PACMAN_ANDROID_CARGO_TRIPLE="x86_64-linux-android"
      export PACMAN_ANDROID_LIBRARY_TRIPLE="x86_64-linux-android"
      ;;
    i686)
      export PACMAN_ANDROID_ABI="x86"
      export PACMAN_ANDROID_CLANG_TRIPLE="i686-linux-android"
      export PACMAN_ANDROID_CARGO_TRIPLE="i686-linux-android"
      export PACMAN_ANDROID_LIBRARY_TRIPLE="i686-linux-android"
      ;;
    armhf)
      export PACMAN_ANDROID_ABI="armeabi-v7a"
      export PACMAN_ANDROID_CLANG_TRIPLE="armv7a-linux-androideabi"
      export PACMAN_ANDROID_CARGO_TRIPLE="armv7-linux-androideabi"
      export PACMAN_ANDROID_LIBRARY_TRIPLE="arm-linux-androideabi"
      ;;
    aarch64)
      export PACMAN_ANDROID_ABI="arm64-v8a"
      export PACMAN_ANDROID_CLANG_TRIPLE="aarch64-linux-android"
      export PACMAN_ANDROID_CARGO_TRIPLE="aarch64-linux-android"
      export PACMAN_ANDROID_LIBRARY_TRIPLE="aarch64-linux-android"
      ;;
    *)
      echo "unsupported target: $target" >&2
      return 1
      ;;
  esac
}


pacman_android_compiler_name() {
  if [[ -z "${PACMAN_ANDROID_CLANG_TRIPLE:-}" || -z "${PACMAN_ANDROID_API_LEVEL:-}" ]]; then
    echo "target is not loaded" >&2
    return 1
  fi
  printf '%s%s-clang\n' "$PACMAN_ANDROID_CLANG_TRIPLE" "$PACMAN_ANDROID_API_LEVEL"
}


pacman_android_cxx_name() {
  if [[ -z "${PACMAN_ANDROID_CLANG_TRIPLE:-}" || -z "${PACMAN_ANDROID_API_LEVEL:-}" ]]; then
    echo "target is not loaded" >&2
    return 1
  fi
  printf '%s%s-clang++\n' "$PACMAN_ANDROID_CLANG_TRIPLE" "$PACMAN_ANDROID_API_LEVEL"
}
