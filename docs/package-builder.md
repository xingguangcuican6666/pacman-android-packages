# Package Builder

API reference for `package.sh`: [package-script-api.md](package-script-api.md)
`package.sh` 的 API 参考： [package-script-api.md](package-script-api.md)

## Goal

The repository now includes a minimal package builder that can:

1. load target metadata
2. prepare Android NDK-based compiler environment
3. run a repository-local recipe
4. stage a normal Unix rootfs
5. emit an ALPM package as `*.pkg.tar.zst`

## Entry Point

Run from repository root:

```bash
./build-package.sh <package-ref> <target>
```

Current example:

```bash
./build-package.sh extra/fastfetch aarch64
```

## Current Recipe Contract

Each package lives at:

- `<repo>-packages/<name>/package.sh`

Optional patch directory:

- `<repo>-packages/<name>/patches/*.patch`

Optional subpackage declarations:

- `<repo>-packages/<name>/*.subpackage.sh`

Required metadata variables:

- `PACMAN_ANDROID_PKG_NAME`
- `PACMAN_ANDROID_PKG_VERSION`
- `PACMAN_ANDROID_PKG_REVERSION`
- `PACMAN_ANDROID_PKG_DESCRIPTION`

Common optional metadata:

- `PACMAN_ANDROID_PKG_URL`
- `PACMAN_ANDROID_PKG_LICENSES`
- `PACMAN_ANDROID_PKG_SRCURL`
- `PACMAN_ANDROID_PKG_SHA256`
- `PACMAN_ANDROID_PKG_SOURCE_FILENAME`
- `PACMAN_ANDROID_PKG_BUILD_SYSTEM`
- `PACMAN_ANDROID_PKG_MAKE_INSTALL_TARGET`
- `PACMAN_ANDROID_PKG_EXTRA_CONFIGURE_ARGS`
- `PACMAN_ANDROID_PKG_EXTRA_BUILD_ARGS`
- `PACMAN_ANDROID_PKG_EXTRA_INSTALL_ARGS`
- `PACMAN_ANDROID_PKG_TARGETS`
- `PACMAN_ANDROID_PKG_DEPENDS`
- `PACMAN_ANDROID_PKG_RUN_DEPENDS`
- `PACMAN_ANDROID_PKG_MAKE_DEPENDS`
- `PACMAN_ANDROID_PKG_BUILD_DEPENDS`
- `PACMAN_ANDROID_PKG_PROVIDES`
- `PACMAN_ANDROID_PKG_CONFLICTS`
- `PACMAN_ANDROID_PKG_REPLACES`

Supported recipe functions:

- `pacman_android_recipe_prepare`
- `pacman_android_recipe_configure`
- `pacman_android_recipe_build`
- `pacman_android_recipe_install`
- `pacman_android_recipe_post_install`

All recipe functions are optional. The builder now provides default `configure`, `build`, and `install` steps and only needs explicit recipe functions when a package deviates from the default pipeline.

## Subpackages

Recipes may declare additional output packages by adding sibling `*.subpackage.sh` files next to `package.sh`.

The builder behavior is:

1. build and install the parent recipe into the normal staging root
2. evaluate each `*.subpackage.sh`
3. move matching files from the parent staging root into a per-subpackage staging root
4. emit one ALPM package per declared output package

This is intentionally similar to Termux's split-package flow, but the package metadata and output layout remain repo-local.

Each subpackage file may define:

- `PACMAN_ANDROID_SUBPKG_DESCRIPTION`
- `PACMAN_ANDROID_SUBPKG_LICENSES`
- `PACMAN_ANDROID_SUBPKG_DEPENDS`
- `PACMAN_ANDROID_SUBPKG_PROVIDES`
- `PACMAN_ANDROID_SUBPKG_CONFLICTS`
- `PACMAN_ANDROID_SUBPKG_REPLACES`
- `PACMAN_ANDROID_SUBPKG_TARGETS`
- `PACMAN_ANDROID_SUBPKG_INCLUDE_PATTERNS`
- `PACMAN_ANDROID_SUBPKG_ALLOW_EMPTY`

The filename controls the output package name. For example, `gcc-libs.subpackage.sh` emits package `gcc-libs`.

Subpackages may also be addressed directly from the CLI:

```bash
./build-package.sh core/gcc-libs aarch64
./build-package.sh core/libstdc++ aarch64
```

The owning recipe is still built once and all sibling packages for that recipe are emitted together.

## Default Build Pipeline

If a recipe does not override the stage functions, the builder will infer a build system from the extracted source tree using a Termux-like order:

1. `configure` -> `autotools`
2. `CMakeLists.txt` -> `cmake`
3. `meson.build` -> `meson`
4. `build.ninja` -> `ninja`
5. `GNUmakefile` / `Makefile` / `makefile` -> `make`

`PACMAN_ANDROID_PKG_BUILD_SYSTEM` may be set to one of:

- `auto`
- `autotools`
- `cmake`
- `meson`
- `ninja`
- `make`
- `none`

Use `none` when the recipe will fully override the default build and install logic.

## Default Source Pipeline

If a recipe sets:

- `PACMAN_ANDROID_PKG_SRCURL`
- `PACMAN_ANDROID_PKG_SHA256`

the builder will automatically:

1. download the archive into `out/distfiles/`
2. verify the SHA256 checksum with explicit expected/actual error output
3. re-download a bad cached archive once instead of failing silently
4. extract the source tree into the package build root
5. auto-detect the real source worktree when the archive layout does not match a guessed dirname
6. export `PACMAN_ANDROID_SOURCE_WORKTREE`

Optional source-shape helper:

- `PACMAN_ANDROID_PKG_SOURCE_FILENAME`

If source metadata is not provided, recipes may still export `PACMAN_ANDROID_SOURCE_WORKTREE` manually from `pacman_android_recipe_prepare`.

The builder populates `PACMAN_ANDROID_PKG_SOURCE_DIRNAME` after source extraction, and refreshes it again after `pacman_android_recipe_prepare` if the recipe sets `PACMAN_ANDROID_SOURCE_WORKTREE` manually.

## Dependency Bootstrap

Recipes may define target-package dependencies at the top of `package.sh` using either naming style:

- `PACMAN_ANDROID_PKG_MAKE_DEPENDS`
- `PACMAN_ANDROID_PKG_BUILD_DEPENDS`
- `PACMAN_ANDROID_PKG_DEPENDS`
- `PACMAN_ANDROID_PKG_RUN_DEPENDS`

`*_BUILD_DEPENDS` is merged into `*_MAKE_DEPENDS`, and `*_RUN_DEPENDS` is merged into `*_DEPENDS`.

Before `pacman_android_recipe_prepare`, the builder will:

1. resolve any dependency that matches a local recipe in this repository
2. build that dependency for the same Android target when needed
3. extract the resulting package into an isolated dependency rootfs under `out/build/<repo>/<name>/<target>/deps-rootfs/`
4. expose that dependency rootfs to `pkg-config`, compiler include search, linker library search, and default CMake discovery

Dependency files are not merged into the final package staging rootfs.

If a dependency refers to a sibling subpackage from the same recipe, the builder does not recurse into a separate local build. The files are expected to come from the same parent recipe build.

## Patch Application

If `<repo>-packages/<name>/patches/` exists, the builder applies all `*.patch` files in lexical order after `pacman_android_recipe_prepare` and before `pacman_android_recipe_configure`.

The builder expects the recipe to export one of:

- `PACMAN_ANDROID_SOURCE_WORKTREE`
- `PACMAN_ANDROID_PATCH_TARGET_DIR`

Optional:

- `PACMAN_ANDROID_PATCH_STRIP_LEVEL`

## Exported Path Variables

The builder exports both repository-specific variables and package-path variables:

- `PACMAN_ANDROID_SOURCE_DIR`
- `PACMAN_ANDROID_SOURCE_WORKTREE`
- `PACMAN_ANDROID_SOURCE_ROOT`
- `PACMAN_ANDROID_PKG_SOURCE_DIRNAME`
- `PACMAN_ANDROID_BUILD_DIR`
- `PACMAN_ANDROID_STARTDIR`
- `PACMAN_ANDROID_SRCDIR`
- `PACMAN_ANDROID_BUILDDIR`
- `PACMAN_ANDROID_PKGDIR`
- `PACMAN_ANDROID_DISTDIR`
- `PACMAN_ANDROID_ROOTFS_DIR`
- `PACMAN_ANDROID_METADATA_DIR`
- `PACMAN_ANDROID_PACKAGE_DIR`
- `PACMAN_ANDROID_DISTFILES_DIR`
- `PACMAN_ANDROID_DEPENDENCY_ROOTFS_DIR`

## Output Layout

For a package `<repo>/<name>` and target `<target>`:

- build workdir:
  - `out/build/<repo>/<recipe>/<target>/`
- staged filesystem:
  - `out/stage/<repo>/<recipe>/<target>/rootfs/`
- package metadata:
  - `out/stage/<repo>/<recipe>/<target>/metadata/`
- subpackage staging roots:
  - `out/stage/<repo>/<recipe>/<target>/packages/<subpackage>/`
- final package outputs:
  - `out/packages/<repo>/<target>/`

The builder currently emits:

- `<name>-<version>-<reversion>-<arch>.pkg.tar.zst`
- matching `.PKGINFO`
- matching `.BUILDINFO`
- matching `.MTREE`
- a simple `.manifest` with package and maintainer metadata
