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
./build-package.sh <package-name> <target>
```

Current example:

```bash
./build-package.sh pacman-android-smoke aarch64
```

## Current Recipe Contract

Each package lives at:

- `packages/<name>/package.sh`

Required metadata variables:

- `PACMAN_ANDROID_PKG_NAME`
- `PACMAN_ANDROID_PKG_VERSION`
- `PACMAN_ANDROID_PKG_RELEASE`
- `PACMAN_ANDROID_PKG_DESCRIPTION`

Common optional metadata:

- `PACMAN_ANDROID_PKG_URL`
- `PACMAN_ANDROID_PKG_LICENSES`
- `PACMAN_ANDROID_PKG_TARGETS`
- `PACMAN_ANDROID_PKG_DEPENDS`
- `PACMAN_ANDROID_PKG_PROVIDES`
- `PACMAN_ANDROID_PKG_CONFLICTS`
- `PACMAN_ANDROID_PKG_REPLACES`

Supported recipe functions:

- `pacman_android_recipe_prepare`
- `pacman_android_recipe_build`
- `pacman_android_recipe_install`

Only `pacman_android_recipe_install` is mandatory.

## Output Layout

For a package `<name>` and target `<target>`:

- build workdir:
  - `out/build/<name>/<target>/`
- staged filesystem:
  - `out/stage/<name>/<target>/rootfs/`
- package metadata:
  - `out/stage/<name>/<target>/metadata/`
- final package outputs:
  - `out/packages/<target>/`

The builder currently emits:

- `<name>-<version>-<release>-<arch>.pkg.tar.zst`
- matching `.PKGINFO`
- matching `.BUILDINFO`
- matching `.MTREE`
- a simple `.manifest`
