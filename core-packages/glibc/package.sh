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
  local flag

  for flag in $PACMAN_ANDROID_COMMON_CFLAGS; do
    if [[ "$flag" == "-D__ANDROID_API__=$PACMAN_ANDROID_API_LEVEL" ]]; then
      continue
    fi
    glibc_common_cflags+=("$flag")
  done

  export BUILD_CC="${BUILD_CC:-$(command -v cc || command -v gcc)}"
  export CFLAGS="${glibc_common_cflags[*]} -O2 -fno-emulated-tls -mno-outline-atomics"
  export CXXFLAGS="${glibc_common_cflags[*]} -O2 -fno-emulated-tls -mno-outline-atomics"
  export LDFLAGS=""
}

pacman_android_glibc_android_fixups() {
  local glibc_src="$PACMAN_ANDROID_SOURCE_WORKTREE"
  local glibc_makefile="$glibc_src/elf/Makefile"
  local pointer_guard="$glibc_src/sysdeps/unix/sysv/linux/aarch64/pointer_guard.h"
  local system_property_stub="$glibc_src/elf/system-property-stub.c"

  if ! grep -q '^#  include <stdint.h>$' "$pointer_guard"; then
    perl -0pi -e 's@# else\n@# else\n#  include <stdint.h>\n@' "$pointer_guard"
  fi

  local awk_script
  awk_script=$(cat <<'AWK'
/rtld-csu \+=errno\.os/ { next }
/rtld-elf \+=system-property-stub\.os/ { next }
/rtld-misc \+=memfd_create\.os/ { next }
/printf '%s\\n' 'rtld-csu \+=errno\.os' \\/ { next }
{
  print
  if ($0 == "\tdone > $@T") {
    print "\tprintf '%s\\n' 'rtld-csu +=errno.os' \\"
    print "\t\t       'rtld-elf +=system-property-stub.os' >> $@T"
  }
}
AWK
)
  awk "$awk_script" "$glibc_makefile" > "$glibc_makefile.new"
  mv -f "$glibc_makefile.new" "$glibc_makefile"

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
