#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLCHAIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$TOOLCHAIN_DIR/.." && pwd)"

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <package-ref> <x86_64|i686|armhf|aarch64>" >&2
  exit 1
fi

package_ref="$1"
target="$2"
exec "$REPO_ROOT/build-package.sh" "$package_ref" "$target"
