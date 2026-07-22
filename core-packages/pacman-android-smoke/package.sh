PACMAN_ANDROID_PKG_NAME="pacman-android-smoke"
PACMAN_ANDROID_PKG_VERSION="0.1.0"
PACMAN_ANDROID_PKG_REVERSION="1"
PACMAN_ANDROID_PKG_DESCRIPTION="Minimal Android-native smoke package for pacman-android-packages"
PACMAN_ANDROID_PKG_URL="https://github.com/xingguangcuican6666/pacman-android-packages"
PACMAN_ANDROID_PKG_LICENSES=("MIT")
PACMAN_ANDROID_PKG_TARGETS=("x86_64" "i686" "armhf" "aarch64")

pacman_android_recipe_build() {
  local binary="$PACMAN_ANDROID_BUILD_DIR/pacman-android-smoke"

  "$CC" \
    $PACMAN_ANDROID_COMMON_CFLAGS \
    -DPACMAN_ANDROID_TARGET="\"$PACMAN_ANDROID_TARGET\"" \
    -DPACMAN_ANDROID_ROOTDIR="\"$PACMAN_ROOTDIR\"" \
    "$PACMAN_ANDROID_REPO_ROOT/toolchain/smoke/hello.c" \
    $PACMAN_ANDROID_COMMON_LDFLAGS \
    -o "$binary"

  file "$binary" >"$PACMAN_ANDROID_BUILD_DIR/file.txt"
  "$READELF" -h "$binary" >"$PACMAN_ANDROID_BUILD_DIR/elf-header.txt"
}


pacman_android_recipe_install() {
  install -Dm755 \
    "$PACMAN_ANDROID_BUILD_DIR/pacman-android-smoke" \
    "$PACMAN_ANDROID_ROOTFS_DIR/usr/bin/pacman-android-smoke"

  install -Dm644 \
    "$PACMAN_ANDROID_REPO_ROOT/LICENSE" \
    "$PACMAN_ANDROID_ROOTFS_DIR/usr/share/licenses/$PACMAN_ANDROID_PKG_NAME/LICENSE"

  install -d "$PACMAN_ANDROID_ROOTFS_DIR/usr/share/doc/$PACMAN_ANDROID_PKG_NAME"
  cat >"$PACMAN_ANDROID_ROOTFS_DIR/usr/share/doc/$PACMAN_ANDROID_PKG_NAME/README.txt" <<EOF
pacman-android-smoke
target=$PACMAN_ANDROID_TARGET
rootdir=$PACMAN_ROOTDIR
EOF
}
