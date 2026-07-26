_gcc_internal_libdir="usr/lib/gcc/${PACMAN_ANDROID_LIBRARY_TRIPLE}/${PACMAN_ANDROID_PKG_VERSION%%.*}"

PACMAN_ANDROID_SUBPKG_DESCRIPTION="Fortran front-end for GCC"
PACMAN_ANDROID_SUBPKG_DEPENDS=(
  "gcc=${PACMAN_ANDROID_PKG_VERSION}-${PACMAN_ANDROID_PKG_REVERSION}"
  "libgfortran=${PACMAN_ANDROID_PKG_VERSION}-${PACMAN_ANDROID_PKG_REVERSION}"
  "glibc"
)
PACMAN_ANDROID_SUBPKG_INCLUDE_PATTERNS=(
  "usr/bin/gfortran"
  "usr/bin/${PACMAN_ANDROID_LIBRARY_TRIPLE}-gfortran"
  "${_gcc_internal_libdir}/f951"
  "${_gcc_internal_libdir}/finclude"
  "${_gcc_internal_libdir}/include/ISO_Fortran_binding.h"
  "usr/lib/libgfortran.spec"
  "usr/share/info/gfortran.info*"
  "usr/share/man/man1/gfortran.1*"
)
