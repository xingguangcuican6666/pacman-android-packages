# Termux Reuse Notes

This project should borrow narrowly from Termux instead of copying its whole build system.

The primary upstream toolchain reference is `termux/ndk-toolchain-clang-with-flang`, with selective fallback to `termux-packages` when sysroot preparation details are needed.

## Areas Worth Reusing

### `ndk-toolchain-clang-with-flang`

Relevant upstream repository:

- `https://github.com/termux/ndk-toolchain-clang-with-flang`

Why:

- It is closer to the actual Android-native toolchain shape we want.
- It reduces the amount of custom toolchain assembly we need to own immediately.

### Termux NDK download/setup

Relevant upstream entry points:

- `scripts/setup-android-sdk.sh`
- `scripts/properties.sh`

Why:

- They already encode Android NDK versioning and download flow.
- They are useful if `ndk-toolchain-clang-with-flang` alone does not cover acquisition and version pinning cleanly.

### Toolchain/sysroot preparation

Relevant upstream entry points:

- `scripts/build/termux_step_setup_toolchain.sh`
- `scripts/build/toolchain/termux_setup_toolchain_29.sh`
- `scripts/build/toolchain/termux_setup_toolchain_23c.sh`
- `ndk-patches/`

Why:

- They contain the logic that turns a raw NDK layout into a working standalone toolchain shape.
- They patch sysroot details that Android-targeted builds often trip over.

## Termux Areas To Avoid Importing Directly

- `packages/`
- `build-package.sh`
- The large `scripts/build/termux_step_*` package pipeline

Reason:

- Those parts carry too much policy and historical compatibility code.
- We want a smaller package recipe model with explicit inputs and outputs.
- Our package layout is simpler because pacman installs only inside `RootDir`, default `/data/adb/pacman`.

## Recommended Local Adaptation

1. Keep `ndk-toolchain-clang-with-flang` as the first upstream reference for toolchain shape.
2. Keep `termux-packages` as a secondary reference checkout under `vendor/src/termux-packages` or a separately cloned working tree.
3. Rewrite only the needed setup logic into repo-local scripts or programs under `toolchain/`.
4. Import only the minimum patch set and transformation logic needed to produce a working sysroot.
5. Treat all imported logic as auditable code, not a black box.

## Initial Toolchain Contract To Define Locally

The local toolchain layer should eventually answer these questions:

- Where is the NDK root?
- Which API level is targeted?
- Which target triple maps to each Android ABI?
- Where is the active sysroot?
- What is the active `RootDir` and which paths inside it are considered canonical?
- Which compiler, archiver, ranlib, strip, and pkg-config should recipes use?
- Which include/lib paths belong to the target versus host?
