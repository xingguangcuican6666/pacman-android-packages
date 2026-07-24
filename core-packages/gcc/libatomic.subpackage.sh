_gcc_internal_libdir="usr/lib/gcc/${PACMAN_ANDROID_LIBRARY_TRIPLE}/${PACMAN_ANDROID_PKG_VERSION%%.*}"

PACMAN_ANDROID_SUBPKG_DESCRIPTION="GNU Atomic library shipped by GCC"
PACMAN_ANDROID_SUBPKG_DEPENDS=("glibc")
PACMAN_ANDROID_SUBPKG_PROVIDES=("libatomic.so")
PACMAN_ANDROID_SUBPKG_INCLUDE_PATTERNS=(
  "usr/lib/libatomic.so*"
  "${_gcc_internal_libdir}/libatomic.so"
)
