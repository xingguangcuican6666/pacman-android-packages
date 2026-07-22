#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

: "${ANDROID_NDK_VERSION:=29}"
: "${ANDROID_NDK_REVISION:=}"
: "${PACMAN_ANDROID_VENDOR_DIR:=$REPO_ROOT/vendor}"

NDK_VERSION="${ANDROID_NDK_VERSION}${ANDROID_NDK_REVISION}"
DEFAULT_NDK_DIR="$PACMAN_ANDROID_VENDOR_DIR/android-ndk-r${NDK_VERSION}"
NDK_DIR="${ANDROID_NDK_ROOT:-$DEFAULT_NDK_DIR}"
NDK_ARCHIVE="$PACMAN_ANDROID_VENDOR_DIR/android-ndk-r${NDK_VERSION}-linux.zip"
NDK_URL="https://dl.google.com/android/repository/android-ndk-r${NDK_VERSION}-linux.zip"
TOOLCHAIN_BIN="$NDK_DIR/toolchains/llvm/prebuilt/linux-x86_64/bin/clang"

case "$NDK_VERSION" in
  29)
    NDK_SHA256="4abbbcdc842f3d4879206e9695d52709603e52dd68d3c1fff04b3b5e7a308ecf"
    ;;
  23c)
    NDK_SHA256="6ce94604b77d28113ecd588d425363624a5228d9662450c48d2e4053f8039242"
    ;;
  *)
    echo "unsupported Android NDK version: $NDK_VERSION" >&2
    exit 1
    ;;
esac

if [[ -x "$TOOLCHAIN_BIN" ]]; then
  printf '%s\n' "$NDK_DIR"
  exit 0
fi

mkdir -p "$PACMAN_ANDROID_VENDOR_DIR"

if [[ ! -f "$NDK_ARCHIVE" ]]; then
  curl --fail --location --retry 5 --retry-all-errors \
    --output "$NDK_ARCHIVE" \
    "$NDK_URL"
fi

echo "${NDK_SHA256}  ${NDK_ARCHIVE}" | sha256sum --check --status

tmpdir="$(mktemp -d "$PACMAN_ANDROID_VENDOR_DIR/.ndk-extract.XXXXXX")"
trap 'rm -rf "$tmpdir"' EXIT

unzip -q "$NDK_ARCHIVE" -d "$tmpdir"
rm -rf "$NDK_DIR"
mv "$tmpdir/android-ndk-r${NDK_VERSION}" "$NDK_DIR"

printf '%s\n' "$NDK_DIR"
