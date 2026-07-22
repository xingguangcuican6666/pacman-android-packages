#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLCHAIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$TOOLCHAIN_DIR/.." && pwd)"

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <x86_64|i686|armhf|aarch64>" >&2
  exit 1
fi

target="$1"

source "$TOOLCHAIN_DIR/targets.sh"
pacman_android_load_target "$target"

OUT_DIR="$REPO_ROOT/out/smoke/$target"
ROOTFS_DIR="$REPO_ROOT/out/rootfs/$target"
BIN_DIR="$ROOTFS_DIR/usr/bin"
BIN_PATH="$BIN_DIR/pacman-android-smoke"

mkdir -p "$OUT_DIR" "$BIN_DIR"

if [[ "${PACMAN_ANDROID_DRY_RUN:-0}" == "1" ]]; then
  NDK_DIR="${ANDROID_NDK_ROOT:-<resolved-at-runtime>}"
  CC="<resolved-at-runtime>/$(pacman_android_compiler_name)"
else
  NDK_DIR="$("$TOOLCHAIN_DIR/fetch-ndk.sh")"
  TOOLCHAIN_ROOT="$NDK_DIR/toolchains/llvm/prebuilt/linux-x86_64"
  SYSROOT="$TOOLCHAIN_ROOT/sysroot"
  CC="$TOOLCHAIN_ROOT/bin/$(pacman_android_compiler_name)"
  LLVM_READELF="$TOOLCHAIN_ROOT/bin/llvm-readelf"
fi

cat >"$OUT_DIR/target.env" <<EOF
PACMAN_ANDROID_TARGET=$PACMAN_ANDROID_TARGET
PACMAN_ANDROID_ABI=$PACMAN_ANDROID_ABI
PACMAN_ANDROID_API_LEVEL=$PACMAN_ANDROID_API_LEVEL
PACMAN_ANDROID_CLANG_TRIPLE=$PACMAN_ANDROID_CLANG_TRIPLE
PACMAN_ANDROID_CARGO_TRIPLE=$PACMAN_ANDROID_CARGO_TRIPLE
PACMAN_ANDROID_LIBRARY_TRIPLE=$PACMAN_ANDROID_LIBRARY_TRIPLE
PACMAN_ROOTDIR=$PACMAN_ROOTDIR
ANDROID_NDK_ROOT=$NDK_DIR
EOF

if [[ "${PACMAN_ANDROID_DRY_RUN:-0}" == "1" ]]; then
  cat "$OUT_DIR/target.env"
  exit 0
fi

"$CC" \
  --sysroot="$SYSROOT" \
  -D__ANDROID_API__="$PACMAN_ANDROID_API_LEVEL" \
  -DPACMAN_ANDROID_TARGET="\"$PACMAN_ANDROID_TARGET\"" \
  -DPACMAN_ANDROID_ROOTDIR="\"$PACMAN_ROOTDIR\"" \
  -fPIE \
  -pie \
  -O2 \
  "$TOOLCHAIN_DIR/smoke/hello.c" \
  -o "$BIN_PATH"

cp "$BIN_PATH" "$OUT_DIR/"
file "$BIN_PATH" >"$OUT_DIR/file.txt"
"$LLVM_READELF" -h "$BIN_PATH" >"$OUT_DIR/elf-header.txt"

tar -C "$ROOTFS_DIR" -cf "$OUT_DIR/rootfs.tar" .

cat >"$OUT_DIR/summary.txt" <<EOF
target=$PACMAN_ANDROID_TARGET
abi=$PACMAN_ANDROID_ABI
api=$PACMAN_ANDROID_API_LEVEL
compiler=$CC
binary=$BIN_PATH
rootdir=$PACMAN_ROOTDIR
EOF
