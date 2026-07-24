PACMAN_ANDROID_SUBPKG_DESCRIPTION="GNU Transactional Memory library shipped by GCC"
PACMAN_ANDROID_SUBPKG_DEPENDS=("glibc" "libgcc=${PACMAN_ANDROID_PKG_VERSION}-${PACMAN_ANDROID_PKG_REVERSION}")
PACMAN_ANDROID_SUBPKG_PROVIDES=("libitm.so")
PACMAN_ANDROID_SUBPKG_INCLUDE_PATTERNS=("usr/lib/libitm.a" "usr/lib/libitm.so*" "usr/share/info/libitm.info*")
