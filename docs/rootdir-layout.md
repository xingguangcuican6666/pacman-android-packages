# RootDir Layout

## Runtime Model

Pacman runs directly against a fixed `RootDir`.

Default:

- `/data/adb/pacman`

Package installation paths live only inside that tree, for example:

- `/data/adb/pacman/usr/bin`
- `/data/adb/pacman/usr/lib`
- `/data/adb/pacman/etc`

## Packaging Implication

This significantly simplifies package shaping:

- Most packages should keep their normal Unix filesystem layout.
- In practice, package payloads can usually remain `usr/bin`, `usr/lib`, `usr/share`, `etc`, and similar paths.
- We do not need a KSU-module-specific payload structure inside packages.

## Working Assumption

For the first version of the build system:

- `RootDir` is configurable.
- The default `RootDir` is `/data/adb/pacman`.
- The package recipe model should assume that 99% of packages do not need layout rewrites.

## Consequences For The Build System

The local environment layer should expose at least:

- `PACMAN_ROOTDIR`
- `PREFIX=/usr`
- `SYSCONFDIR=/etc`

Recipes should stage into a normal Unix filesystem tree, and repository publishing should package that tree without introducing module-specific path transforms.
