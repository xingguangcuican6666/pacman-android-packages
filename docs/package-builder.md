# Package Builder

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
- `PACMAN_ANDROID_PKG_SOURCE_DIRNAME`
- `PACMAN_ANDROID_PKG_BUILD_SYSTEM`
- `PACMAN_ANDROID_PKG_MAKE_INSTALL_TARGET`
- `PACMAN_ANDROID_PKG_EXTRA_CONFIGURE_ARGS`
- `PACMAN_ANDROID_PKG_EXTRA_BUILD_ARGS`
- `PACMAN_ANDROID_PKG_EXTRA_INSTALL_ARGS`
- `PACMAN_ANDROID_PKG_TARGETS`
- `PACMAN_ANDROID_PKG_DEPENDS`
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
2. verify the SHA256 checksum
3. extract the source tree into the package build root
4. export `PACMAN_ANDROID_SOURCE_WORKTREE`

Optional source-shape helpers:

- `PACMAN_ANDROID_PKG_SOURCE_FILENAME`
- `PACMAN_ANDROID_PKG_SOURCE_DIRNAME`

If source metadata is not provided, recipes may still export `PACMAN_ANDROID_SOURCE_WORKTREE` manually from `pacman_android_recipe_prepare`.

## Patch Application

If `<repo>-packages/<name>/patches/` exists, the builder applies all `*.patch` files in lexical order after `pacman_android_recipe_prepare` and before `pacman_android_recipe_configure`.

The builder expects the recipe to export one of:

- `PACMAN_ANDROID_SOURCE_WORKTREE`
- `PACMAN_ANDROID_PATCH_TARGET_DIR`

Optional:

- `PACMAN_ANDROID_PATCH_STRIP_LEVEL`

## Output Layout

For a package `<repo>/<name>` and target `<target>`:

- build workdir:
  - `out/build/<repo>/<name>/<target>/`
- staged filesystem:
  - `out/stage/<repo>/<name>/<target>/rootfs/`
- package metadata:
  - `out/stage/<repo>/<name>/<target>/metadata/`
- final package outputs:
  - `out/packages/<repo>/<target>/`

The builder currently emits:

- `<name>-<version>-<reversion>-<arch>.pkg.tar.zst`
- matching `.PKGINFO`
- matching `.BUILDINFO`
- matching `.MTREE`
- a simple `.manifest`
