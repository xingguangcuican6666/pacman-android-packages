# CI Matrix

## Goal

The repository should have two CI lanes before the full package builder exists:

1. Build and publish a reusable Docker builder image.
2. Run a target matrix that validates Android-native compilation for:
   - `x86_64`
   - `i686`
   - `armhf`
   - `aarch64`

## Builder Image

The builder image is intentionally host-oriented:

- Base: Ubuntu
- Includes generic build dependencies such as `bash`, `curl`, `git`, `unzip`, `llvm`, `clang`, `ninja`, `pkg-config`, `zstd`
- Does not bake package recipes into the image
- Leaves Android NDK acquisition to the repository toolchain layer

This keeps the image reusable while still supporting future repo-local toolchain logic.

## Matrix Contract

Each matrix job should:

1. Restore or download the Android NDK.
2. Resolve target metadata from the repo-local target map.
3. Build a smoke package with the repository-local builder for the selected architecture.
4. Emit artifacts under `out/packages/<target>/`.
5. A separate upload workflow may publish artifacts from successful non-PR build runs.

## Current Target Map

- `x86_64` -> `x86_64-linux-android`
- `i686` -> `i686-linux-android`
- `armhf` -> `armv7a-linux-androideabi`
- `aarch64` -> `aarch64-linux-android`

## Why A Smoke Build First

The repository now has a minimal package recipe and package assembler. The matrix still targets a smoke package because it validates the hardest early risks first:

- Docker container is usable
- Android NDK is downloadable
- Target triples are wired correctly
- ALPM package emission works from the same repository contract
- All four requested architectures can build from the same repository contract

## Upload Secrets

The upload workflow looks for these repository secrets:

- `PACMAN_REPO_UPLOAD_URL`
- `PACMAN_REPO_UPLOAD_TOKEN`

`Build Matrix` itself does not publish packages anymore. `Upload Packages` is responsible for publication.

For automatic publication:

- a successful `Build Matrix` run on branch `main` triggered by `push` or `workflow_dispatch` will trigger `Upload Packages`
- a `pull_request`-triggered `Build Matrix` run will not trigger publication

For manual publication:

- `Upload Packages` also supports `workflow_dispatch`
- provide the source `Build Matrix` run ID as input
- the source run must still be from branch `main`, or upload will be skipped
