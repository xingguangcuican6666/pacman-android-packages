# pacman-android-packages

`pacman-android-packages` is a clean-slate repository for a new Android-native package build system that targets pacman repositories and packages.

The project is intentionally not a fork of the full Termux packaging framework. The goal is to keep the build logic small, auditable, and focused on Android-native pacman packaging.

## Project Scope

This repository is being built around a few fixed assumptions:

- Packages are built for Android native targets.
- The package manager runtime uses a fixed pacman `RootDir`.
- The default `RootDir` is `/data/adb/pacman`.
- Most packages should keep a conventional Unix filesystem layout such as `usr/bin`, `usr/lib`, `usr/share`, and `etc`.
- Builder infrastructure should support local development and CI from the same containerized environment.

This repository does not try to reproduce all of Termux packaging behavior.

## Current Status

This is still the foundation stage.

What already exists:

- A repository skeleton for the new build system.
- A builder container definition.
- A target mapping layer for:
  - `x86_64`
  - `i686`
  - `armhf`
  - `aarch64`
- GitHub Actions workflows for:
  - builder image publication
  - multi-architecture smoke builds
- Early documentation for architecture, layout, CI, and upstream reuse boundaries.

What does not exist yet:

- Real package recipes.
- A full toolchain preparation pipeline.
- A pacman package assembly pipeline.
- Repository publication automation tied to real package outputs.

## Repository Layout

- `docs/`
  Design notes, constraints, CI decisions, layout rules, and upstream reuse notes.

- `docker/`
  Builder container definition for local and CI builds.

- `.github/workflows/`
  CI workflows for builder image publication and target-matrix smoke builds.

- `packages/`
  Future package definitions.

- `toolchain/`
  Repository-local target mapping, NDK acquisition, smoke builds, and future toolchain logic.

- `vendor/`
  Ignored location for downloaded toolchains, upstream reference checkouts, and generated sysroot assets.

## Architecture Targets

The current CI/build contract is centered on these targets:

- `x86_64`
- `i686`
- `armhf`
- `aarch64`

The current target loader lives in [toolchain/targets.sh](toolchain/targets.sh).

## Toolchain Direction

The repository will reuse upstream ideas selectively instead of importing a full build system.

Primary upstream references:

- `termux/ndk-toolchain-clang-with-flang`
- `termux/termux-packages`

Planned reuse is limited to toolchain-related areas such as:

- Android NDK acquisition
- sysroot preparation
- Android-target compatibility patches where justified

Package recipes, packaging flow, and repository policy are intended to stay repository-local.

See:

- [docs/architecture.md](docs/architecture.md)
- [docs/rootdir-layout.md](docs/rootdir-layout.md)
- [docs/termux-reuse.md](docs/termux-reuse.md)
- [docs/ci-matrix.md](docs/ci-matrix.md)

## CI and Container Model

The repository includes:

- a reusable builder container at [docker/builder.Dockerfile](docker/builder.Dockerfile)
- a matrix workflow at [.github/workflows/build-matrix.yml](.github/workflows/build-matrix.yml)
- a GHCR publication workflow at [.github/workflows/publish-builder-image.yml](.github/workflows/publish-builder-image.yml)

The first CI milestone is not full package output. It is a reliable multi-architecture Android smoke build from the same repository contract.

## Near-Term Plan

1. Turn the current NDK fetch step into a proper repo-local toolchain preparation flow.
2. Decide how much of `ndk-toolchain-clang-with-flang` should be adapted versus copied.
3. Add the first real package recipe.
4. Emit a real pacman package.
5. Connect package artifacts to repository publication.

## License

Original code in this repository is licensed under the MIT License. See [LICENSE](LICENSE).

Third-party code, patches, vendored sources, or imported logic may be governed by their own upstream licenses. Those components should retain their original notices and must not be relicensed by this repository. See [THIRD_PARTY.md](THIRD_PARTY.md).
