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
      exit 1
    fi
  fi

  echo "package recipe not found for reference: $package_ref" >&2
  exit 1
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
export PACMAN_ANDROID_STAGE_ROOT="$REPO_ROOT/out/stage/$PACKAGE_REPO/$PACKAGE_NAME/$TARGET"
export PACMAN_ANDROID_ROOTFS_DIR="$PACMAN_ANDROID_STAGE_ROOT/rootfs"
export PACMAN_ANDROID_METADATA_DIR="$PACMAN_ANDROID_STAGE_ROOT/metadata"
export PACMAN_ANDROID_PACKAGE_DIR="$REPO_ROOT/out/packages/$PACKAGE_REPO/$TARGET"

mkdir -p \
  "$PACMAN_ANDROID_BUILD_DIR" \
  "$PACMAN_ANDROID_ROOTFS_DIR" \
  "$PACMAN_ANDROID_METADATA_DIR" \
  "$PACMAN_ANDROID_PACKAGE_DIR"

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
declare PACMAN_ANDROID_PKG_SOURCE_DIRNAME=""
declare -a PACMAN_ANDROID_PKG_LICENSES=()
declare -a PACMAN_ANDROID_PKG_TARGETS=()
declare -a PACMAN_ANDROID_PKG_DEPENDS=()
declare -a PACMAN_ANDROID_PKG_MAKE_DEPENDS=()
declare -a PACMAN_ANDROID_PKG_CHECK_DEPENDS=()
declare -a PACMAN_ANDROID_PKG_PROVIDES=()
declare -a PACMAN_ANDROID_PKG_CONFLICTS=()
declare -a PACMAN_ANDROID_PKG_REPLACES=()

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

prepare_default_source() {
  [[ -n "$PACMAN_ANDROID_PKG_SRCURL" ]] || return 0

  require_var PACMAN_ANDROID_PKG_SHA256

  export PACMAN_ANDROID_DISTFILES_DIR="$PACMAN_ANDROID_REPO_ROOT/out/distfiles"
  export PACMAN_ANDROID_SOURCE_DIR="$PACMAN_ANDROID_BUILD_ROOT/src"
  export PACMAN_ANDROID_CMAKE_BUILD_DIR="$PACMAN_ANDROID_BUILD_ROOT/cmake-build"

  mkdir -p "$PACMAN_ANDROID_DISTFILES_DIR" "$PACMAN_ANDROID_SOURCE_DIR"

  local source_filename="${PACMAN_ANDROID_PKG_SOURCE_FILENAME:-$(basename "${PACMAN_ANDROID_PKG_SRCURL%%\?*}")}"
  export PACMAN_ANDROID_SOURCE_ARCHIVE="$PACMAN_ANDROID_DISTFILES_DIR/$source_filename"

  if [[ ! -f "$PACMAN_ANDROID_SOURCE_ARCHIVE" ]]; then
    curl \
      --fail \
      --location \
      --retry 5 \
      --retry-all-errors \
      --output "$PACMAN_ANDROID_SOURCE_ARCHIVE" \
      "$PACMAN_ANDROID_PKG_SRCURL"
  fi

  echo "${PACMAN_ANDROID_PKG_SHA256}  ${PACMAN_ANDROID_SOURCE_ARCHIVE}" | sha256sum --check --status

  rm -rf "$PACMAN_ANDROID_SOURCE_DIR" "$PACMAN_ANDROID_CMAKE_BUILD_DIR"
  mkdir -p "$PACMAN_ANDROID_SOURCE_DIR"
  bsdtar -xf "$PACMAN_ANDROID_SOURCE_ARCHIVE" -C "$PACMAN_ANDROID_SOURCE_DIR"

  local source_dirname="${PACMAN_ANDROID_PKG_SOURCE_DIRNAME:-$(bsdtar -tf "$PACMAN_ANDROID_SOURCE_ARCHIVE" | head -n1 | cut -d/ -f1)}"
  if [[ -z "$source_dirname" ]]; then
    echo "failed to infer source directory name from archive: $PACMAN_ANDROID_SOURCE_ARCHIVE" >&2
    exit 1
  fi

  export PACMAN_ANDROID_SOURCE_WORKTREE="$PACMAN_ANDROID_SOURCE_DIR/$source_dirname"
  if [[ ! -d "$PACMAN_ANDROID_SOURCE_WORKTREE" ]]; then
    echo "expected source worktree does not exist: $PACMAN_ANDROID_SOURCE_WORKTREE" >&2
    exit 1
  fi
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

require_var PACMAN_ANDROID_PKG_NAME
require_var PACMAN_ANDROID_PKG_VERSION
require_var PACMAN_ANDROID_PKG_REVERSION
require_var PACMAN_ANDROID_PKG_DESCRIPTION

if [[ ${#PACMAN_ANDROID_PKG_TARGETS[@]} -gt 0 ]] && ! in_array "$TARGET" "${PACMAN_ANDROID_PKG_TARGETS[@]}"; then
  echo "target $TARGET is not supported by package $PACMAN_ANDROID_PKG_NAME" >&2
  exit 1
fi

if ! declare -F pacman_android_recipe_install >/dev/null; then
  echo "recipe must define pacman_android_recipe_install" >&2
  exit 1
fi

export PACMAN_ANDROID_PKG_BASE="${PACMAN_ANDROID_PKG_BASE:-$PACMAN_ANDROID_PKG_NAME}"
export PACMAN_ANDROID_PKG_FULL_VERSION="${PACMAN_ANDROID_PKG_VERSION}-${PACMAN_ANDROID_PKG_REVERSION}"
export PACMAN_ANDROID_PKG_PACKAGER="$(detect_packager)"
export PACMAN_ANDROID_PACKAGE_BASENAME="${PACMAN_ANDROID_PKG_NAME}-${PACMAN_ANDROID_PKG_FULL_VERSION}-${PACMAN_ANDROID_PACKAGE_ARCH}"
export PACMAN_ANDROID_PACKAGE_PATH="$PACMAN_ANDROID_PACKAGE_DIR/${PACMAN_ANDROID_PACKAGE_BASENAME}.pkg.tar.zst"

export PKG_CONFIG_LIBDIR="${PACMAN_ANDROID_ROOTFS_DIR}/usr/lib/pkgconfig:${PACMAN_ANDROID_ROOTFS_DIR}/usr/share/pkgconfig"
export PKG_CONFIG_SYSROOT_DIR="$PACMAN_ROOTDIR"

rm -rf "$PACMAN_ANDROID_BUILD_DIR" "$PACMAN_ANDROID_ROOTFS_DIR" "$PACMAN_ANDROID_METADATA_DIR"
mkdir -p "$PACMAN_ANDROID_BUILD_DIR" "$PACMAN_ANDROID_ROOTFS_DIR" "$PACMAN_ANDROID_METADATA_DIR" "$PACMAN_ANDROID_PACKAGE_DIR"

if [[ "${PACMAN_ANDROID_DRY_RUN:-0}" == "1" ]]; then
  cat <<EOF
package=$PACMAN_ANDROID_PKG_NAME
package_ref=$PACMAN_ANDROID_PACKAGE_REF
package_collection=$PACMAN_ANDROID_PACKAGE_COLLECTION
package_repo=$PACMAN_ANDROID_PACKAGE_REPO
target=$PACMAN_ANDROID_TARGET
package_arch=$PACMAN_ANDROID_PACKAGE_ARCH
version=$PACMAN_ANDROID_PKG_FULL_VERSION
srcurl=$PACMAN_ANDROID_PKG_SRCURL
recipe=$PACMAN_ANDROID_RECIPE_FILE
package_path=$PACMAN_ANDROID_PACKAGE_PATH
ndk_root=$PACMAN_ANDROID_NDK_ROOT
rootdir=$PACMAN_ROOTDIR
EOF
  exit 0
fi

prepare_default_source

if declare -F pacman_android_recipe_prepare >/dev/null; then
  pacman_android_recipe_prepare
fi

apply_recipe_patches

if declare -F pacman_android_recipe_build >/dev/null; then
  pacman_android_recipe_build
fi

pacman_android_recipe_install

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
