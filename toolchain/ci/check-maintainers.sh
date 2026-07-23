#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
EXPECTED_MAINTAINER="${EXPECTED_MAINTAINER:-xingguangcuican6666}"

status=0

while IFS= read -r -d '' recipe; do
  rel="${recipe#$REPO_ROOT/}"
  maintainer="$(
    RECIPE_FILE="$recipe" PACMAN_ANDROID_TARGET=aarch64 bash -c '
      set -euo pipefail
      source "$RECIPE_FILE"
      printf "%s" "${PACMAN_ANDROID_PKG_MAINTAINER:-}"
    '
  )"

  if [[ "$maintainer" != "$EXPECTED_MAINTAINER" ]]; then
    echo "unexpected maintainer ($maintainer): $rel" >&2
    status=1
  fi
done < <(
  find "$REPO_ROOT" \
    -mindepth 2 \
    -maxdepth 2 \
    -type f \
    \( -path "$REPO_ROOT/core-packages/*/package.sh" \
    -o -path "$REPO_ROOT/extra-packages/*/package.sh" \
    -o -path "$REPO_ROOT/multilib-packages/*/package.sh" \) \
    -print0 | sort -z
)

exit "$status"
