#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <package-ref> <x86_64|i686|armhf|aarch64>" >&2
  exit 1
fi

PACKAGE_REF="$1"
TARGET="$2"

active_collections() {
  local entry
  for entry in "$REPO_ROOT"/*-packages; do
    [[ -d "$entry" ]] || continue
    local name
    name="$(basename "$entry")"
    [[ "$name" == "disabled-packages" ]] && continue
    printf '%s\n' "$name"
  done
}


find_recipe_dir() {
  local package_ref="$1"
  local collection=""
  local package_name=""

  if [[ "$package_ref" == */* ]]; then
    collection="${package_ref%%/*}"
    package_name="${package_ref#*/}"
    if [[ "$collection" != *-packages ]]; then
      collection="${collection}-packages"
    fi
    if [[ -f "$REPO_ROOT/$collection/$package_name/package.sh" ]]; then
      printf '%s\n' "$REPO_ROOT/$collection/$package_name"
      return 0
    fi
  else
    package_name="$package_ref"
    local matches=()
    local collection_name
    while IFS= read -r collection_name; do
      [[ -n "$collection_name" ]] || continue
      local candidate="$REPO_ROOT/$collection_name/$package_name"
      if [[ -f "$candidate/package.sh" ]]; then
        matches+=("$candidate")
      fi
    done < <(active_collections)

    if [[ ${#matches[@]} -eq 1 ]]; then
      printf '%s\n' "${matches[0]}"
      return 0
    fi

    if [[ ${#matches[@]} -gt 1 ]]; then
      echo "package reference is ambiguous: $package_ref" >&2
      printf '%s\n' "${matches[@]}" >&2
      return 2
    fi
  fi

  echo "package recipe not found for reference: $package_ref" >&2
  return 1
}


package_ref_from_recipe_dir() {
  local recipe_dir="$1"
  local collection package_name repo
  collection="$(basename "$(dirname "$recipe_dir")")"
  package_name="$(basename "$recipe_dir")"
  repo="${collection%-packages}"
  printf '%s/%s\n' "$repo" "$package_name"
}


RECIPE_DIR="$(find_recipe_dir "$PACKAGE_REF")"
RECIPE_FILE="$RECIPE_DIR/package.sh"
PACKAGE_COLLECTION="$(basename "$(dirname "$RECIPE_DIR")")"
PACKAGE_NAME="$(basename "$RECIPE_DIR")"

if [[ "$PACKAGE_COLLECTION" == "disabled-packages" || "$PACKAGE_COLLECTION" != *-packages ]]; then
  echo "invalid active package collection: $PACKAGE_COLLECTION" >&2
  exit 1
fi

PACKAGE_REPO="${PACKAGE_COLLECTION%-packages}"

source "$REPO_ROOT/toolchain/env.sh"
pacman_android_prepare_environment "$TARGET"

export PACMAN_ANDROID_REPO_ROOT="$REPO_ROOT"
export PACMAN_ANDROID_PACKAGE_REF="$PACKAGE_REF"
export PACMAN_ANDROID_PACKAGE_COLLECTION="$PACKAGE_COLLECTION"
export PACMAN_ANDROID_PACKAGE_REPO="$PACKAGE_REPO"
export PACMAN_ANDROID_RECIPE_DIR="$RECIPE_DIR"
export PACMAN_ANDROID_RECIPE_FILE="$RECIPE_FILE"
export PACMAN_ANDROID_BUILD_ROOT="$REPO_ROOT/out/build/$PACKAGE_REPO/$PACKAGE_NAME/$TARGET"
export PACMAN_ANDROID_BUILD_DIR="$PACMAN_ANDROID_BUILD_ROOT/work"
export PACMAN_ANDROID_SOURCE_DIR="$PACMAN_ANDROID_BUILD_ROOT/src"
export PACMAN_ANDROID_CMAKE_BUILD_DIR="$PACMAN_ANDROID_BUILD_ROOT/cmake-build"
export PACMAN_ANDROID_MESON_BUILD_DIR="$PACMAN_ANDROID_BUILD_ROOT/meson-build"
export PACMAN_ANDROID_AUTOTOOLS_BUILD_DIR="$PACMAN_ANDROID_BUILD_ROOT/autotools-build"
export PACMAN_ANDROID_MESON_CROSS_FILE="$PACMAN_ANDROID_BUILD_ROOT/meson-cross-file.ini"
export PACMAN_ANDROID_SYSROOT_INCLUDE_DIR="$PACMAN_ANDROID_SYSROOT/usr/include"
export PACMAN_ANDROID_SYSROOT_ARCH_INCLUDE_DIR="$PACMAN_ANDROID_SYSROOT_INCLUDE_DIR/$PACMAN_ANDROID_LIBRARY_TRIPLE"
export PACMAN_ANDROID_SYSROOT_HEADERS_DIR="$PACMAN_ANDROID_BUILD_ROOT/sysroot-headers"
export PACMAN_ANDROID_STAGE_ROOT="$REPO_ROOT/out/stage/$PACKAGE_REPO/$PACKAGE_NAME/$TARGET"
export PACMAN_ANDROID_ROOTFS_DIR="$PACMAN_ANDROID_STAGE_ROOT/rootfs"
export PACMAN_ANDROID_METADATA_DIR="$PACMAN_ANDROID_STAGE_ROOT/metadata"
export PACMAN_ANDROID_PACKAGE_DIR="$REPO_ROOT/out/packages/$PACKAGE_REPO/$TARGET"
export PACMAN_ANDROID_DISTFILES_DIR="$REPO_ROOT/out/distfiles"
export PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR="$PACMAN_ANDROID_BUILD_ROOT/deps-rootfs"
export PACMAN_ANDROID_CANONICAL_PACKAGE_REF="$(package_ref_from_recipe_dir "$RECIPE_DIR")"
export PACMAN_ANDROID_INSTALL_ROOT="$PACMAN_ANDROID_ROOTFS_DIR"
export PACMAN_ANDROID_SRCDIR="$PACMAN_ANDROID_SOURCE_DIR"
export PACMAN_ANDROID_PKGDIR="$PACMAN_ANDROID_ROOTFS_DIR"
export PACMAN_ANDROID_STARTDIR="$REPO_ROOT"
export PACMAN_ANDROID_BUILDDIR="$PACMAN_ANDROID_BUILD_DIR"
export PACMAN_ANDROID_DISTDIR="$PACMAN_ANDROID_DISTFILES_DIR"
export PACMAN_ANDROID_BUILD_STACK="${PACMAN_ANDROID_BUILD_STACK:+$PACMAN_ANDROID_BUILD_STACK }$PACMAN_ANDROID_CANONICAL_PACKAGE_REF"

mkdir -p \
  "$PACMAN_ANDROID_BUILD_DIR" \
  "$PACMAN_ANDROID_ROOTFS_DIR" \
  "$PACMAN_ANDROID_METADATA_DIR" \
  "$PACMAN_ANDROID_PACKAGE_DIR" \
  "$PACMAN_ANDROID_DISTFILES_DIR" \
  "$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR"

declare PACMAN_ANDROID_PKG_NAME=""
declare PACMAN_ANDROID_PKG_VERSION=""
declare PACMAN_ANDROID_PKG_REVERSION=""
declare PACMAN_ANDROID_PKG_DESCRIPTION=""
declare PACMAN_ANDROID_PKG_URL=""
declare PACMAN_ANDROID_PKG_BASE=""
declare PACMAN_ANDROID_PKG_PACKAGER=""
declare PACMAN_ANDROID_PKG_SRCURL=""
declare PACMAN_ANDROID_PKG_SHA256=""
declare PACMAN_ANDROID_PKG_SOURCE_FILENAME=""
declare PACMAN_ANDROID_PKG_BUILD_SYSTEM="auto"
declare PACMAN_ANDROID_PKG_MAKE_INSTALL_TARGET="install"
declare -a PACMAN_ANDROID_PKG_LICENSES=()
declare -a PACMAN_ANDROID_PKG_TARGETS=()
declare -a PACMAN_ANDROID_PKG_DEPENDS=()
declare -a PACMAN_ANDROID_PKG_MAKE_DEPENDS=()
declare -a PACMAN_ANDROID_PKG_BUILD_DEPENDS=()
declare -a PACMAN_ANDROID_PKG_RUN_DEPENDS=()
declare -a PACMAN_ANDROID_PKG_CHECK_DEPENDS=()
declare -a PACMAN_ANDROID_PKG_PROVIDES=()
declare -a PACMAN_ANDROID_PKG_CONFLICTS=()
declare -a PACMAN_ANDROID_PKG_REPLACES=()
declare -a PACMAN_ANDROID_PKG_EXTRA_CONFIGURE_ARGS=()
declare -a PACMAN_ANDROID_PKG_EXTRA_BUILD_ARGS=()
declare -a PACMAN_ANDROID_PKG_EXTRA_INSTALL_ARGS=()

pacman_android_recipe_prepare() {
  return 0
}

pacman_android_recipe_configure() {
  pacman_android_default_configure
}

pacman_android_recipe_build() {
  pacman_android_default_build
}

pacman_android_recipe_install() {
  pacman_android_default_install
}

pacman_android_recipe_post_install() {
  return 0
}

source "$RECIPE_FILE"

require_var() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "required recipe variable is empty: $name" >&2
    exit 1
  fi
}

in_array() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}


append_unique_values() {
  local array_name="$1"
  shift
  local -n target_array="$array_name"
  local value
  for value in "$@"; do
    [[ -n "$value" ]] || continue
    if ! in_array "$value" "${target_array[@]}"; then
      target_array+=("$value")
    fi
  done
}


normalize_recipe_metadata() {
  append_unique_values PACMAN_ANDROID_PKG_MAKE_DEPENDS "${PACMAN_ANDROID_PKG_BUILD_DEPENDS[@]}"
  append_unique_values PACMAN_ANDROID_PKG_DEPENDS "${PACMAN_ANDROID_PKG_RUN_DEPENDS[@]}"
}

detect_packager() {
  if [[ -n "$PACMAN_ANDROID_PKG_PACKAGER" ]]; then
    printf '%s\n' "$PACMAN_ANDROID_PKG_PACKAGER"
    return
  fi

  local name email
  name="$(git -C "$REPO_ROOT" config --get user.name 2>/dev/null || true)"
  email="$(git -C "$REPO_ROOT" config --get user.email 2>/dev/null || true)"
  if [[ -n "$name" && -n "$email" ]]; then
    printf '%s <%s>\n' "$name" "$email"
  elif [[ -n "$name" ]]; then
    printf '%s\n' "$name"
  else
    printf '%s\n' "pacman-android-packages"
  fi
}

write_repeated_entries() {
  local field="$1"
  shift
  local value
  for value in "$@"; do
    printf '%s = %s\n' "$field" "$value"
  done
}

normalize_recipe_metadata

pacman_android_export_source_dirname() {
  local source_worktree="${PACMAN_ANDROID_SOURCE_WORKTREE:-}"
  [[ -n "$source_worktree" ]] || return 0

  if [[ "$source_worktree" == "$PACMAN_ANDROID_SOURCE_DIR" ]]; then
    export PACMAN_ANDROID_PKG_SOURCE_DIRNAME="."
    return 0
  fi

  if [[ "$source_worktree" == "$PACMAN_ANDROID_SOURCE_DIR"/* ]]; then
    export PACMAN_ANDROID_PKG_SOURCE_DIRNAME="${source_worktree#"$PACMAN_ANDROID_SOURCE_DIR"/}"
    return 0
  fi

  export PACMAN_ANDROID_PKG_SOURCE_DIRNAME="$(basename "$source_worktree")"
}


pacman_android_prepare_sysroot_headers() {
  if [[ ! -d "$PACMAN_ANDROID_SYSROOT_INCLUDE_DIR" ]]; then
    echo "missing NDK sysroot include directory: $PACMAN_ANDROID_SYSROOT_INCLUDE_DIR" >&2
    exit 1
  fi

  if [[ ! -d "$PACMAN_ANDROID_SYSROOT_ARCH_INCLUDE_DIR" ]]; then
    echo "missing arch-specific NDK include directory: $PACMAN_ANDROID_SYSROOT_ARCH_INCLUDE_DIR" >&2
    exit 1
  fi

  rm -rf "$PACMAN_ANDROID_SYSROOT_HEADERS_DIR"
  mkdir -p "$PACMAN_ANDROID_SYSROOT_HEADERS_DIR"

  cp -a "$PACMAN_ANDROID_SYSROOT_INCLUDE_DIR/." "$PACMAN_ANDROID_SYSROOT_HEADERS_DIR/"
  cp -a "$PACMAN_ANDROID_SYSROOT_ARCH_INCLUDE_DIR/." "$PACMAN_ANDROID_SYSROOT_HEADERS_DIR/"
}

prepare_default_source() {
  [[ -n "$PACMAN_ANDROID_PKG_SRCURL" ]] || return 0

  require_var PACMAN_ANDROID_PKG_SHA256

  mkdir -p "$PACMAN_ANDROID_DISTFILES_DIR" "$PACMAN_ANDROID_SOURCE_DIR"

  local source_filename
  source_filename="${PACMAN_ANDROID_PKG_SOURCE_FILENAME:-$(basename "${PACMAN_ANDROID_PKG_SRCURL%%\?*}")}"
  export PACMAN_ANDROID_SOURCE_ARCHIVE="$PACMAN_ANDROID_DISTFILES_DIR/$source_filename"
  download_and_verify_source_archive

  rm -rf "$PACMAN_ANDROID_SOURCE_DIR"
  mkdir -p "$PACMAN_ANDROID_SOURCE_DIR"
  bsdtar -xf "$PACMAN_ANDROID_SOURCE_ARCHIVE" -C "$PACMAN_ANDROID_SOURCE_DIR"
  export PACMAN_ANDROID_SOURCE_WORKTREE
  PACMAN_ANDROID_SOURCE_WORKTREE="$(resolve_source_worktree)"
  export PACMAN_ANDROID_SOURCE_ROOT="$PACMAN_ANDROID_SOURCE_WORKTREE"
  pacman_android_export_source_dirname
}


sha256_file() {
  sha256sum "$1" | cut -d' ' -f1
}


verify_source_archive_sha256() {
  local archive_path="$1"
  local actual_sha256
  actual_sha256="$(sha256_file "$archive_path")"

  if [[ "$actual_sha256" == "$PACMAN_ANDROID_PKG_SHA256" ]]; then
    return 0
  fi

  echo "sha256 mismatch for source archive: $archive_path" >&2
  echo "  url:      $PACMAN_ANDROID_PKG_SRCURL" >&2
  echo "  expected: $PACMAN_ANDROID_PKG_SHA256" >&2
  echo "  actual:   $actual_sha256" >&2
  return 1
}


download_source_archive() {
  local tmp_archive
  tmp_archive="$(mktemp "$PACMAN_ANDROID_DISTFILES_DIR/.download.XXXXXX")"

  if ! curl \
    --fail \
    --show-error \
    --location \
    --retry 5 \
    --retry-all-errors \
    --output "$tmp_archive" \
    "$PACMAN_ANDROID_PKG_SRCURL"; then
    rm -f "$tmp_archive"
    echo "failed to download source archive: $PACMAN_ANDROID_PKG_SRCURL" >&2
    exit 1
  fi

  mv "$tmp_archive" "$PACMAN_ANDROID_SOURCE_ARCHIVE"
}


download_and_verify_source_archive() {
  if [[ -f "$PACMAN_ANDROID_SOURCE_ARCHIVE" ]] && verify_source_archive_sha256 "$PACMAN_ANDROID_SOURCE_ARCHIVE"; then
    return 0
  fi

  if [[ -f "$PACMAN_ANDROID_SOURCE_ARCHIVE" ]]; then
    echo "cached source archive is invalid, re-downloading: $PACMAN_ANDROID_SOURCE_ARCHIVE" >&2
    rm -f "$PACMAN_ANDROID_SOURCE_ARCHIVE"
  fi

  download_source_archive

  if ! verify_source_archive_sha256 "$PACMAN_ANDROID_SOURCE_ARCHIVE"; then
    echo "refusing to continue with an invalid source archive" >&2
    exit 1
  fi
}


resolve_source_worktree() {
  local -a top_level_dirs=()
  local -a top_level_nondirs=()
  mapfile -t top_level_dirs < <(find "$PACMAN_ANDROID_SOURCE_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%P\n' | sort)
  mapfile -t top_level_nondirs < <(find "$PACMAN_ANDROID_SOURCE_DIR" -mindepth 1 -maxdepth 1 ! -type d -printf '%P\n' | sort)

  if [[ ${#top_level_dirs[@]} -eq 0 && ${#top_level_nondirs[@]} -eq 0 ]]; then
    echo "source archive extracted no files: $PACMAN_ANDROID_SOURCE_ARCHIVE" >&2
    exit 1
  fi

  if [[ ${#top_level_dirs[@]} -eq 1 && ${#top_level_nondirs[@]} -eq 0 ]]; then
    printf '%s\n' "$PACMAN_ANDROID_SOURCE_DIR/${top_level_dirs[0]}"
    return 0
  fi

  printf '%s\n' "$PACMAN_ANDROID_SOURCE_DIR"
}


dependency_name_from_spec() {
  local dependency="$1"
  dependency="${dependency%%[<>=]*}"
  dependency="${dependency%%:*}"
  printf '%s\n' "$dependency"
}


query_package_metadata() {
  local package_ref="$1"
  local output
  output="$(PACMAN_ANDROID_DRY_RUN=1 "$REPO_ROOT/build-package.sh" "$package_ref" "$TARGET")"

  QUERY_PACKAGE_PATH=""
  QUERY_RECIPE_PATH=""
  QUERY_PACKAGE_CANONICAL_REF=""

  local key value
  while IFS='=' read -r key value; do
    case "$key" in
      package_path) QUERY_PACKAGE_PATH="$value" ;;
      recipe) QUERY_RECIPE_PATH="$value" ;;
      canonical_package_ref) QUERY_PACKAGE_CANONICAL_REF="$value" ;;
    esac
  done <<< "$output"

  if [[ -z "$QUERY_PACKAGE_PATH" || -z "$QUERY_RECIPE_PATH" || -z "$QUERY_PACKAGE_CANONICAL_REF" ]]; then
    echo "failed to query package metadata for dependency: $package_ref" >&2
    echo "$output" >&2
    exit 1
  fi
}


dependency_package_is_current() {
  local package_path="$1"
  local recipe_path="$2"
  local buildinfo_path="${package_path%.pkg.tar.zst}.BUILDINFO"

  [[ -f "$package_path" && -f "$buildinfo_path" ]] || return 1

  local recipe_sha256
  recipe_sha256="$(sha256_file "$recipe_path")"
  grep -Fqx "pkgbuild_sha256sum = $recipe_sha256" "$buildinfo_path"
}


ensure_local_dependency_package() {
  local dependency_ref="$1"
  query_package_metadata "$dependency_ref"

  if dependency_package_is_current "$QUERY_PACKAGE_PATH" "$QUERY_RECIPE_PATH"; then
    printf '%s\n' "$QUERY_PACKAGE_PATH"
    return 0
  fi

  if in_array "$QUERY_PACKAGE_CANONICAL_REF" ${PACMAN_ANDROID_BUILD_STACK}; then
    echo "detected a local dependency cycle while building $PACMAN_ANDROID_CANONICAL_PACKAGE_REF" >&2
    echo "  cycle member: $QUERY_PACKAGE_CANONICAL_REF" >&2
    echo "  build stack:  $PACMAN_ANDROID_BUILD_STACK" >&2
    exit 1
  fi

  echo "building local dependency $QUERY_PACKAGE_CANONICAL_REF for target $TARGET" >&2

  local build_output package_path
  build_output="$("$REPO_ROOT/build-package.sh" "$QUERY_PACKAGE_CANONICAL_REF" "$TARGET")"
  package_path="$(printf '%s\n' "$build_output" | tail -n1)"

  if [[ ! -f "$package_path" ]]; then
    echo "dependency build did not produce a package file: $QUERY_PACKAGE_CANONICAL_REF" >&2
    echo "$build_output" >&2
    exit 1
  fi

  printf '%s\n' "$package_path"
}


resolve_local_dependency_ref() {
  local dependency_spec="$1"
  local dependency_name recipe_dir find_status
  dependency_name="$(dependency_name_from_spec "$dependency_spec")"
  [[ -n "$dependency_name" ]] || return 1

  recipe_dir="$(find_recipe_dir "$dependency_name" 2>/dev/null)" || find_status=$?
  if [[ -n "${find_status:-}" ]]; then
    if [[ "$find_status" == "2" ]]; then
      echo "local dependency reference is ambiguous: $dependency_name" >&2
      exit 1
    fi
    if [[ "$dependency_name" == */* ]]; then
      echo "local dependency recipe not found: $dependency_name" >&2
      exit 1
    fi
    return 1
  fi

  package_ref_from_recipe_dir "$recipe_dir"
}


bootstrap_local_dependencies() {
  local -a dependency_specs=("${PACMAN_ANDROID_PKG_MAKE_DEPENDS[@]}" "${PACMAN_ANDROID_PKG_DEPENDS[@]}")
  [[ ${#dependency_specs[@]} -gt 0 ]] || return 0

  rm -rf "$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR"
  mkdir -p "$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR"

  local -a installed_refs=()
  local dependency_spec dependency_ref package_path
  for dependency_spec in "${dependency_specs[@]}"; do
    dependency_ref="$(resolve_local_dependency_ref "$dependency_spec" || true)"
    [[ -n "$dependency_ref" ]] || continue

    if [[ "$dependency_ref" == "$PACMAN_ANDROID_CANONICAL_PACKAGE_REF" ]]; then
      echo "package cannot depend on itself: $dependency_ref" >&2
      exit 1
    fi

    if in_array "$dependency_ref" "${installed_refs[@]}"; then
      continue
    fi

    package_path="$(ensure_local_dependency_package "$dependency_ref")"
    echo "installing local dependency $(basename "$package_path") into $PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR" >&2
    bsdtar -xf "$package_path" -C "$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR"
    rm -f \
      "$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR/.PKGINFO" \
      "$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR/.BUILDINFO" \
      "$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR/.MTREE"

    installed_refs+=("$dependency_ref")
  done
}

apply_recipe_patches() {
  local patch_dir="$RECIPE_DIR/patches"
  local source_dir="${PACMAN_ANDROID_SOURCE_WORKTREE:-${PACMAN_ANDROID_PATCH_TARGET_DIR:-}}"
  local strip_level="${PACMAN_ANDROID_PATCH_STRIP_LEVEL:-1}"

  [[ -d "$patch_dir" ]] || return 0

  if [[ -z "$source_dir" || ! -d "$source_dir" ]]; then
    echo "patches exist in $patch_dir but no valid source directory was exported" >&2
    echo "expected PACMAN_ANDROID_SOURCE_WORKTREE or PACMAN_ANDROID_PATCH_TARGET_DIR" >&2
    exit 1
  fi

  mapfile -t patch_files < <(find "$patch_dir" -maxdepth 1 -type f -name '*.patch' | sort)
  if [[ ${#patch_files[@]} -eq 0 ]]; then
    return 0
  fi

  local patch_file
  for patch_file in "${patch_files[@]}"; do
    patch --forward --reject-file=- -d "$source_dir" "-p${strip_level}" < "$patch_file"
  done
}


pacman_android_require_source_worktree() {
  local build_system="${1:-build}"
  if [[ -z "${PACMAN_ANDROID_SOURCE_WORKTREE:-}" || ! -d "${PACMAN_ANDROID_SOURCE_WORKTREE:-}" ]]; then
    echo "cannot run default ${build_system} step without PACMAN_ANDROID_SOURCE_WORKTREE" >&2
    echo "define PACMAN_ANDROID_PKG_SRCURL/PACMAN_ANDROID_PKG_SHA256 or override the recipe step" >&2
    exit 1
  fi
}


pacman_android_has_makefile() {
  local directory="$1"
  [[ -f "$directory/GNUmakefile" || -f "$directory/Makefile" || -f "$directory/makefile" ]]
}


pacman_android_detect_build_system() {
  local requested="${PACMAN_ANDROID_PKG_BUILD_SYSTEM:-auto}"
  case "$requested" in
    ""|auto)
      ;;
    autotools|cmake|meson|make|ninja|none)
      printf '%s\n' "$requested"
      return 0
      ;;
    *)
      echo "unsupported PACMAN_ANDROID_PKG_BUILD_SYSTEM: $requested" >&2
      exit 1
      ;;
  esac

  if [[ -z "${PACMAN_ANDROID_SOURCE_WORKTREE:-}" || ! -d "${PACMAN_ANDROID_SOURCE_WORKTREE:-}" ]]; then
    printf 'none\n'
    return 0
  fi

  if [[ -f "$PACMAN_ANDROID_SOURCE_WORKTREE/configure" ]]; then
    printf 'autotools\n'
  elif [[ -f "$PACMAN_ANDROID_SOURCE_WORKTREE/CMakeLists.txt" ]]; then
    printf 'cmake\n'
  elif [[ -f "$PACMAN_ANDROID_SOURCE_WORKTREE/meson.build" ]]; then
    printf 'meson\n'
  elif [[ -f "$PACMAN_ANDROID_SOURCE_WORKTREE/build.ninja" ]]; then
    printf 'ninja\n'
  elif pacman_android_has_makefile "$PACMAN_ANDROID_SOURCE_WORKTREE"; then
    printf 'make\n'
  else
    printf 'none\n'
  fi
}


pacman_android_resolve_build_system() {
  if [[ -n "${PACMAN_ANDROID_BUILD_SYSTEM_RESOLVED:-}" ]]; then
    printf '%s\n' "$PACMAN_ANDROID_BUILD_SYSTEM_RESOLVED"
    return 0
  fi

  export PACMAN_ANDROID_BUILD_SYSTEM_RESOLVED
  PACMAN_ANDROID_BUILD_SYSTEM_RESOLVED="$(pacman_android_detect_build_system)"
  printf '%s\n' "$PACMAN_ANDROID_BUILD_SYSTEM_RESOLVED"
}


pacman_android_build_jobs() {
  if [[ -n "${PACMAN_ANDROID_BUILD_JOBS:-}" ]]; then
    printf '%s\n' "$PACMAN_ANDROID_BUILD_JOBS"
    return 0
  fi

  getconf _NPROCESSORS_ONLN 2>/dev/null || printf '1\n'
}


pacman_android_target_cpu_family() {
  case "$PACMAN_ANDROID_TARGET" in
    x86_64) printf 'x86_64\n' ;;
    i686) printf 'x86\n' ;;
    armhf) printf 'arm\n' ;;
    aarch64) printf 'aarch64\n' ;;
    *)
      echo "unsupported target for meson cpu family: $PACMAN_ANDROID_TARGET" >&2
      exit 1
      ;;
  esac
}


pacman_android_target_cpu() {
  case "$PACMAN_ANDROID_TARGET" in
    x86_64) printf 'x86_64\n' ;;
    i686) printf 'i686\n' ;;
    armhf) printf 'armv7\n' ;;
    aarch64) printf 'aarch64\n' ;;
    *)
      echo "unsupported target for meson cpu: $PACMAN_ANDROID_TARGET" >&2
      exit 1
      ;;
  esac
}


pacman_android_default_build_worktree() {
  local build_system
  build_system="${1:-$(pacman_android_resolve_build_system)}"

  case "$build_system" in
    autotools) printf '%s\n' "$PACMAN_ANDROID_AUTOTOOLS_BUILD_DIR" ;;
    cmake) printf '%s\n' "$PACMAN_ANDROID_CMAKE_BUILD_DIR" ;;
    meson) printf '%s\n' "$PACMAN_ANDROID_MESON_BUILD_DIR" ;;
    make|ninja) printf '%s\n' "${PACMAN_ANDROID_SOURCE_WORKTREE:-}" ;;
    none) printf '\n' ;;
    *)
      echo "unsupported build system: $build_system" >&2
      exit 1
      ;;
  esac
}


pacman_android_default_configure_autotools() {
  pacman_android_require_source_worktree autotools

  rm -rf "$PACMAN_ANDROID_AUTOTOOLS_BUILD_DIR"
  mkdir -p "$PACMAN_ANDROID_AUTOTOOLS_BUILD_DIR"

  (
    cd "$PACMAN_ANDROID_AUTOTOOLS_BUILD_DIR"
    bash "$PACMAN_ANDROID_SOURCE_WORKTREE/configure" \
      --host="$PACMAN_ANDROID_LIBRARY_TRIPLE" \
      --prefix="$PACMAN_ANDROID_PREFIX" \
      --sysconfdir="$PACMAN_ANDROID_SYSCONFDIR" \
      --disable-dependency-tracking \
      "${PACMAN_ANDROID_PKG_EXTRA_CONFIGURE_ARGS[@]}"
  )
}


pacman_android_default_configure_cmake() {
  pacman_android_require_source_worktree cmake

  rm -rf "$PACMAN_ANDROID_CMAKE_BUILD_DIR"
  mkdir -p "$PACMAN_ANDROID_CMAKE_BUILD_DIR"

  cmake -S "$PACMAN_ANDROID_SOURCE_WORKTREE" -B "$PACMAN_ANDROID_CMAKE_BUILD_DIR" -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE="$PACMAN_ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake" \
    -DCMAKE_AR="$PACMAN_ANDROID_AR" \
    -DCMAKE_RANLIB="$PACMAN_ANDROID_RANLIB" \
    -DCMAKE_STRIP="$PACMAN_ANDROID_STRIP" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS="$CFLAGS $CPPFLAGS" \
    -DCMAKE_CXX_FLAGS="$CXXFLAGS $CPPFLAGS" \
    -DCMAKE_EXE_LINKER_FLAGS="$LDFLAGS" \
    -DCMAKE_SHARED_LINKER_FLAGS="$LDFLAGS" \
    -DCMAKE_INSTALL_PREFIX="$PACMAN_ANDROID_PREFIX" \
    -DCMAKE_INSTALL_SYSCONFDIR="$PACMAN_ANDROID_SYSCONFDIR" \
    -DCMAKE_FIND_ROOT_PATH="$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR;$PACMAN_ANDROID_SYSROOT" \
    -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
    -DCMAKE_PREFIX_PATH="$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR/usr" \
    -DCMAKE_INCLUDE_PATH="$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR/usr/include" \
    -DCMAKE_LIBRARY_PATH="$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR/usr/lib" \
    -DCMAKE_MAKE_PROGRAM="$(command -v ninja)" \
    -DANDROID_ABI="$PACMAN_ANDROID_ABI" \
    -DANDROID_PLATFORM="android-$PACMAN_ANDROID_API_LEVEL" \
    "${PACMAN_ANDROID_PKG_EXTRA_CONFIGURE_ARGS[@]}"
}


pacman_android_default_configure_meson() {
  pacman_android_require_source_worktree meson

  rm -rf "$PACMAN_ANDROID_MESON_BUILD_DIR"
  mkdir -p "$PACMAN_ANDROID_MESON_BUILD_DIR"

  cat >"$PACMAN_ANDROID_MESON_CROSS_FILE" <<EOF
[binaries]
c = '$PACMAN_ANDROID_CC'
cpp = '$PACMAN_ANDROID_CXX'
ar = '$PACMAN_ANDROID_AR'
strip = '$PACMAN_ANDROID_STRIP'
pkgconfig = 'pkg-config'

[properties]
sys_root = '$PACMAN_ANDROID_SYSROOT'

[host_machine]
system = 'android'
cpu_family = '$(pacman_android_target_cpu_family)'
cpu = '$(pacman_android_target_cpu)'
endian = 'little'
EOF

  meson setup \
    "$PACMAN_ANDROID_MESON_BUILD_DIR" \
    "$PACMAN_ANDROID_SOURCE_WORKTREE" \
    --cross-file "$PACMAN_ANDROID_MESON_CROSS_FILE" \
    --prefix "$PACMAN_ANDROID_PREFIX" \
    --sysconfdir "$PACMAN_ANDROID_SYSCONFDIR" \
    --buildtype release \
    "${PACMAN_ANDROID_PKG_EXTRA_CONFIGURE_ARGS[@]}"
}


pacman_android_default_configure() {
  local build_system
  build_system="$(pacman_android_resolve_build_system)"

  case "$build_system" in
    none|make|ninja)
      return 0
      ;;
    autotools)
      pacman_android_default_configure_autotools
      ;;
    cmake)
      pacman_android_default_configure_cmake
      ;;
    meson)
      pacman_android_default_configure_meson
      ;;
    *)
      echo "unsupported build system during configure: $build_system" >&2
      exit 1
      ;;
  esac
}


pacman_android_default_build() {
  local build_system jobs build_worktree
  build_system="$(pacman_android_resolve_build_system)"
  jobs="$(pacman_android_build_jobs)"
  build_worktree="$(pacman_android_default_build_worktree "$build_system")"

  case "$build_system" in
    none)
      echo "could not infer a default build system for $PACMAN_ANDROID_PACKAGE_REF" >&2
      echo "define PACMAN_ANDROID_PKG_BUILD_SYSTEM or override pacman_android_recipe_build" >&2
      exit 1
      ;;
    cmake)
      cmake --build "$PACMAN_ANDROID_CMAKE_BUILD_DIR" --parallel "$jobs" "${PACMAN_ANDROID_PKG_EXTRA_BUILD_ARGS[@]}"
      ;;
    meson|ninja)
      ninja -C "$build_worktree" -j "$jobs" "${PACMAN_ANDROID_PKG_EXTRA_BUILD_ARGS[@]}"
      ;;
    autotools|make)
      make -C "$build_worktree" -j "$jobs" "${PACMAN_ANDROID_PKG_EXTRA_BUILD_ARGS[@]}"
      ;;
    *)
      echo "unsupported build system during build: $build_system" >&2
      exit 1
      ;;
  esac
}


pacman_android_default_install() {
  local build_system build_worktree
  build_system="$(pacman_android_resolve_build_system)"
  build_worktree="$(pacman_android_default_build_worktree "$build_system")"

  case "$build_system" in
    none)
      echo "could not infer a default install step for $PACMAN_ANDROID_PACKAGE_REF" >&2
      echo "define PACMAN_ANDROID_PKG_BUILD_SYSTEM or override pacman_android_recipe_install" >&2
      exit 1
      ;;
    cmake)
      DESTDIR="$PACMAN_ANDROID_ROOTFS_DIR" \
        cmake --install "$PACMAN_ANDROID_CMAKE_BUILD_DIR" "${PACMAN_ANDROID_PKG_EXTRA_INSTALL_ARGS[@]}"
      ;;
    meson)
      DESTDIR="$PACMAN_ANDROID_ROOTFS_DIR" \
        meson install -C "$PACMAN_ANDROID_MESON_BUILD_DIR" "${PACMAN_ANDROID_PKG_EXTRA_INSTALL_ARGS[@]}"
      ;;
    ninja)
      DESTDIR="$PACMAN_ANDROID_ROOTFS_DIR" \
        ninja -C "$build_worktree" "${PACMAN_ANDROID_PKG_EXTRA_INSTALL_ARGS[@]}" install
      ;;
    autotools|make)
      make -C "$build_worktree" -j 1 \
        DESTDIR="$PACMAN_ANDROID_ROOTFS_DIR" \
        "${PACMAN_ANDROID_PKG_EXTRA_INSTALL_ARGS[@]}" \
        "$PACMAN_ANDROID_PKG_MAKE_INSTALL_TARGET"
      ;;
    *)
      echo "unsupported build system during install: $build_system" >&2
      exit 1
      ;;
  esac
}

require_var PACMAN_ANDROID_PKG_NAME
require_var PACMAN_ANDROID_PKG_VERSION
require_var PACMAN_ANDROID_PKG_REVERSION
require_var PACMAN_ANDROID_PKG_DESCRIPTION

if [[ ${#PACMAN_ANDROID_PKG_TARGETS[@]} -gt 0 ]] && ! in_array "$TARGET" "${PACMAN_ANDROID_PKG_TARGETS[@]}"; then
  echo "target $TARGET is not supported by package $PACMAN_ANDROID_PKG_NAME" >&2
  exit 1
fi

export PACMAN_ANDROID_PKG_BASE="${PACMAN_ANDROID_PKG_BASE:-$PACMAN_ANDROID_PKG_NAME}"
export PACMAN_ANDROID_PKG_FULL_VERSION="${PACMAN_ANDROID_PKG_VERSION}-${PACMAN_ANDROID_PKG_REVERSION}"
export PACMAN_ANDROID_PKG_PACKAGER="$(detect_packager)"
export PACMAN_ANDROID_PACKAGE_BASENAME="${PACMAN_ANDROID_PKG_NAME}-${PACMAN_ANDROID_PKG_FULL_VERSION}-${PACMAN_ANDROID_PACKAGE_ARCH}"
export PACMAN_ANDROID_PACKAGE_PATH="$PACMAN_ANDROID_PACKAGE_DIR/${PACMAN_ANDROID_PACKAGE_BASENAME}.pkg.tar.zst"

export PKG_CONFIG_LIBDIR="${PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR}/usr/lib/pkgconfig:${PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR}/usr/share/pkgconfig:${PACMAN_ANDROID_ROOTFS_DIR}/usr/lib/pkgconfig:${PACMAN_ANDROID_ROOTFS_DIR}/usr/share/pkgconfig"
export PKG_CONFIG_SYSROOT_DIR="$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR"
export CPPFLAGS="-I${PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR}/usr/include${CPPFLAGS:+ $CPPFLAGS}"
export LDFLAGS="-L${PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR}/usr/lib${LDFLAGS:+ $LDFLAGS}"

rm -rf \
  "$PACMAN_ANDROID_BUILD_DIR" \
  "$PACMAN_ANDROID_SOURCE_DIR" \
  "$PACMAN_ANDROID_CMAKE_BUILD_DIR" \
  "$PACMAN_ANDROID_MESON_BUILD_DIR" \
  "$PACMAN_ANDROID_AUTOTOOLS_BUILD_DIR" \
  "$PACMAN_ANDROID_MESON_CROSS_FILE" \
  "$PACMAN_ANDROID_ROOTFS_DIR" \
  "$PACMAN_ANDROID_METADATA_DIR" \
  "$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR"
mkdir -p \
  "$PACMAN_ANDROID_BUILD_DIR" \
  "$PACMAN_ANDROID_SOURCE_DIR" \
  "$PACMAN_ANDROID_ROOTFS_DIR" \
  "$PACMAN_ANDROID_METADATA_DIR" \
  "$PACMAN_ANDROID_PACKAGE_DIR" \
  "$PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR"

if [[ "${PACMAN_ANDROID_DRY_RUN:-0}" == "1" ]]; then
  cat <<EOF
package=$PACMAN_ANDROID_PKG_NAME
package_ref=$PACMAN_ANDROID_PACKAGE_REF
canonical_package_ref=$PACMAN_ANDROID_CANONICAL_PACKAGE_REF
package_collection=$PACMAN_ANDROID_PACKAGE_COLLECTION
package_repo=$PACMAN_ANDROID_PACKAGE_REPO
target=$PACMAN_ANDROID_TARGET
package_arch=$PACMAN_ANDROID_PACKAGE_ARCH
version=$PACMAN_ANDROID_PKG_FULL_VERSION
srcurl=$PACMAN_ANDROID_PKG_SRCURL
build_system=$PACMAN_ANDROID_PKG_BUILD_SYSTEM
recipe=$PACMAN_ANDROID_RECIPE_FILE
package_path=$PACMAN_ANDROID_PACKAGE_PATH
ndk_root=$PACMAN_ANDROID_NDK_ROOT
rootdir=$PACMAN_ROOTDIR
PACMAN_ANDROID_STARTDIR=$PACMAN_ANDROID_STARTDIR
PACMAN_ANDROID_SRCDIR=$PACMAN_ANDROID_SRCDIR
PACMAN_ANDROID_BUILDDIR=$PACMAN_ANDROID_BUILDDIR
PACMAN_ANDROID_PKGDIR=$PACMAN_ANDROID_PKGDIR
PACMAN_ANDROID_DISTDIR=$PACMAN_ANDROID_DISTDIR
EOF
  exit 0
fi

pacman_android_prepare_sysroot_headers

prepare_default_source
bootstrap_local_dependencies

pacman_android_recipe_prepare
pacman_android_export_source_dirname

apply_recipe_patches

pacman_android_recipe_configure
pacman_android_recipe_build
pacman_android_recipe_install
pacman_android_recipe_post_install

if [[ ! -d "$PACMAN_ANDROID_ROOTFS_DIR" ]] || [[ -z "$(find "$PACMAN_ANDROID_ROOTFS_DIR" -mindepth 1 -print -quit)" ]]; then
  echo "rootfs staging directory is empty: $PACMAN_ANDROID_ROOTFS_DIR" >&2
  exit 1
fi

BUILD_DATE="$(date -u +%s)"
INSTALLED_SIZE="$(du -sb "$PACMAN_ANDROID_ROOTFS_DIR" | cut -f1)"
BUILD_TOOL_VERSION="$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo dev)"
RECIPE_SHA256="$(sha256sum "$RECIPE_FILE" | cut -d' ' -f1)"
PKGINFO_FILE="$PACMAN_ANDROID_METADATA_DIR/.PKGINFO"
BUILDINFO_FILE="$PACMAN_ANDROID_METADATA_DIR/.BUILDINFO"
MTREE_FILE="$PACMAN_ANDROID_METADATA_DIR/.MTREE"
MANIFEST_FILE="$PACMAN_ANDROID_PACKAGE_DIR/${PACMAN_ANDROID_PACKAGE_BASENAME}.manifest"

{
  printf 'pkgname = %s\n' "$PACMAN_ANDROID_PKG_NAME"
  printf 'pkgbase = %s\n' "$PACMAN_ANDROID_PKG_BASE"
  printf 'pkgver = %s\n' "$PACMAN_ANDROID_PKG_FULL_VERSION"
  printf 'pkgdesc = %s\n' "$PACMAN_ANDROID_PKG_DESCRIPTION"
  if [[ -n "$PACMAN_ANDROID_PKG_URL" ]]; then
    printf 'url = %s\n' "$PACMAN_ANDROID_PKG_URL"
  fi
  printf 'builddate = %s\n' "$BUILD_DATE"
  printf 'packager = %s\n' "$PACMAN_ANDROID_PKG_PACKAGER"
  printf 'size = %s\n' "$INSTALLED_SIZE"
  printf 'arch = %s\n' "$PACMAN_ANDROID_PACKAGE_ARCH"
  write_repeated_entries license "${PACMAN_ANDROID_PKG_LICENSES[@]}"
  write_repeated_entries depend "${PACMAN_ANDROID_PKG_DEPENDS[@]}"
  write_repeated_entries provides "${PACMAN_ANDROID_PKG_PROVIDES[@]}"
  write_repeated_entries conflict "${PACMAN_ANDROID_PKG_CONFLICTS[@]}"
  write_repeated_entries replaces "${PACMAN_ANDROID_PKG_REPLACES[@]}"
} >"$PKGINFO_FILE"

{
  printf 'format = 2\n'
  printf 'pkgname = %s\n' "$PACMAN_ANDROID_PKG_NAME"
  printf 'pkgbase = %s\n' "$PACMAN_ANDROID_PKG_BASE"
  printf 'pkgver = %s\n' "$PACMAN_ANDROID_PKG_FULL_VERSION"
  printf 'pkgarch = %s\n' "$PACMAN_ANDROID_PACKAGE_ARCH"
  printf 'packager = %s\n' "$PACMAN_ANDROID_PKG_PACKAGER"
  printf 'builddate = %s\n' "$BUILD_DATE"
  printf 'builddir = %s\n' "$PACMAN_ANDROID_BUILD_DIR"
  printf 'startdir = %s\n' "$REPO_ROOT"
  printf 'buildtool = %s\n' 'pacman-android-packages'
  printf 'buildtoolver = %s\n' "$BUILD_TOOL_VERSION"
  printf 'pkgbuild_sha256sum = %s\n' "$RECIPE_SHA256"
  printf 'buildenv = %s\n' "target=$PACMAN_ANDROID_TARGET"
  printf 'options = %s\n' '!strip'
} >"$BUILDINFO_FILE"

bsdtar --format=mtree -cf "$MTREE_FILE" -C "$PACMAN_ANDROID_ROOTFS_DIR" .

bsdtar --uid 0 --gid 0 --numeric-owner -cf - \
  -C "$PACMAN_ANDROID_METADATA_DIR" .PKGINFO .BUILDINFO .MTREE \
  -C "$PACMAN_ANDROID_ROOTFS_DIR" . \
  | zstd -T0 -19 -f -o "$PACMAN_ANDROID_PACKAGE_PATH" >/dev/null

cp "$PKGINFO_FILE" "$PACMAN_ANDROID_PACKAGE_DIR/${PACMAN_ANDROID_PACKAGE_BASENAME}.PKGINFO"
cp "$BUILDINFO_FILE" "$PACMAN_ANDROID_PACKAGE_DIR/${PACMAN_ANDROID_PACKAGE_BASENAME}.BUILDINFO"
cp "$MTREE_FILE" "$PACMAN_ANDROID_PACKAGE_DIR/${PACMAN_ANDROID_PACKAGE_BASENAME}.MTREE"

{
  printf 'package=%s\n' "$PACMAN_ANDROID_PKG_NAME"
  printf 'package_ref=%s\n' "$PACMAN_ANDROID_PACKAGE_REF"
  printf 'canonical_package_ref=%s\n' "$PACMAN_ANDROID_CANONICAL_PACKAGE_REF"
  printf 'package_collection=%s\n' "$PACMAN_ANDROID_PACKAGE_COLLECTION"
  printf 'package_repo=%s\n' "$PACMAN_ANDROID_PACKAGE_REPO"
  printf 'target=%s\n' "$PACMAN_ANDROID_TARGET"
  printf 'package_arch=%s\n' "$PACMAN_ANDROID_PACKAGE_ARCH"
  printf 'version=%s\n' "$PACMAN_ANDROID_PKG_FULL_VERSION"
  printf 'package_path=%s\n' "$PACMAN_ANDROID_PACKAGE_PATH"
  printf 'package_file=%s\n' "$(basename "$PACMAN_ANDROID_PACKAGE_PATH")"
  printf 'rootfs_dir=%s\n' "$PACMAN_ANDROID_ROOTFS_DIR"
  printf 'build_dir=%s\n' "$PACMAN_ANDROID_BUILD_DIR"
  printf 'ndk_root=%s\n' "$PACMAN_ANDROID_NDK_ROOT"
} >"$MANIFEST_FILE"

printf '%s\n' "$PACMAN_ANDROID_PACKAGE_PATH"
