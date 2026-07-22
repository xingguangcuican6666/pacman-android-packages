# Architecture

## Goal

Build a new pacman-oriented package build system for Android native targets without inheriting the full Termux packaging framework.

## Constraints

- The repository should stay small and understandable.
- Package recipes should not depend on large global shell state.
- Toolchain preparation may reuse upstream Termux logic, but package build flow should be repo-local.
- Runtime installation lives under a fixed pacman `RootDir`, default `/data/adb/pacman`.
- Package payloads should preserve normal Unix layout under that `RootDir`.
- The first milestone is one reproducible package build, not feature parity with Termux.

## Proposed Repository Shape

- `packages/<name>/`
  - Per-package recipe, patches, metadata, and tests.
- `toolchain/`
  - Local logic for SDK/NDK detection, sysroot selection, target triples, compiler wrappers, and environment export.
- `docker/`
  - Builder image definition for local development and CI.
- `.github/workflows/`
  - Matrix builds, builder image publication, and future package publishing.
- `vendor/`
  - Downloaded or synced third-party sources such as the Android NDK, `ndk-toolchain-clang-with-flang`, or a Termux reference checkout.
- `out/`
  - Build directories, staging roots, package artifacts, and repository metadata.
- `docs/`
  - Design and operating notes.

## Build System Direction

The new system should split into four layers:

1. Toolchain preparation
   - Download or locate Android NDK.
   - Reuse or adapt `termux/ndk-toolchain-clang-with-flang` and selected Termux sysroot logic.
   - Produce a working Android-native toolchain view for package builds.

2. Build environment
   - Resolve target ABI, API level, `RootDir`, compiler, linker, and pkg-config paths.
   - Export a deterministic environment for package recipes.

3. Package recipe execution
   - Fetch sources.
   - Apply patches.
   - Configure, build, stage, and package.
   - Keep package filesystem layout conventional so files land under `RootDir/usr`, `RootDir/etc`, `RootDir/lib`, and similar paths.

4. Repository publishing
   - Emit pacman packages.
   - Update `core.db` and `core.files`.
   - Publish artifacts to the Android repository host.

The first CI implementation should still validate the toolchain before package recipes exist. A smoke build that compiles one Android-native binary per target architecture is sufficient for the first cut.

## What We Are Not Reusing Wholesale

- Termux package collection.
- Termux monolithic shell step framework.
- Termux repo metadata layout beyond what is required for pacman output.
- KSU-specific runtime layout conventions for package contents.

## First Practical Milestones

1. Add a toolchain-prep command that materializes NDK/sysroot assets into `vendor/`.
2. Add local target descriptions for `x86_64`, `i686`, `armhf`, and `aarch64`.
3. Define the default package layout contract around `RootDir=/data/adb/pacman`.
4. Add a reusable Docker builder image.
5. Add a GitHub Actions matrix that smoke-compiles one Android-native binary for each target.
6. Build one tiny leaf package using the new environment.
7. Package it as a pacman artifact and upload it to the `core` repo.
