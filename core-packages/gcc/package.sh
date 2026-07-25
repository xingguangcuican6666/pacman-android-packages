PACMAN_ANDROID_PKG_NAME="gcc"
PACMAN_ANDROID_PKG_VERSION="16.1.1+r346+g4e03491b401d"
PACMAN_ANDROID_PKG_REVERSION="1"
PACMAN_ANDROID_PKG_DESCRIPTION="The GNU Compiler Collection - C and C++ frontends"
PACMAN_ANDROID_PKG_URL="https://gcc.gnu.org"
PACMAN_ANDROID_PKG_MAINTAINER="xingguangcuican6666"
PACMAN_ANDROID_PKG_LICENSES=(
  "GPL-3.0-or-later WITH GCC-exception-3.1"
  "GFDL-1.3-or-later"
)
# GCC executes host-built compiler binaries during the recipe. The CI builder
# image therefore provides qemu-user so foreign-arch host tools remain runnable
# on the x86_64 GitHub Actions runner.
PACMAN_ANDROID_PKG_TARGETS=("x86_64" "i686" "armhf" "aarch64")
PACMAN_ANDROID_PKG_BUILD_DEPENDS=("core/glibc" "core/linux-api-headers")
PACMAN_ANDROID_PKG_BUILD_SYSTEM="none"
PACMAN_ANDROID_PKG_DEPENDS=("binutils" "glibc" "libasan=${PACMAN_ANDROID_PKG_VERSION}-${PACMAN_ANDROID_PKG_REVERSION}" "libgcc=${PACMAN_ANDROID_PKG_VERSION}-${PACMAN_ANDROID_PKG_REVERSION}" "libstdc++=${PACMAN_ANDROID_PKG_VERSION}-${PACMAN_ANDROID_PKG_REVERSION}" "libubsan=${PACMAN_ANDROID_PKG_VERSION}-${PACMAN_ANDROID_PKG_REVERSION}")
PACMAN_ANDROID_GCC_GIT_URL="https://github.com/gcc-mirror/gcc.git"
PACMAN_ANDROID_GCC_GIT_COMMIT="4e03491b401dce0658543dd90524ddb92063836e"

case "$PACMAN_ANDROID_TARGET" in
  x86_64)
    PACMAN_ANDROID_PKG_DEPENDS+=(
      "liblsan=${PACMAN_ANDROID_PKG_VERSION}-${PACMAN_ANDROID_PKG_REVERSION}"
      "libtsan=${PACMAN_ANDROID_PKG_VERSION}-${PACMAN_ANDROID_PKG_REVERSION}"
    )
    ;;
  aarch64)
    PACMAN_ANDROID_PKG_DEPENDS+=(
      "libhwasan=${PACMAN_ANDROID_PKG_VERSION}-${PACMAN_ANDROID_PKG_REVERSION}"
      "liblsan=${PACMAN_ANDROID_PKG_VERSION}-${PACMAN_ANDROID_PKG_REVERSION}"
      "libtsan=${PACMAN_ANDROID_PKG_VERSION}-${PACMAN_ANDROID_PKG_REVERSION}"
    )
    ;;
esac

pacman_android_gcc_major_version() {
  printf '%s\n' "${PACMAN_ANDROID_PKG_VERSION%%.*}"
}

pacman_android_gcc_internal_libdir() {
  printf '/usr/lib/gcc/%s/%s\n' "$PACMAN_ANDROID_LIBRARY_TRIPLE" "$(pacman_android_gcc_major_version)"
}

pacman_android_gcc_build_dir() {
  printf '%s\n' "$PACMAN_ANDROID_BUILD_DIR/gcc-build"
}

pacman_android_gcc_wrapper_dir() {
  printf '%s\n' "$PACMAN_ANDROID_BUILD_DIR/tool-wrappers"
}

pacman_android_gcc_host_cc_wrapper() {
  printf '%s/cc\n' "$(pacman_android_gcc_wrapper_dir)"
}

pacman_android_gcc_host_cxx_wrapper() {
  printf '%s/c++\n' "$(pacman_android_gcc_wrapper_dir)"
}

pacman_android_gcc_target_cc_wrapper() {
  printf '%s/%s-gcc\n' "$(pacman_android_gcc_wrapper_dir)" "$PACMAN_ANDROID_LIBRARY_TRIPLE"
}

pacman_android_gcc_target_cxx_wrapper() {
  printf '%s/%s-g++\n' "$(pacman_android_gcc_wrapper_dir)" "$PACMAN_ANDROID_LIBRARY_TRIPLE"
}

pacman_android_gcc_target_as_wrapper() {
  printf '%s/%s-as\n' "$(pacman_android_gcc_wrapper_dir)" "$PACMAN_ANDROID_LIBRARY_TRIPLE"
}

pacman_android_gcc_target_fortran_wrapper() {
  printf '%s/%s-gfortran\n' "$(pacman_android_gcc_wrapper_dir)" "$PACMAN_ANDROID_LIBRARY_TRIPLE"
}

pacman_android_gcc_target_tooldir() {
  printf '%s/%s\n' "$(pacman_android_gcc_build_dir)" "$PACMAN_ANDROID_LIBRARY_TRIPLE"
}

pacman_android_gcc_glibc_loader() {
  case "$PACMAN_ANDROID_TARGET" in
    x86_64) printf '/lib64/ld-linux-x86-64.so.2\n' ;;
    i686) printf '/lib/ld-linux.so.2\n' ;;
    armhf) printf '/lib/ld-linux.so.3\n' ;;
    aarch64) printf '/lib/ld-linux-aarch64.so.1\n' ;;
    *)
      echo "unsupported target for glibc loader: $PACMAN_ANDROID_TARGET" >&2
      exit 1
      ;;
  esac
}

pacman_android_gcc_target_exec_runner() {
  case "$PACMAN_ANDROID_TARGET" in
    x86_64)
      ;;
    i686)
      printf '%s\n' qemu-i386
      ;;
    armhf)
      printf '%s\n' qemu-arm
      ;;
    aarch64)
      printf '%s\n' qemu-aarch64
      ;;
    *)
      echo "unsupported target for exec runner: $PACMAN_ANDROID_TARGET" >&2
      exit 1
      ;;
  esac
}

pacman_android_gcc_glibc_libdirs() {
  case "$PACMAN_ANDROID_TARGET" in
    x86_64|aarch64)
      printf '%s\n' /lib64 /usr/lib64
      ;;
    i686|armhf)
      printf '%s\n' /lib /usr/lib
      ;;
    *)
      echo "unsupported target for glibc libdirs: $PACMAN_ANDROID_TARGET" >&2
      exit 1
      ;;
  esac
}

pacman_android_gcc_glibc_crt_dir() {
  case "$PACMAN_ANDROID_TARGET" in
    x86_64|aarch64)
      printf '%s\n' /usr/lib64
      ;;
    i686|armhf)
      printf '%s\n' /usr/lib
      ;;
    *)
      echo "unsupported target for glibc crt dir: $PACMAN_ANDROID_TARGET" >&2
      exit 1
      ;;
  esac
}

pacman_android_gcc_host_libcxx_dir() {
  case "$PACMAN_ANDROID_TARGET" in
    x86_64) printf '%s\n' "$PACMAN_ANDROID_TOOLCHAIN_ROOT/lib/x86_64-unknown-linux-gnu" ;;
    i686) printf '%s\n' "$PACMAN_ANDROID_TOOLCHAIN_ROOT/lib/i386-unknown-linux-gnu" ;;
    armhf) printf '%s\n' "$PACMAN_ANDROID_TOOLCHAIN_ROOT/lib/arm-unknown-linux-musleabihf" ;;
    aarch64) printf '%s\n' "$PACMAN_ANDROID_TOOLCHAIN_ROOT/lib/aarch64-unknown-linux-musl" ;;
    *)
      echo "unsupported target for host libc++ dir: $PACMAN_ANDROID_TARGET" >&2
      exit 1
      ;;
  esac
}

pacman_android_gcc_host_libcxx_include_dir() {
  printf '%s\n' "$PACMAN_ANDROID_SYSROOT/usr/include/c++/v1"
}

pacman_android_gcc_wrapper_include_dir() {
  printf '%s/include\n' "$(pacman_android_gcc_wrapper_dir)"
}

pacman_android_gcc_target_wrapper_include_dir() {
  printf '%s/target-include\n' "$(pacman_android_gcc_wrapper_dir)"
}

pacman_android_gcc_ndk_generic_include_dir() {
  printf '%s\n' "$PACMAN_ANDROID_SYSROOT/usr/include"
}

pacman_android_gcc_build_triple() {
  gcc -dumpmachine 2>/dev/null || cc -dumpmachine
}

pacman_android_gcc_disable_libgfortran_caf_shmem() {
  local gcc_source_dir
  gcc_source_dir="$PACMAN_ANDROID_SOURCE_WORKTREE"

  # Android's bionic headers explicitly lack shm_open/shm_unlink, so disable
  # the caf_shmem backend and keep the portable libcaf_single runtime.
  perl -0pi -e 's/enable_caf_shmem=true/enable_caf_shmem=false/' \
    "$gcc_source_dir/libgfortran/configure" \
    "$gcc_source_dir/libgfortran/configure.ac"
}

pacman_android_gcc_patch_libstdcxx_bionic_ctype_base() {
  local ctype_base
  ctype_base="$PACMAN_ANDROID_SOURCE_WORKTREE/libstdc++-v3/config/os/bionic/ctype_base.h"

  # GCC's bionic ctype_base.h still expects legacy _U/_L/_N masks, but
  # current NDK bionic exposes the _CTYPE_* names instead.
  perl -0pi -e '
    s/\b_U\b/_CTYPE_U/g;
    s/\b_L\b/_CTYPE_L/g;
    s/\b_N\b/_CTYPE_N/g;
    s/\b_X\b/_CTYPE_X/g;
    s/\b_S\b/_CTYPE_S/g;
    s/\b_P\b/_CTYPE_P/g;
    s/\b_B\b/_CTYPE_B/g;
    s/\b_C\b/_CTYPE_C/g;
  ' "$ctype_base"
}

pacman_android_gcc_disable_x86_64_android_libhwasan() {
  local configure_tgt
  configure_tgt="$PACMAN_ANDROID_SOURCE_WORKTREE/libsanitizer/configure.tgt"

  # x86_64 Android rejects ifunc, while upstream's generic x86_64-linux case
  # enables HWASAN and builds hwasan_dynamic_shadow.cpp unconditionally.
  if grep -F 'x86_64-*-linux-android*)' "$configure_tgt" >/dev/null; then
    return 0
  fi

  perl -0pi -e 's@^  \Qx86_64-*-linux* | i?86-*-linux*)\E$@  x86_64-*-linux-android*)\n\tif test x\$ac_cv_sizeof_void_p = x8; then\n\t\tTSAN_SUPPORTED=yes\n\t\tLSAN_SUPPORTED=yes\n\t\tTSAN_TARGET_DEPENDENT_OBJECTS=tsan_rtl_amd64.lo\n\tfi\n\t;;\n$&@m' "$configure_tgt"

  if ! grep -F 'x86_64-*-linux-android*)' "$configure_tgt" >/dev/null; then
    echo "failed to patch libsanitizer/configure.tgt for x86_64 Android libhwasan" >&2
    exit 1
  fi
}

pacman_android_gcc_allow_skipping_foreign_selftests() {
  local gcc_makefile_in
  gcc_makefile_in="$PACMAN_ANDROID_SOURCE_WORKTREE/gcc/Makefile.in"

  perl -0pi -e 's!SELFTEST_TARGETS = \@selftest_languages\@!ifdef PACMAN_ANDROID_SKIP_GCC_SELFTESTS\nSELFTEST_TARGETS =\nelse\nSELFTEST_TARGETS = \@selftest_languages\@\nendif!' "$gcc_makefile_in"

  if ! grep -F 'ifdef PACMAN_ANDROID_SKIP_GCC_SELFTESTS' "$gcc_makefile_in" >/dev/null; then
    echo "failed to patch gcc/Makefile.in for foreign selftest skipping" >&2
    exit 1
  fi
}

pacman_android_gcc_write_host_wrappers() {
  local wrapper_dir wrapper_include_dir target_wrapper_include_dir cc_wrapper cxx_wrapper crt_dir glibc_loader glibc_crt_dir host_libcxx_dir host_libcxx_include_dir ndk_generic_include_dir target_exec_runner
  local target_cc_wrapper target_cxx_wrapper target_as_wrapper target_fortran_wrapper build_dir target_tooldir
  local host_locale_header
  local -a glibc_libdirs=()
  local libdir

  wrapper_dir="$(pacman_android_gcc_wrapper_dir)"
  wrapper_include_dir="$(pacman_android_gcc_wrapper_include_dir)"
  target_wrapper_include_dir="$(pacman_android_gcc_target_wrapper_include_dir)"
  cc_wrapper="$(pacman_android_gcc_host_cc_wrapper)"
  cxx_wrapper="$(pacman_android_gcc_host_cxx_wrapper)"
  target_cc_wrapper="$(pacman_android_gcc_target_cc_wrapper)"
  target_cxx_wrapper="$(pacman_android_gcc_target_cxx_wrapper)"
  target_as_wrapper="$(pacman_android_gcc_target_as_wrapper)"
  target_fortran_wrapper="$(pacman_android_gcc_target_fortran_wrapper)"
  build_dir="$(pacman_android_gcc_build_dir)"
  target_tooldir="$(pacman_android_gcc_target_tooldir)"
  crt_dir="$PACMAN_ANDROID_SYSROOT/usr/lib/$PACMAN_ANDROID_LIBRARY_TRIPLE/$PACMAN_ANDROID_API_LEVEL"
  glibc_loader="$(pacman_android_gcc_glibc_loader)"
  glibc_crt_dir="$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR$(pacman_android_gcc_glibc_crt_dir)"
  host_locale_header="$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR/usr/include/locale.h"
  host_libcxx_dir="$(pacman_android_gcc_host_libcxx_dir)"
  host_libcxx_include_dir="$(pacman_android_gcc_host_libcxx_include_dir)"
  ndk_generic_include_dir="$(pacman_android_gcc_ndk_generic_include_dir)"
  target_exec_runner="$(pacman_android_gcc_target_exec_runner || true)"
  mapfile -t glibc_libdirs < <(pacman_android_gcc_glibc_libdirs)

  rm -rf "$wrapper_dir"
  mkdir -p \
    "$wrapper_dir" \
    "$wrapper_include_dir" \
    "$wrapper_include_dir/android" \
    "$wrapper_include_dir/sys" \
    "$target_wrapper_include_dir" \
    "$target_wrapper_include_dir/android" \
    "$target_wrapper_include_dir/sys"

  cat >"$wrapper_include_dir/xlocale.h" <<EOF
#ifndef PACMAN_ANDROID_GCC_XLOCALE_H
#define PACMAN_ANDROID_GCC_XLOCALE_H

#include "$host_locale_header"

#endif
EOF

  cat >"$wrapper_include_dir/android/api-level.h" <<'EOF'
#pragma once

#include <android/versioning.h>
#include_next <android/api-level.h>
EOF

  cat >"$wrapper_include_dir/android/versioning.h" <<'EOF'
#pragma once

#define __BIONIC_AVAILABILITY(...)
#define __BIONIC_AVAILABILITY_GUARD(api_level) 1
#define __INTRODUCED_IN(api_level)
#define __DEPRECATED_IN(api_level, msg)
#define __REMOVED_IN(api_level, msg)
#define __INTRODUCED_IN_32(api_level)
#define __INTRODUCED_IN_64(api_level)
EOF

  cat >"$wrapper_include_dir/__config_site" <<'EOF'
#ifndef _LIBCPP___CONFIG_SITE
#define _LIBCPP___CONFIG_SITE

#define _LIBCPP_ABI_VERSION 1
#define _LIBCPP_ABI_NAMESPACE __1
#define _LIBCPP_ABI_FORCE_ITANIUM 0
#define _LIBCPP_ABI_FORCE_MICROSOFT 0
#define _LIBCPP_HAS_THREADS 1
#define _LIBCPP_HAS_MONOTONIC_CLOCK 1
#define _LIBCPP_HAS_TERMINAL 1
#define _LIBCPP_HAS_MUSL_LIBC 0
#define _LIBCPP_HAS_THREAD_API_PTHREAD 1
#define _LIBCPP_HAS_THREAD_API_EXTERNAL 0
#define _LIBCPP_HAS_THREAD_API_WIN32 0
#define _LIBCPP_HAS_THREAD_API_C11 0
#define _LIBCPP_HAS_VENDOR_AVAILABILITY_ANNOTATIONS 0
#define _LIBCPP_HAS_FILESYSTEM 1
#define _LIBCPP_HAS_RANDOM_DEVICE 1
#define _LIBCPP_HAS_LOCALIZATION 1
#define _LIBCPP_HAS_UNICODE 1
#define _LIBCPP_HAS_WIDE_CHARACTERS 1
#define _LIBCPP_HAS_TIME_ZONE_DATABASE 0
#define _LIBCPP_INSTRUMENTED_WITH_ASAN 0
#define _LIBCPP_PSTL_BACKEND_STD_THREAD
#define _LIBCPP_HARDENING_MODE_DEFAULT 2

#endif
EOF

  cat >"$target_wrapper_include_dir/android/api-level.h" <<'EOF'
#pragma once

#include <android/versioning.h>
#include_next <android/api-level.h>
EOF

  cat >"$target_wrapper_include_dir/android/versioning.h" <<'EOF'
#pragma once

#ifdef __clang__
#include_next <android/versioning.h>
#else
#define __BIONIC_AVAILABILITY(...)
#define __BIONIC_AVAILABILITY_GUARD(api_level) 1
#define __INTRODUCED_IN(api_level)
#define __DEPRECATED_IN(api_level, msg)
#define __REMOVED_IN(api_level, msg)
#define __INTRODUCED_IN_32(api_level)
#define __INTRODUCED_IN_64(api_level)
#endif
EOF

  cat >"$target_wrapper_include_dir/sys/cdefs.h" <<'EOF'
#pragma once

#ifndef __clang__
#define _Nonnull
#define _Nullable
#define _Null_unspecified
#define BIONIC_IOCTL_NO_SIGNEDNESS_OVERLOAD 1
#endif

#include_next <sys/cdefs.h>

#ifndef __clang__
#undef __BIONIC_COMPLICATED_NULLNESS
#define __BIONIC_COMPLICATED_NULLNESS
#undef __RENAME
#define __RENAME(x)
#undef __enable_if
#define __enable_if(cond, msg)
#undef __overloadable
#define __overloadable
#undef __clang_error_if
#define __clang_error_if(cond, msg)
#undef __clang_warning_if
#define __clang_warning_if(cond, msg)
#endif
EOF

  cat >"$target_wrapper_include_dir/string.h" <<'EOF'
#pragma once

#if defined(__cplusplus) && !defined(__clang__)
#include "bionic-gcc-string.h"
#else
#include_next <string.h>
#endif
EOF

  perl -0pe 's@/\* Const-correct overloads\. Placed after FORTIFY so we call those functions, if possible\. \*/\n#if defined\(__cplusplus\).*?#undef __prefer_this_overload\n#endif\n@@s' \
    "$ndk_generic_include_dir/string.h" >"$target_wrapper_include_dir/bionic-gcc-string.h"

  if cmp -s "$ndk_generic_include_dir/string.h" "$target_wrapper_include_dir/bionic-gcc-string.h"; then
    echo "failed to patch bionic string.h for GCC C++" >&2
    exit 1
  fi

  cat >"$cc_wrapper" <<EOF
#!/usr/bin/env bash
set -euo pipefail

args=(--sysroot="$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR" -B"$crt_dir")
linking=1

for arg in "\$@"; do
  case "\$arg" in
    -c|-E|-S|--version|-v|-V|-qversion)
      linking=0
      ;;
  esac
done

args+=(-isystem "$wrapper_include_dir" -idirafter "$ndk_generic_include_dir")

if [[ "\$linking" == "1" ]]; then
  args+=(-nostartfiles -Wl,--dynamic-linker="$glibc_loader" "$glibc_crt_dir/Scrt1.o" "$glibc_crt_dir/crti.o")
EOF

  for libdir in "${glibc_libdirs[@]}"; do
    cat >>"$cc_wrapper" <<EOF
  args+=(-L"$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR$libdir" -Wl,-rpath-link,"$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR$libdir")
EOF
  done

  cat >>"$cc_wrapper" <<EOF
  args+=("$glibc_crt_dir/crtn.o")
fi

exec "$PACMAN_ANDROID_CC" "\${args[@]}" "\$@"
EOF

  cat >"$cxx_wrapper" <<EOF
#!/usr/bin/env bash
set -euo pipefail

args=(--sysroot="$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR" -B"$crt_dir")
linking=1

for arg in "\$@"; do
  case "\$arg" in
    -c|-E|-S|--version|-v|-V|-qversion)
      linking=0
      ;;
  esac
done

args+=(-isystem "$wrapper_include_dir" -idirafter "$ndk_generic_include_dir")
args+=(-nostdinc++ -isystem "$host_libcxx_include_dir")

if [[ "\$linking" == "1" ]]; then
  args+=(-nostartfiles -Wl,--dynamic-linker="$glibc_loader" "$glibc_crt_dir/Scrt1.o" "$glibc_crt_dir/crti.o")
EOF

  for libdir in "${glibc_libdirs[@]}"; do
    cat >>"$cxx_wrapper" <<EOF
  args+=(-L"$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR$libdir" -Wl,-rpath-link,"$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR$libdir")
EOF
  done

  cat >>"$cxx_wrapper" <<EOF
  args+=(-nostdlib++ "$host_libcxx_dir/libc++.a" "$host_libcxx_dir/libc++abi.a" "$glibc_crt_dir/crtn.o")
fi

exec "$PACMAN_ANDROID_CXX" "\${args[@]}" "\$@"
EOF

cat >"$target_cc_wrapper" <<EOF
#!/usr/bin/env bash
set -euo pipefail

xgcc="$build_dir/gcc/xgcc"
frontend="$build_dir/gcc/cc1"
use_xgcc=0
frontend_only=0
preprocess_only=0
dump_macros=0
compile_only=0
needs_gcc_driver=0
assembly_source=0
linking=1
xgcc_runner="$target_exec_runner"
xgcc_ld_prefix="$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR"
target_sysroot="$PACMAN_ANDROID_SYSROOT"
target_crt_dir="$crt_dir"
target_wrapper_include_dir="$target_wrapper_include_dir"
target_arch_include="$PACMAN_ANDROID_SYSROOT/usr/include/$PACMAN_ANDROID_LIBRARY_TRIPLE"
target_include="/usr/$PACMAN_ANDROID_LIBRARY_TRIPLE/include"
target_sys_include="/usr/$PACMAN_ANDROID_LIBRARY_TRIPLE/sys-include"
filtered_args=()
fallback_args=()
skip_next=0
pending_isystem=0

for arg in "\$@"; do
  if [[ "\$pending_isystem" == "1" ]]; then
    pending_isystem=0
    case "\$arg" in
      "\$target_include"|"\$target_sys_include")
        continue
        ;;
      *)
        filtered_args+=(-isystem "\$arg")
        continue
        ;;
    esac
  fi

  if [[ "\$skip_next" == "1" ]]; then
    skip_next=0
    case "\$arg" in
      "\$target_include"|"\$target_sys_include")
        continue
        ;;
    esac
  fi

  case "\$arg" in
    -dumpspecs|-dumpmachine|-dumpfullversion|-dumpversion|-print-*|--print-*|--version|-v)
      use_xgcc=1
      ;;
    -S)
      frontend_only=1
      linking=0
      ;;
    -E)
      preprocess_only=1
      linking=0
      ;;
    -c)
      compile_only=1
      linking=0
      ;;
    -shared|-r)
      linking=0
      ;;
    -dM|-dD)
      dump_macros=1
      ;;
    -fbuilding-libgcc)
      needs_gcc_driver=1
      ;;
    *.s|*.S|*.asm)
      assembly_source=1
      ;;
    -lpthread)
      continue
      ;;
    --sysroot=*)
      continue
      ;;
    -isystem)
      pending_isystem=1
      continue
      ;;
  esac

  filtered_args+=("\$arg")
done

if [[ -x "\$xgcc" ]]; then
  # Foreign-arch xgcc under qemu is reliable for query, preprocess, and
  # compile-to-assembly phases, but not for full object production where the
  # driver has to chain further host-side helper tools. Keep the native x86_64
  # target on the full xgcc path.
  if [[ "\$use_xgcc" == "1" || "\$frontend_only" == "1" || ( "\$preprocess_only" == "1" && "\$dump_macros" == "1" ) || ( "\$needs_gcc_driver" == "1" && "\$compile_only" == "1" && "\$assembly_source" == "0" ) || ( -z "\$xgcc_runner" && -x "\$frontend" ) ]]; then
    if [[ "\$linking" == "1" ]]; then
      filtered_args+=(-static-libgcc)
    fi

    if [[ -n "\$xgcc_runner" ]]; then
      if ! command -v "\$xgcc_runner" >/dev/null 2>&1; then
        echo "\$(basename "\$0"): missing runner \$xgcc_runner for foreign-arch xgcc" >&2
        exit 1
      fi

      exec "\$xgcc_runner" -L "\$xgcc_ld_prefix" "\$xgcc" \
        -B"$build_dir/gcc/" \
        -B"\$target_crt_dir/" \
        --sysroot="\$target_sysroot" \
        -isystem "\$target_wrapper_include_dir" \
        -isystem "\$target_arch_include" \
        "\${filtered_args[@]}"
    fi

    exec -a "\$(basename "\$0")" "\$xgcc" \
      -B"$build_dir/gcc/" \
      -B"\$target_crt_dir/" \
      --sysroot="\$target_sysroot" \
      -isystem "\$target_wrapper_include_dir" \
      -isystem "\$target_arch_include" \
      "\${filtered_args[@]}"
  fi
fi

for arg in "\${filtered_args[@]}"; do
  case "\$arg" in
    -fbuilding-libgcc)
      continue
      ;;
  esac
  fallback_args+=("\$arg")
done

exec "$PACMAN_ANDROID_CC" \
  --sysroot="\$target_sysroot" \
  -B"\$target_crt_dir/" \
  -isystem "\$target_wrapper_include_dir" \
  -isystem "\$target_arch_include" \
  "\${fallback_args[@]}"
EOF

cat >"$target_cxx_wrapper" <<EOF
#!/usr/bin/env bash
set -euo pipefail

xgcc="$build_dir/gcc/xgcc"
frontend="$build_dir/gcc/cc1plus"
use_xgcc=0
frontend_only=0
preprocess_only=0
dump_macros=0
linking=1
xgcc_runner="$target_exec_runner"
xgcc_ld_prefix="$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR"
target_sysroot="$PACMAN_ANDROID_SYSROOT"
target_crt_dir="$crt_dir"
target_wrapper_include_dir="$target_wrapper_include_dir"
target_arch_include="$PACMAN_ANDROID_SYSROOT/usr/include/$PACMAN_ANDROID_LIBRARY_TRIPLE"
target_include="/usr/$PACMAN_ANDROID_LIBRARY_TRIPLE/include"
target_sys_include="/usr/$PACMAN_ANDROID_LIBRARY_TRIPLE/sys-include"
filtered_args=()
fallback_args=()
skip_next=0
pending_isystem=0

for arg in "\$@"; do
  if [[ "\$pending_isystem" == "1" ]]; then
    pending_isystem=0
    case "\$arg" in
      "\$target_include"|"\$target_sys_include")
        continue
        ;;
      *)
        filtered_args+=(-isystem "\$arg")
        continue
        ;;
    esac
  fi

  if [[ "\$skip_next" == "1" ]]; then
    skip_next=0
    case "\$arg" in
      "\$target_include"|"\$target_sys_include")
        continue
        ;;
    esac
  fi

  case "\$arg" in
    -dumpspecs|-dumpmachine|-dumpfullversion|-dumpversion|-print-*|--print-*|--version|-v)
      use_xgcc=1
      ;;
    -S)
      frontend_only=1
      linking=0
      ;;
    -E)
      preprocess_only=1
      linking=0
      ;;
    -c|-shared|-r)
      linking=0
      ;;
    -dM|-dD)
      dump_macros=1
      ;;
    -lpthread)
      continue
      ;;
    --sysroot=*)
      continue
      ;;
    -isystem)
      pending_isystem=1
      continue
      ;;
  esac

  filtered_args+=("\$arg")
done

if [[ -x "\$xgcc" ]]; then
  if [[ "\$use_xgcc" == "1" || "\$frontend_only" == "1" || ( "\$preprocess_only" == "1" && "\$dump_macros" == "1" ) || ( -z "\$xgcc_runner" && -x "\$frontend" ) ]]; then
    if [[ "\$linking" == "1" ]]; then
      filtered_args+=(-static-libgcc)
    fi

    if [[ -n "\$xgcc_runner" ]]; then
      if ! command -v "\$xgcc_runner" >/dev/null 2>&1; then
        echo "\$(basename "\$0"): missing runner \$xgcc_runner for foreign-arch xgcc" >&2
        exit 1
      fi

      exec "\$xgcc_runner" -L "\$xgcc_ld_prefix" "\$xgcc" \
        -B"$build_dir/gcc/" \
        -B"\$target_crt_dir/" \
        --sysroot="\$target_sysroot" \
        -isystem "\$target_wrapper_include_dir" \
        -isystem "\$target_arch_include" \
        "\${filtered_args[@]}"
    fi

    exec -a "\$(basename "\$0")" "\$xgcc" \
      -B"$build_dir/gcc/" \
      -B"\$target_crt_dir/" \
      --sysroot="\$target_sysroot" \
      -isystem "\$target_wrapper_include_dir" \
      -isystem "\$target_arch_include" \
      "\${filtered_args[@]}"
  fi
fi

for arg in "\${filtered_args[@]}"; do
  case "\$arg" in
    -fbuilding-libgcc)
      continue
      ;;
  esac
  fallback_args+=("\$arg")
done

clang_args=(
  --sysroot="\$target_sysroot"
  -B"\$target_crt_dir/"
  -isystem "\$target_wrapper_include_dir"
  -isystem "\$target_arch_include"
  -nostdinc++
)

if [[ "\$linking" == "1" ]]; then
  clang_args+=(-nostdlib++)
fi

exec "$PACMAN_ANDROID_CXX" "\${clang_args[@]}" "\${fallback_args[@]}"
EOF

  cat >"$target_as_wrapper" <<EOF
#!/usr/bin/env bash
set -euo pipefail

args=(-c)
tmpdir=

cleanup() {
  if [[ -n "\${tmpdir}" ]]; then
    rm -rf "\${tmpdir}"
  fi
}

trap cleanup EXIT

for arg in "\$@"; do
  case "\$arg" in
    --32|--64|--traditional-format)
      ;;
    *.s|*.S|*.asm)
      if [[ -f "\$arg" ]]; then
        if [[ -z "\${tmpdir}" ]]; then
          tmpdir="\$(mktemp -d)"
        fi

        patched="\$tmpdir/\$(basename "\$arg")"
        sed -E \
          -e 's/\\.section[[:space:]]+\\.eh_frame,\"aw\"(,@progbits)?/.section .eh_frame,\"a\",@unwind/g' \
          -e 's/\\.section[[:space:]]+\\.gcc_except_table,\"aw\"(,@progbits)?/.section .gcc_except_table,\"a\",@progbits/g' \
          "\$arg" >"\$patched"
        args+=("\$patched")
      else
        args+=("\$arg")
      fi
      ;;
    --*)
      args+=(-Xassembler "\$arg")
      ;;
    *)
      args+=("\$arg")
      ;;
  esac
done

exec "$PACMAN_ANDROID_CC" "\${args[@]}"
EOF

  cat >"$target_fortran_wrapper" <<EOF
#!/usr/bin/env bash
set -euo pipefail

xgcc="$build_dir/gcc/xgcc"
frontend="$build_dir/gcc/f951"
use_xgcc=0
linking=1
xgcc_runner="$target_exec_runner"
xgcc_ld_prefix="$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR"
target_sysroot="$PACMAN_ANDROID_SYSROOT"
target_crt_dir="$crt_dir"
target_wrapper_include_dir="$target_wrapper_include_dir"
target_arch_include="$PACMAN_ANDROID_SYSROOT/usr/include/$PACMAN_ANDROID_LIBRARY_TRIPLE"
target_include="/usr/$PACMAN_ANDROID_LIBRARY_TRIPLE/include"
target_sys_include="/usr/$PACMAN_ANDROID_LIBRARY_TRIPLE/sys-include"
filtered_args=()
skip_next=0
pending_isystem=0

for arg in "\$@"; do
  if [[ "\$pending_isystem" == "1" ]]; then
    pending_isystem=0
    case "\$arg" in
      "\$target_include"|"\$target_sys_include")
        continue
        ;;
      *)
        filtered_args+=(-isystem "\$arg")
        continue
        ;;
    esac
  fi

  if [[ "\$skip_next" == "1" ]]; then
    skip_next=0
    case "\$arg" in
      "\$target_include"|"\$target_sys_include")
        continue
        ;;
    esac
  fi

  case "\$arg" in
    -dumpspecs|-dumpmachine|-dumpfullversion|-dumpversion|-print-*|--print-*|--version|-v)
      use_xgcc=1
      ;;
    -c|-E|-S|-shared|-r)
      linking=0
      ;;
    -lpthread)
      continue
      ;;
    --sysroot=*)
      continue
      ;;
    -isystem)
      pending_isystem=1
      continue
      ;;
  esac

  filtered_args+=("\$arg")
done

if [[ -x "\$xgcc" && ( "\$use_xgcc" == "1" || -x "\$frontend" ) ]]; then
  if [[ "\$linking" == "1" ]]; then
    filtered_args+=(-static-libgcc)
  fi

  if [[ -n "\$xgcc_runner" ]]; then
    if ! command -v "\$xgcc_runner" >/dev/null 2>&1; then
      echo "\$(basename "\$0"): missing runner \$xgcc_runner for foreign-arch xgcc" >&2
      exit 1
    fi

    exec "\$xgcc_runner" -L "\$xgcc_ld_prefix" "\$xgcc" \
      -B"$build_dir/gcc/" \
      -B"\$target_crt_dir/" \
      --sysroot="\$target_sysroot" \
      -isystem "\$target_wrapper_include_dir" \
      -isystem "\$target_arch_include" \
      "\${filtered_args[@]}"
  fi

  exec -a "\$(basename "\$0")" "\$xgcc" \
    -B"$build_dir/gcc/" \
    -B"\$target_crt_dir/" \
    --sysroot="\$target_sysroot" \
    -isystem "\$target_wrapper_include_dir" \
    -isystem "\$target_arch_include" \
    "\${filtered_args[@]}"
fi

echo "\$(basename "\$0"): GCC Fortran frontend is not ready yet" >&2
exit 1
EOF

  chmod +x "$cc_wrapper" "$cxx_wrapper" "$target_cc_wrapper" "$target_cxx_wrapper" "$target_as_wrapper" "$target_fortran_wrapper"

  ln -sf "$(basename "$target_cc_wrapper")" "$wrapper_dir/${PACMAN_ANDROID_LIBRARY_TRIPLE}-cc"
  ln -sf "$(basename "$target_cxx_wrapper")" "$wrapper_dir/${PACMAN_ANDROID_LIBRARY_TRIPLE}-c++"
  ln -sf "$(basename "$target_cc_wrapper")" "$wrapper_dir/${PACMAN_ANDROID_LIBRARY_TRIPLE}-gccgo"
  ln -sf "$(basename "$target_cc_wrapper")" "$wrapper_dir/${PACMAN_ANDROID_LIBRARY_TRIPLE}-gdc"
  ln -sf "$(basename "$target_cc_wrapper")" "$wrapper_dir/${PACMAN_ANDROID_LIBRARY_TRIPLE}-gm2"
  ln -sf "$(basename "$target_cc_wrapper")" "$wrapper_dir/${PACMAN_ANDROID_LIBRARY_TRIPLE}-ga68"
  ln -sf "$PACMAN_ANDROID_AR" "$wrapper_dir/${PACMAN_ANDROID_LIBRARY_TRIPLE}-ar"
  ln -sf "$PACMAN_ANDROID_NM" "$wrapper_dir/${PACMAN_ANDROID_LIBRARY_TRIPLE}-nm"
  ln -sf "$PACMAN_ANDROID_RANLIB" "$wrapper_dir/${PACMAN_ANDROID_LIBRARY_TRIPLE}-ranlib"
  ln -sf "$PACMAN_ANDROID_STRIP" "$wrapper_dir/${PACMAN_ANDROID_LIBRARY_TRIPLE}-strip"
}

pacman_android_gcc_make_args() {
  local build_cflags="-O2"
  local target_cflags target_ldflags

  target_cflags="-O2"
  target_ldflags=""

  PACMAN_ANDROID_GCC_MAKE_ARGS=(
    MAKEINFO=true
    "CC_FOR_BUILD=${BUILD_CC:-$(command -v cc || command -v gcc)}"
    "CXX_FOR_BUILD=${BUILD_CXX:-$(command -v c++ || command -v g++)}"
    "CC=$(pacman_android_gcc_host_cc_wrapper)"
    "CXX=$(pacman_android_gcc_host_cxx_wrapper)"
    "AR=$PACMAN_ANDROID_AR"
    "AS=$(pacman_android_gcc_host_cc_wrapper)"
    "LD=$PACMAN_ANDROID_LD"
    "NM=$PACMAN_ANDROID_NM"
    "OBJCOPY=$PACMAN_ANDROID_OBJCOPY"
    "OBJDUMP=$PACMAN_ANDROID_OBJDUMP"
    "RANLIB=$PACMAN_ANDROID_RANLIB"
    "READELF=$PACMAN_ANDROID_READELF"
    "STRIP=$PACMAN_ANDROID_STRIP"
    "CPPFLAGS="
    "CFLAGS=$build_cflags"
    "CXXFLAGS=$build_cflags"
    "LDFLAGS="
    "CFLAGS_FOR_BUILD=${CFLAGS_FOR_BUILD:-$build_cflags}"
    "CXXFLAGS_FOR_BUILD=${CXXFLAGS_FOR_BUILD:-$build_cflags}"
    "CC_FOR_TARGET=$(pacman_android_gcc_wrapper_dir)/${PACMAN_ANDROID_LIBRARY_TRIPLE}-cc"
    "CXX_FOR_TARGET=$(pacman_android_gcc_wrapper_dir)/${PACMAN_ANDROID_LIBRARY_TRIPLE}-c++"
    "RAW_CXX_FOR_TARGET=$(pacman_android_gcc_wrapper_dir)/${PACMAN_ANDROID_LIBRARY_TRIPLE}-c++"
    "GCC_FOR_TARGET=$(pacman_android_gcc_target_cc_wrapper)"
    "AR_FOR_TARGET=$PACMAN_ANDROID_AR"
    "AS_FOR_TARGET=$(pacman_android_gcc_target_as_wrapper)"
    "GFORTRAN_FOR_TARGET=$(pacman_android_gcc_wrapper_dir)/${PACMAN_ANDROID_LIBRARY_TRIPLE}-gfortran"
    "LD_FOR_TARGET=$PACMAN_ANDROID_LD"
    "NM_FOR_TARGET=$PACMAN_ANDROID_NM"
    "OBJCOPY_FOR_TARGET=$PACMAN_ANDROID_OBJCOPY"
    "OBJDUMP_FOR_TARGET=$PACMAN_ANDROID_OBJDUMP"
    "RANLIB_FOR_TARGET=$PACMAN_ANDROID_RANLIB"
    "READELF_FOR_TARGET=$PACMAN_ANDROID_READELF"
    "STRIP_FOR_TARGET=$PACMAN_ANDROID_STRIP"
    "CFLAGS_FOR_TARGET=$target_cflags"
    "CXXFLAGS_FOR_TARGET=$target_cflags"
    "LDFLAGS_FOR_TARGET=$target_ldflags"
  )
}

pacman_android_gcc_build_targets() {
  printf '%s\n' \
    all-gcc \
    all-target-libgcc \
    all-target-libstdc++-v3 \
    all-target-libatomic \
    all-target-libgomp \
    all-target-libitm \
    all-target-libobjc \
    all-target-libquadmath \
    all-target-libsanitizer \
    all-target-libgfortran
}

pacman_android_gcc_install_targets() {
  printf '%s\n' \
    install-gcc \
    install-target-libgcc \
    install-target-libstdc++-v3 \
    install-target-libatomic \
    install-target-libgomp \
    install-target-libitm \
    install-target-libobjc \
    install-target-libquadmath \
    install-target-libsanitizer \
    install-target-libgfortran
}

pacman_android_recipe_prepare() {
  local cache_ref cache_repo gcc_source_dir

  cache_repo="$PACMAN_ANDROID_DISTFILES_DIR/gcc.git"
  cache_ref="refs/pacman-android/${PACMAN_ANDROID_GCC_GIT_COMMIT}"

  gcc_source_dir="$PACMAN_ANDROID_SOURCE_DIR/gcc"
  rm -rf "$gcc_source_dir"
  mkdir -p "$gcc_source_dir"
  mkdir -p "$PACMAN_ANDROID_DISTFILES_DIR"

  if [[ ! -d "$cache_repo" ]]; then
    git init --bare --initial-branch=main "$cache_repo" >/dev/null
  fi

  GIT_TERMINAL_PROMPT=0 git --git-dir="$cache_repo" fetch --depth 1 "$PACMAN_ANDROID_GCC_GIT_URL" "${PACMAN_ANDROID_GCC_GIT_COMMIT}:${cache_ref}"
  git --git-dir="$cache_repo" archive "$PACMAN_ANDROID_GCC_GIT_COMMIT" | tar -x -C "$gcc_source_dir"

  export PACMAN_ANDROID_SOURCE_WORKTREE="$gcc_source_dir"
  export PACMAN_ANDROID_SOURCE_ROOT="$gcc_source_dir"
  pacman_android_gcc_disable_libgfortran_caf_shmem
  pacman_android_gcc_patch_libstdcxx_bionic_ctype_base
  pacman_android_gcc_disable_x86_64_android_libhwasan
  pacman_android_gcc_allow_skipping_foreign_selftests

  export BUILD_CC="${BUILD_CC:-$(command -v cc || command -v gcc)}"
  export BUILD_CXX="${BUILD_CXX:-$(command -v c++ || command -v g++)}"
  export CONFIG_SHELL="$(command -v bash)"
  pacman_android_gcc_write_host_wrappers
  export PATH="$(pacman_android_gcc_wrapper_dir):$PATH"

  (
    cd "$PACMAN_ANDROID_SOURCE_WORKTREE"
    ./contrib/download_prerequisites --directory="$PACMAN_ANDROID_SOURCE_WORKTREE" --no-isl
  )
}

pacman_android_recipe_configure() {
  local build_dir build_triple
  build_dir="$(pacman_android_gcc_build_dir)"
  build_triple="$(pacman_android_gcc_build_triple)"

  rm -rf "$build_dir"
  mkdir -p "$build_dir"

  (
    cd "$build_dir"
    CC="$(pacman_android_gcc_host_cc_wrapper)" \
    CXX="$(pacman_android_gcc_host_cxx_wrapper)" \
    AR="$PACMAN_ANDROID_AR" \
    AS="$(pacman_android_gcc_host_cc_wrapper)" \
    LD="$PACMAN_ANDROID_LD" \
    NM="$PACMAN_ANDROID_NM" \
    OBJCOPY="$PACMAN_ANDROID_OBJCOPY" \
    OBJDUMP="$PACMAN_ANDROID_OBJDUMP" \
    RANLIB="$PACMAN_ANDROID_RANLIB" \
    READELF="$PACMAN_ANDROID_READELF" \
    STRIP="$PACMAN_ANDROID_STRIP" \
    CPPFLAGS="" \
    CFLAGS="-O2" \
    CXXFLAGS="-O2" \
    LDFLAGS="" \
    bash "$PACMAN_ANDROID_SOURCE_WORKTREE/configure" \
      --build="$build_triple" \
      --host="$PACMAN_ANDROID_LIBRARY_TRIPLE" \
      --target="$PACMAN_ANDROID_LIBRARY_TRIPLE" \
      --prefix="$PACMAN_ANDROID_PREFIX" \
      --libdir="$PACMAN_ANDROID_PREFIX/lib" \
      --libexecdir="$PACMAN_ANDROID_PREFIX/lib" \
      --mandir="$PACMAN_ANDROID_PREFIX/share/man" \
      --infodir="$PACMAN_ANDROID_PREFIX/share/info" \
      --with-bugurl="https://github.com/xingguangcuican6666/pacman-android-packages/issues" \
      --with-build-sysroot="$PACMAN_ANDROID_SYSROOT" \
      --with-sysroot="/" \
      --with-native-system-header-dir="$PACMAN_ANDROID_PREFIX/include" \
      --with-zstd=no \
      --without-isl \
      --enable-languages=c,c++,fortran,objc,obj-c++ \
      --enable-shared \
      --enable-threads=posix \
      --enable-__cxa_atexit \
      --enable-clocale=gnu \
      --enable-default-pie \
      --enable-default-ssp \
      --enable-initfini-array \
      --disable-bootstrap \
      --disable-libcc1 \
      --disable-libssp \
      --disable-libstdcxx-pch \
      --disable-multilib \
      --disable-nls \
      --disable-werror \
      --enable-cet=no
  )
}

pacman_android_recipe_build() {
  local build_dir jobs
  local target_exec_runner
  local -a make_args build_targets

  build_dir="$(pacman_android_gcc_build_dir)"
  jobs="$(pacman_android_build_jobs)"
  target_exec_runner="$(pacman_android_gcc_target_exec_runner || true)"
  pacman_android_gcc_make_args
  make_args=("${PACMAN_ANDROID_GCC_MAKE_ARGS[@]}")
  mapfile -t build_targets < <(pacman_android_gcc_build_targets)

  if [[ -n "$target_exec_runner" ]]; then
    PACMAN_ANDROID_SKIP_GCC_SELFTESTS=1 \
      make -C "$build_dir" -j "$jobs" "${make_args[@]}" "${build_targets[@]}"
    return 0
  fi

  make -C "$build_dir" -j "$jobs" "${make_args[@]}" "${build_targets[@]}"
}

pacman_android_recipe_install() {
  local build_dir
  local -a make_args install_targets

  build_dir="$(pacman_android_gcc_build_dir)"
  pacman_android_gcc_make_args
  make_args=("${PACMAN_ANDROID_GCC_MAKE_ARGS[@]}")
  mapfile -t install_targets < <(pacman_android_gcc_install_targets)

  make -C "$build_dir" -j 1 DESTDIR="$PACMAN_ANDROID_ROOTFS_DIR" "${make_args[@]}" "${install_targets[@]}"
}

pacman_android_recipe_post_install() {
  local gcc_internal_libdir
  gcc_internal_libdir="$PACMAN_ANDROID_ROOTFS_DIR$(pacman_android_gcc_internal_libdir)"

  if [[ ! -e "$PACMAN_ANDROID_ROOTFS_DIR/usr/bin/cc" ]]; then
    (
      cd "$PACMAN_ANDROID_ROOTFS_DIR/usr/bin"
      ln -s gcc cc
    )
  fi

  for binary in gcc g++ cpp gcc-ar gcc-nm gcc-ranlib; do
    if [[ -e "$PACMAN_ANDROID_ROOTFS_DIR/usr/bin/$binary" && ! -e "$PACMAN_ANDROID_ROOTFS_DIR/usr/bin/${PACMAN_ANDROID_LIBRARY_TRIPLE}-$binary" ]]; then
      (
        cd "$PACMAN_ANDROID_ROOTFS_DIR/usr/bin"
        ln -s "$binary" "${PACMAN_ANDROID_LIBRARY_TRIPLE}-$binary"
      )
    fi
  done

  if [[ -f "$gcc_internal_libdir/liblto_plugin.so" ]]; then
    mkdir -p "$PACMAN_ANDROID_ROOTFS_DIR/usr/lib/bfd-plugins"
    if [[ ! -e "$PACMAN_ANDROID_ROOTFS_DIR/usr/lib/bfd-plugins/liblto_plugin.so" ]]; then
      (
        cd "$PACMAN_ANDROID_ROOTFS_DIR/usr/lib/bfd-plugins"
        ln -s "../../lib/gcc/${PACMAN_ANDROID_LIBRARY_TRIPLE}/$(pacman_android_gcc_major_version)/liblto_plugin.so" liblto_plugin.so
      )
    fi
  fi
}
