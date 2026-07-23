PACMAN_ANDROID_PKG_NAME="glibc"
PACMAN_ANDROID_PKG_VERSION="2.43.9000"
PACMAN_ANDROID_PKG_REVERSION="1"
PACMAN_ANDROID_PKG_DESCRIPTION="The GNU C Library provides many of the low-level components used directly by programs written in the C or C++ languages."
PACMAN_ANDROID_PKG_URL="https://sourceware.org/git/glibc.git"
PACMAN_ANDROID_PKG_LICENSES=("MIT")
PACMAN_ANDROID_PKG_TARGETS=("x86_64" "i686" "armhf" "aarch64")
PACMAN_ANDROID_PKG_BUILD_DEPENDS=("core/linux-api-headers")
PACMAN_ANDROID_PKG_SRCURL="https://github.com/xingguangcuican6666/glibc-pacman-android/archive/refs/tags/v${PACMAN_ANDROID_PKG_VERSION}.tar.gz"
PACMAN_ANDROID_PKG_SHA256="48018955c54feca2cd3754f0522098865272452f00ce1dbad897b1a10308edfc"
PACMAN_ANDROID_PKG_BUILD_SYSTEM="autotools"

# glibc is stricter than the generic autotools path: it needs optimization,
# a native compiler for build helpers, and it should not inherit package-wide
# PIE link flags intended for executables.
pacman_android_recipe_prepare() {
  local -a glibc_common_cflags=()
  local -a glibc_extra_cflags=(-O2)
  local flag

  for flag in $PACMAN_ANDROID_COMMON_CFLAGS; do
    if [[ "$flag" == "-D__ANDROID_API__=$PACMAN_ANDROID_API_LEVEL" ]]; then
      continue
    fi
    glibc_common_cflags+=("$flag")
  done

  case "$PACMAN_ANDROID_TARGET" in
    x86_64|i686)
      glibc_extra_cflags+=(-fno-emulated-tls -mlong-double-80)
      ;;
    aarch64)
      glibc_extra_cflags+=(-fno-emulated-tls -mno-outline-atomics)
      ;;
  esac

  export BUILD_CC="${BUILD_CC:-$(command -v cc || command -v gcc)}"
  export CFLAGS="${glibc_common_cflags[*]} ${glibc_extra_cflags[*]}"
  export CXXFLAGS="${glibc_common_cflags[*]} ${glibc_extra_cflags[*]}"
  export LDFLAGS=""
}

pacman_android_glibc_android_fixups() {
  local glibc_src="$PACMAN_ANDROID_SOURCE_WORKTREE"
  case "$PACMAN_ANDROID_TARGET" in
    aarch64)
      local glibc_makefile="$glibc_src/elf/Makefile"
      local pointer_guard="$glibc_src/sysdeps/unix/sysv/linux/aarch64/pointer_guard.h"
      local system_property_stub="$glibc_src/elf/system-property-stub.c"

      if ! grep -q '^#  include <stdint.h>$' "$pointer_guard"; then
        perl -0pi -e 's@# else\n@# else\n#  include <stdint.h>\n@' "$pointer_guard"
      fi

      if ! grep -q 'system-property-stub\.os' "$glibc_makefile"; then
        awk '/^--- a\/elf\/Makefile$/ { print; next }
             /^(\+\+\+|@@)/ { print; next }
             /done > \$@T/ {
               print
               print "\tprintf '\''%s\\n'\'' '\''rtld-csu +=errno.os'\'' \\"
               print "\t\t       '\''rtld-elf +=system-property-stub.os'\'' \\"
               print "\t\t       '\''rtld-misc +=memfd_create.os'\'' >> $@T"
               next
             }
             { print }' "$glibc_makefile" > "$glibc_makefile.new"
        mv -f "$glibc_makefile.new" "$glibc_makefile"
      fi

      cat > "$system_property_stub" <<'EOF'
/* Android's NDK can inject Android-only symbols into rtld LTO output.
   Provide local fallbacks so ld.so does not depend on bionic.  */

#include <errno.h>

int
__system_property_get (const char *name, char *value)
{
  (void) name;
  if (value != 0)
    value[0] = '\0';

  return 0;
}

int
memfd_create (const char *name, unsigned int flags)
{
  (void) name;
  (void) flags;
  __set_errno (ENOSYS);
  return -1;
}
EOF
      ;;
    x86_64|i686)
      local glibc_makefile="$glibc_src/elf/Makefile"
      local math_makefile="$glibc_src/math/Makefile"
      local x86_floatn="$glibc_src/sysdeps/x86/bits/floatn.h"
      local x86_float128_abi="$glibc_src/sysdeps/x86/float128-abi.h"
      local x86_math_barriers="$glibc_src/sysdeps/x86/fpu/math-barriers.h"
      local x86_mulxc3="$glibc_src/math/mulxc3.c"
      local x86_divxc3="$glibc_src/math/divxc3.c"

      if ! grep -q '^rtld-csu +=errno\.os$' "$glibc_makefile"; then
        awk '/done > \$@T/ {
               print
               print "\tprintf '\''%s\\n'\'' '\''rtld-csu +=errno.os'\'' >> $@T"
               next
             }
             { print }' "$glibc_makefile" > "$glibc_makefile.new"
        mv -f "$glibc_makefile.new" "$glibc_makefile"
      fi

      if ! grep -q '^#if defined __ANDROID__ && defined __clang__ && (defined __x86_64__ || defined __i386__)$' "$x86_floatn"; then
        awk '
          !done && /^#if \(defined __x86_64__/ {
            print "#if defined __ANDROID__ && defined __clang__ && (defined __x86_64__ || defined __i386__)"
            print "# define __HAVE_FLOAT128 0"
            sub(/^#if /, "#elif ")
            done = 1
          }
          { print }
        ' "$x86_floatn" > "$x86_floatn.new"
        mv -f "$x86_floatn.new" "$x86_floatn"
      fi

      cat > "$x86_float128_abi" <<'EOF'
/* No _Float128 ABI support on Android x86 targets.  */
EOF

      cat > "$x86_math_barriers" <<'EOF'
/* Control when floating-point expressions are evaluated.  x86 version.
   Copyright (C) 2007-2026 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, see
   <https://www.gnu.org/licenses/>.  */

#ifndef X86_MATH_BARRIERS_H
#define X86_MATH_BARRIERS_H 1

#if defined __HAVE_FLOAT128 && __HAVE_FLOAT128
# define X86_MATH_BARRIER_USES_FLOAT128(x) \
  __builtin_types_compatible_p (__typeof (x), _Float128)
#else
# define X86_MATH_BARRIER_USES_FLOAT128(x) 0
#endif

#ifdef __SSE2_MATH__
# define math_opt_barrier(x)						\
  ({ __typeof(x) __x;							\
     if (sizeof (x) <= sizeof (double)					\
	|| X86_MATH_BARRIER_USES_FLOAT128 (x))			\
       __asm ("" : "=x" (__x) : "0" (x));				\
     else								\
       __asm ("" : "=t" (__x) : "0" (x));				\
     __x; })
# define math_force_eval(x)						\
  do {									\
    if (sizeof (x) <= sizeof (double)					\
	|| X86_MATH_BARRIER_USES_FLOAT128 (x))			\
      __asm __volatile ("" : : "x" (x));				\
    else								\
      __asm __volatile ("" : : "f" (x));				\
  } while (0)
#else
# define math_opt_barrier(x)						\
  ({ __typeof (x) __x;							\
     if (X86_MATH_BARRIER_USES_FLOAT128 (x))				\
       {								\
	 __x = (x);							\
	 __asm ("" : "+m" (__x));					\
       }								\
     else								\
       __asm ("" : "=t" (__x) : "0" (x));				\
     __x; })
# define math_force_eval(x)						\
  do {									\
    __typeof (x) __x = (x);						\
    if (sizeof (x) <= sizeof (double)					\
	|| X86_MATH_BARRIER_USES_FLOAT128 (x))			\
      __asm __volatile ("" : : "m" (__x));				\
    else								\
      __asm __volatile ("" : : "f" (__x));				\
  } while (0)
#endif

#endif
EOF

      sed '0,/__multc3/s//__mulxc3/' "$glibc_src/math/multc3.c" > "$x86_mulxc3"
      sed '0,/__divtc3/s//__divxc3/' "$glibc_src/math/divtc3.c" > "$x86_divxc3"

      if ! grep -q '^libm-routines += mulxc3 divxc3$' "$math_makefile"; then
        awk '
          /^libm-routines \+= mulxc3 divxc3$/ { next }
          /^# These functions are in libc instead of libm/ && !done {
            print "libm-routines += mulxc3 divxc3"
            print ""
            done = 1
          }
          { print }
        ' "$math_makefile" > "$math_makefile.new"
        mv -f "$math_makefile.new" "$math_makefile"
      fi

      if [[ "$PACMAN_ANDROID_TARGET" == "x86_64" ]]; then
        local x86_64_implies="$glibc_src/sysdeps/x86_64/Implies"

        if grep -qx 'ieee754/float128' "$x86_64_implies"; then
          grep -vx 'ieee754/float128' "$x86_64_implies" > "$x86_64_implies.new"
          mv -f "$x86_64_implies.new" "$x86_64_implies"
        fi
      else
        local i386_implies="$glibc_src/sysdeps/i386/Implies"

        if grep -qx 'ieee754/float128' "$i386_implies"; then
          grep -vx 'ieee754/float128' "$i386_implies" > "$i386_implies.new"
          mv -f "$i386_implies.new" "$i386_implies"
        fi
      fi
      ;;
  esac
}


pacman_android_recipe_configure() {
  pacman_android_require_source_worktree glibc
  pacman_android_glibc_android_fixups

  rm -rf "$PACMAN_ANDROID_AUTOTOOLS_BUILD_DIR"
  mkdir -p "$PACMAN_ANDROID_AUTOTOOLS_BUILD_DIR"

  local build_triple
  local compiler_rt_builtins
  local libgcc_compat_dir
  build_triple="$(gcc -dumpmachine 2>/dev/null || cc -dumpmachine)"
  compiler_rt_builtins="$("$CC" -rtlib=compiler-rt --print-libgcc-file-name)"

  if [[ -z "$compiler_rt_builtins" || "$compiler_rt_builtins" == "libgcc.a" || ! -f "$compiler_rt_builtins" ]]; then
    echo "failed to resolve compiler-rt builtins archive for glibc: $compiler_rt_builtins" >&2
    exit 1
  fi

  libgcc_compat_dir="$PACMAN_ANDROID_AUTOTOOLS_BUILD_DIR/libgcc-compat"
  rm -rf "$libgcc_compat_dir"
  mkdir -p "$libgcc_compat_dir"
  ln -s "$compiler_rt_builtins" "$libgcc_compat_dir/libgcc.a"
  export LDFLAGS="-L$libgcc_compat_dir"
  cat > "$PACMAN_ANDROID_AUTOTOOLS_BUILD_DIR/configparms" <<'EOF'
build-programs = no
EOF

  (
    cd "$PACMAN_ANDROID_AUTOTOOLS_BUILD_DIR"
    bash "$PACMAN_ANDROID_SOURCE_WORKTREE/configure" \
      --build="$build_triple" \
      --host="$PACMAN_ANDROID_LIBRARY_TRIPLE" \
      --prefix="$PACMAN_ANDROID_PREFIX" \
      --sysconfdir="$PACMAN_ANDROID_SYSCONFDIR" \
      --with-headers="$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR/usr/include" \
      --enable-kernel=3.2 \
      --disable-werror \
      "${PACMAN_ANDROID_PKG_EXTRA_CONFIGURE_ARGS[@]}"
  )
}
