PACMAN_ANDROID_PKG_NAME="linux-api-headers"
PACMAN_ANDROID_PKG_VERSION="7.1"
PACMAN_ANDROID_PKG_REVERSION="1"
PACMAN_ANDROID_PKG_DESCRIPTION="Kernel headers sanitized for use in userspace"
PACMAN_ANDROID_PKG_URL="https://www.kernel.org/"
PACMAN_ANDROID_PKG_LICENSES=("GPL-2.0-only")
PACMAN_ANDROID_PKG_TARGETS=("x86_64" "i686" "armhf" "aarch64")
PACMAN_ANDROID_PKG_SRCURL="https://www.kernel.org/pub/linux/kernel/v${PACMAN_ANDROID_PKG_VERSION%%.*}.x/linux-${PACMAN_ANDROID_PKG_VERSION}.tar.xz"
PACMAN_ANDROID_PKG_SHA256="691f44797fbe790dc8a321604c927087526ad27b6d649925d60f8eed0a2564a0"
PACMAN_ANDROID_PKG_BUILD_SYSTEM="none"

pacman_android_recipe_build() {
  (
    cd "$PACMAN_ANDROID_SOURCE_WORKTREE"
    unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS CC CXX AR RANLIB NM OBJCOPY OBJDUMP READELF STRIP LD
    export PATH="/usr/bin:/bin"
    make ARCH="$PACMAN_ANDROID_LINUX_ARCH" mrproper
  )
}


pacman_android_recipe_install() {
  (
    cd "$PACMAN_ANDROID_SOURCE_WORKTREE"
    make \
      ARCH="$PACMAN_ANDROID_LINUX_ARCH" \
      INSTALL_HDR_PATH="$PACMAN_ANDROID_ROOTFS_DIR/usr" \
      headers_install
  )

  rm -rf "$PACMAN_ANDROID_ROOTFS_DIR/usr/include/drm"
}
