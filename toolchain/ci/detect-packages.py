#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path
from typing import Iterable


TARGETS = ["x86_64", "i686", "armhf", "aarch64"]
PACKAGE_PATTERN = re.compile(r"^packages/([^/]+)/")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--packages", default="", help="Comma-separated package list")
    parser.add_argument("--github-output", default="", help="Path to GitHub output file")
    return parser.parse_args()


def package_names_from_paths(paths: Iterable[str]) -> list[str]:
    packages: set[str] = set()
    for raw_path in paths:
        path = raw_path.strip()
        if not path:
            continue
        match = PACKAGE_PATTERN.match(path)
        if not match:
            continue
        package_name = match.group(1)
        if package_name.startswith("."):
            continue
        packages.add(package_name)
    return sorted(packages)


def package_names_from_csv(raw: str) -> list[str]:
    packages = {item.strip() for item in raw.split(",") if item.strip()}
    return sorted(packages)


def write_outputs(path: str, packages: list[str]) -> None:
    matrix = [{"package": package, "target": target} for package in packages for target in TARGETS]
    output_lines = [
        f"has_packages={'true' if packages else 'false'}",
        f"packages={json.dumps(packages, separators=(',', ':'))}",
        f"matrix={json.dumps(matrix, separators=(',', ':'))}",
    ]
    Path(path).write_text("\n".join(output_lines) + "\n", encoding="utf-8")


def main() -> None:
    args = parse_args()

    if args.packages:
      packages = package_names_from_csv(args.packages)
    else:
      packages = package_names_from_paths(line for line in __import__("sys").stdin)

    if args.github_output:
      write_outputs(args.github_output, packages)
    else:
      print(
          json.dumps(
              {
                  "has_packages": bool(packages),
                  "packages": packages,
                  "matrix": [{"package": package, "target": target} for package in packages for target in TARGETS],
              },
              separators=(",", ":"),
          )
      )


if __name__ == "__main__":
    main()
