PACMAN_ANDROID_PKG_NAME="glibc"
PACMAN_ANDROID_PKG_VERSION="2.43.9000"
PACMAN_ANDROID_PKG_REVERSION="1"
PACMAN_ANDROID_PKG_DESCRIPTION="The GNU C Library provides many of the low-level components used directly by programs written in the C or C++ languages."
PACMAN_ANDROID_PKG_URL="https://sourceware.org/git/glibc.git"
PACMAN_ANDROID_PKG_LICENSES=("MIT")
PACMAN_ANDROID_PKG_TARGETS=("x86_64" "i686" "armhf" "aarch64")
PACMAN_ANDROID_PKG_SRCURL="https://github.com/xingguangcuican6666/glibc-pacman-android/archive/refs/tags/v${PACMAN_ANDROID_PKG_VERSION}.tar.gz"
PACMAN_ANDROID_PKG_SHA256="48018955c54feca2cd3754f0522098865272452f00ce1dbad897b1a10308edfc"
PACMAN_ANDROID_PKG_BUILD_SYSTEM="autotools"

# glibc is stricter than the generic autotools path: it needs optimization,
# a native compiler for build helpers, and it should not inherit package-wide
# PIE link flags intended for executables.
pacman_android_recipe_prepare() {
  export BUILD_CC="${BUILD_CC:-$(command -v cc || command -v gcc)}"
  export CFLAGS="$PACMAN_ANDROID_COMMON_CFLAGS -O2"
  export CXXFLAGS="$PACMAN_ANDROID_COMMON_CFLAGS -O2"
  export LDFLAGS=""
}


pacman_android_recipe_configure() {
  pacman_android_require_source_worktree glibc
  pacman_android_prepare_kernel_headers

  rm -rf "$PACMAN_ANDROID_AUTOTOOLS_BUILD_DIR"
  mkdir -p "$PACMAN_ANDROID_AUTOTOOLS_BUILD_DIR"

  local build_triple
  build_triple="$(gcc -dumpmachine 2>/dev/null || cc -dumpmachine)"

  (
    cd "$PACMAN_ANDROID_AUTOTOOLS_BUILD_DIR"
    bash "$PACMAN_ANDROID_SOURCE_WORKTREE/configure" \
      --build="$build_triple" \
      --host="$PACMAN_ANDROID_LIBRARY_TRIPLE" \
      --prefix="$PACMAN_ANDROID_PREFIX" \
      --sysconfdir="$PACMAN_ANDROID_SYSCONFDIR" \
      --with-headers="$PACMAN_ANDROID_KERNEL_HEADERS_DIR" \
      --enable-kernel=3.2 \
      --disable-werror \
      "${PACMAN_ANDROID_PKG_EXTRA_CONFIGURE_ARGS[@]}"
  )
}
