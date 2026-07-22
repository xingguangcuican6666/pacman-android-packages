# CI Matrix

## Goal

The repository should have two CI lanes before the full package builder exists:

1. Build and publish a reusable Docker builder image.
2. Run a package target matrix that validates Android-native compilation for changed canonical package directories:
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

1. Detect changed package directories under `<repo>-packages/<name>/`.
2. Restore or download the Android NDK.
3. Select each changed package recipe automatically.
4. Resolve target metadata from the repo-local target map.
5. Build that package with the repository-local builder for the selected architecture.
6. Emit artifacts under `out/packages/<repo>/<target>/`.
7. A separate upload workflow may publish artifacts from successful non-PR build runs.

## Current Target Map

- `x86_64` -> `x86_64-linux-android`
- `i686` -> `i686-linux-android`
- `armhf` -> `armv7a-linux-androideabi`
- `aarch64` -> `aarch64-linux-android`

## Package Selection

By default, CI automatically detects package directories touched by the current change set:

- `pull_request`: files changed in the PR
- `push`: files changed in the pushed compare range
- `workflow_dispatch`: optional comma-separated `packages` input, otherwise files changed in `HEAD`

Only directories matching `<repo>-packages/<name>/` are selected for the build matrix.

## Why Real Package Builds

Building changed package recipes validates more than the original smoke binary:

- Docker container is usable
- Android NDK is downloadable
- Target triples are wired correctly
- Package-specific source fetch and configure logic works
- ALPM package emission works from the same repository contract
- All four requested architectures can build the selected package from the same repository contract

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
