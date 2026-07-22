#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLCHAIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$TOOLCHAIN_DIR/.." && pwd)"

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <x86_64|i686|armhf|aarch64>" >&2
  exit 1
fi

target="$1"
exec "$REPO_ROOT/build-package.sh" pacman-android-smoke "$target"
