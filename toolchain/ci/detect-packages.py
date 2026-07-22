#!/usr/bin/env python3
import argparse
import json
import sys
from pathlib import Path


TARGETS = ["x86_64", "i686", "armhf", "aarch64"]
PACKAGE_SUFFIX = "-packages"
DISABLED_COLLECTION = "disabled-packages"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--packages", default="", help="Comma-separated package refs")
    parser.add_argument("--github-output", default="", help="Path to GitHub output file")
    parser.add_argument("--plan-file", default="", help="Path to sync plan JSON file")
    parser.add_argument("--repo-root", default=".", help="Repository root")
    return parser.parse_args()


def collection_repo(collection: str) -> str:
    if collection == DISABLED_COLLECTION or not collection.endswith(PACKAGE_SUFFIX):
        return ""
    return collection[: -len(PACKAGE_SUFFIX)]


def discover_active_collections(repo_root: Path) -> list[str]:
    collections = []
    for entry in sorted(repo_root.iterdir()):
        if not entry.is_dir():
            continue
        name = entry.name
        if name == DISABLED_COLLECTION:
            continue
        if name.endswith(PACKAGE_SUFFIX):
            collections.append(name)
    return collections


def active_ref_from_path(path: str) -> dict | None:
    parts = Path(path).parts
    if len(parts) < 2:
      return None
    collection = parts[0]
    repo = collection_repo(collection)
    if not repo:
        return None
    package = parts[1]
    return {"collection": collection, "repo": repo, "package": package}


def disabled_package_from_path(path: str) -> str:
    parts = Path(path).parts
    if len(parts) < 2 or parts[0] != DISABLED_COLLECTION:
        return ""
    return parts[1]


def active_package_exists(repo_root: Path, ref: dict) -> bool:
    return (repo_root / ref["collection"] / ref["package"] / "package.sh").is_file()


def parse_package_ref(raw: str, active_collections: list[str], repo_root: Path) -> dict:
    raw = raw.strip()
    if not raw:
        raise ValueError("empty package ref")

    if "/" in raw:
        first, package = raw.split("/", 1)
        collection = first if first.endswith(PACKAGE_SUFFIX) else f"{first}{PACKAGE_SUFFIX}"
        repo = collection_repo(collection)
        if not repo:
            raise ValueError(f"invalid active package collection: {collection}")
        ref = {"collection": collection, "repo": repo, "package": package}
        if not active_package_exists(repo_root, ref):
            raise ValueError(f"package ref not found: {raw}")
        return ref

    matches = []
    for collection in active_collections:
        ref = {"collection": collection, "repo": collection_repo(collection), "package": raw}
        if active_package_exists(repo_root, ref):
            matches.append(ref)
    if len(matches) == 1:
        return matches[0]
    if len(matches) > 1:
        raise ValueError(f"ambiguous package ref: {raw}")
    raise ValueError(f"package ref not found: {raw}")


def parse_csv_refs(raw: str, active_collections: list[str], repo_root: Path) -> list[dict]:
    refs = []
    seen = set()
    for item in raw.split(","):
        if not item.strip():
            continue
        ref = parse_package_ref(item, active_collections, repo_root)
        key = (ref["collection"], ref["package"])
        if key in seen:
            continue
        seen.add(key)
        refs.append(ref)
    return sorted(refs, key=lambda ref: (ref["repo"], ref["package"]))


def parse_change_records(lines: list[str]) -> list[dict]:
    records = []
    for raw in lines:
        line = raw.rstrip("\n")
        if not line:
            continue
        parts = line.split("\t")
        while len(parts) < 3:
            parts.append("")
        status, previous, current = parts[:3]
        records.append({"status": status or "modified", "previous": previous, "current": current})
    return records


def derive_refs_from_changes(records: list[dict], repo_root: Path) -> tuple[list[dict], list[str]]:
    current_refs = {}
    old_refs = {}
    removals = set()

    for record in records:
        status = record["status"]
        current = record["current"]
        previous = record["previous"]

        if status == "removed" and not previous:
            previous = current

        if current and status != "removed":
            ref = active_ref_from_path(current)
            if ref and active_package_exists(repo_root, ref):
                current_refs[(ref["collection"], ref["package"])] = ref

        if previous:
            old_ref = active_ref_from_path(previous)
            if old_ref:
                old_refs[(old_ref["collection"], old_ref["package"])] = old_ref

        disabled_package = disabled_package_from_path(current)
        if disabled_package:
            removals.add(disabled_package)

    for key, old_ref in old_refs.items():
        if key not in current_refs:
            removals.add(old_ref["package"])

    build_refs = sorted(current_refs.values(), key=lambda ref: (ref["repo"], ref["package"]))
    removal_list = sorted(removals)
    return build_refs, removal_list


def build_matrix(refs: list[dict]) -> list[dict]:
    matrix = []
    for ref in refs:
        package_ref = f'{ref["repo"]}/{ref["package"]}'
        for target in TARGETS:
            matrix.append(
                {
                    "package_ref": package_ref,
                    "collection": ref["collection"],
                    "repo": ref["repo"],
                    "package": ref["package"],
                    "target": target,
                }
            )
    return matrix


def write_outputs(path: str, refs: list[dict], removals: list[str]) -> None:
    payload = {
        "has_packages": bool(refs),
        "packages": refs,
        "matrix": build_matrix(refs),
        "remove_packages": removals,
        "has_removals": bool(removals),
    }
    lines = [
        f'has_packages={"true" if payload["has_packages"] else "false"}',
        f'has_removals={"true" if payload["has_removals"] else "false"}',
        f'packages={json.dumps(payload["packages"], separators=(",", ":"))}',
        f'matrix={json.dumps(payload["matrix"], separators=(",", ":"))}',
        f'remove_packages={json.dumps(payload["remove_packages"], separators=(",", ":"))}',
    ]
    Path(path).write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_plan(path: str, refs: list[dict], removals: list[str]) -> None:
    plan = {
        "build_packages": refs,
        "build_matrix": build_matrix(refs),
        "remove_packages": removals,
    }
    Path(path).write_text(json.dumps(plan, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def main() -> None:
    args = parse_args()
    repo_root = Path(args.repo_root).resolve()
    active_collections = discover_active_collections(repo_root)

    if args.packages:
        refs = parse_csv_refs(args.packages, active_collections, repo_root)
        removals = []
    else:
        refs, removals = derive_refs_from_changes(parse_change_records(list(sys.stdin)), repo_root)

    if args.github_output:
        write_outputs(args.github_output, refs, removals)
    if args.plan_file:
        write_plan(args.plan_file, refs, removals)
    if not args.github_output and not args.plan_file:
        print(
            json.dumps(
                {
                    "has_packages": bool(refs),
                    "has_removals": bool(removals),
                    "packages": refs,
                    "matrix": build_matrix(refs),
                    "remove_packages": removals,
                },
                separators=(",", ":"),
            )
        )


if __name__ == "__main__":
    main()
