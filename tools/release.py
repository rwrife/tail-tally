#!/usr/bin/env python3
"""Small, dependency-free helpers for Tail Tally release validation."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import sys
from typing import Sequence


PRERELEASE_IDENTIFIER = r"(?:0|[1-9]\d*|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*)"
VERSION_RE = re.compile(
    r"^(?P<release>(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)"
    rf"(?:-{PRERELEASE_IDENTIFIER}(?:\.{PRERELEASE_IDENTIFIER})*)?)"
    r"\+(?P<build>[1-9]\d*)$"
)


def read_pubspec_version(pubspec: Path) -> str:
    matches = []
    for line in pubspec.read_text(encoding="utf-8").splitlines():
        match = re.fullmatch(r"version:\s*([^\s#]+)\s*(?:#.*)?", line)
        if match:
            matches.append(match.group(1))
    if len(matches) != 1:
        raise ValueError(f"expected exactly one top-level version in {pubspec}")
    if VERSION_RE.fullmatch(matches[0]) is None:
        raise ValueError(
            "pubspec version must be SemVer <major>.<minor>.<patch>"
            "[-prerelease]+<positive-build>"
        )
    return matches[0]


def release_version(version: str) -> str:
    match = VERSION_RE.fullmatch(version)
    if match is None:
        raise ValueError(f"invalid pubspec version: {version}")
    return match.group("release")


def validate(pubspec: Path, tag: str | None, expected: str | None) -> str:
    version = read_pubspec_version(pubspec)
    if expected and expected != version:
        raise ValueError(
            f"requested version {expected!r} does not match pubspec {version!r}"
        )
    if tag:
        wanted = f"v{release_version(version)}"
        if tag != wanted:
            raise ValueError(
                f"tag {tag!r} does not match pubspec release version {wanted!r}"
            )
    return version


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_provenance(
    output_dir: Path,
    version: str,
    source_sha: str,
    source_ref: str,
    run_url: str,
    assets: Sequence[Path],
) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    subjects = [
        {"name": asset.name, "sha256": sha256(asset)}
        for asset in sorted(assets, key=lambda path: path.name)
    ]
    provenance = {
        "format": "tail-tally-release-provenance-v1",
        "version": version,
        "source": {
            "repository": os.environ.get("GITHUB_SERVER_URL", "https://github.com")
            + "/"
            + os.environ.get("GITHUB_REPOSITORY", "rwrife/tail-tally"),
            "commit": source_sha,
            "ref": source_ref,
        },
        "builder": {
            "workflow_run": run_url,
            "flutter": "3.47.2",
            "commands": [
                "flutter build apk --debug",
                "flutter build ios --simulator --no-codesign",
            ],
        },
        "subjects": subjects,
        "reproduction": {
            "source_checkout": f"git checkout --detach {source_sha}",
            "instructions": "See docs/release-checklist.md",
            "claim": (
                "The metadata identifies source and build inputs for useful "
                "reproduction; byte-identical output is not claimed."
            ),
        },
    }
    provenance_path = output_dir / "PROVENANCE.json"
    provenance_path.write_text(
        json.dumps(provenance, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )

    checksummed = [*subjects, {"name": provenance_path.name, "sha256": sha256(provenance_path)}]
    (output_dir / "SHA256SUMS").write_text(
        "".join(f"{item['sha256']}  {item['name']}\n" for item in checksummed),
        encoding="utf-8",
    )


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser()
    subparsers = result.add_subparsers(dest="command", required=True)

    validate_parser = subparsers.add_parser("validate")
    validate_parser.add_argument("--pubspec", type=Path, default=Path("pubspec.yaml"))
    validate_parser.add_argument("--tag")
    validate_parser.add_argument("--expected")
    validate_parser.add_argument("--github-output", action="store_true")

    provenance_parser = subparsers.add_parser("provenance")
    provenance_parser.add_argument("--output-dir", type=Path, required=True)
    provenance_parser.add_argument("--version", required=True)
    provenance_parser.add_argument("--source-sha", required=True)
    provenance_parser.add_argument("--source-ref", required=True)
    provenance_parser.add_argument("--run-url", required=True)
    provenance_parser.add_argument("assets", nargs="+", type=Path)
    return result


def main() -> int:
    args = parser().parse_args()
    try:
        if args.command == "validate":
            version = validate(args.pubspec, args.tag, args.expected)
            if args.github_output:
                print(f"version={version}")
                print(f"release_version={release_version(version)}")
            else:
                print(version)
        else:
            missing = [str(path) for path in args.assets if not path.is_file()]
            if missing:
                raise ValueError(f"release assets do not exist: {', '.join(missing)}")
            write_provenance(
                args.output_dir,
                args.version,
                args.source_sha,
                args.source_ref,
                args.run_url,
                args.assets,
            )
    except (OSError, ValueError) as error:
        print(f"release validation failed: {error}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
