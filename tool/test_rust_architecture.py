#!/usr/bin/env python3
"""Negative fixtures for every Rust architecture-policy rule."""

from __future__ import annotations

import copy
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any, Callable


REPO_ROOT = Path(__file__).resolve().parent.parent
CHECKER = REPO_ROOT / "tool/check_rust_architecture.py"


def package(name: str, root: Path, dependencies: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "name": name,
        "manifest_path": str(root / "engine/crates" / name / "Cargo.toml"),
        "dependencies": dependencies,
    }


def dependency(name: str, root: Path, *, external: bool = False) -> dict[str, Any]:
    return {
        "name": name,
        "kind": None,
        "path": None if external else str(root / "engine/crates" / name),
    }


class Fixture:
    def __init__(self) -> None:
        self.root = Path(tempfile.mkdtemp(prefix="aonw-rust-architecture-"))
        self.policy_path = self.root / "engine/quality/architecture_policy.json"
        self.metadata_path = self.root / "metadata.json"
        self.policy: dict[str, Any] = {}
        self.metadata: dict[str, Any] = {}
        self.reset()

    def close(self) -> None:
        shutil.rmtree(self.root)

    def reset(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)
        for crate in ["pure", "adapter"]:
            (self.root / "engine/crates" / crate / "src").mkdir(parents=True, exist_ok=True)
            (self.root / "engine/crates" / crate / "Cargo.toml").write_text(
                f"[package]\nname = \"{crate}\"\nversion = \"0.1.0\"\n\n"
                "[lints]\nworkspace = true\n",
                encoding="utf-8",
            )
            (self.root / "engine/crates" / crate / "src/lib.rs").write_text(
                "pub fn value() -> u8 {\n    1\n}\n", encoding="utf-8"
            )
        (self.root / "engine/quality").mkdir(parents=True, exist_ok=True)
        (self.root / "engine/Cargo.toml").write_text("[workspace]\n", encoding="utf-8")
        self.policy = {
            "provenance": {
                "reviewedDate": "2099-01-01",
                "rustc": "fixture rustc",
                "cargo": "fixture cargo",
                "methodology": "exact-crate-edges-pure-source-unsafe-and-line-ratchet",
            },
            "workspaceManifest": "engine/Cargo.toml",
            "crateDependencies": {
                "adapter": ["normal:pure"],
                "pure": [],
            },
            "pureCrates": ["pure"],
            "forbiddenPureDependencies": ["rand"],
            "forbiddenPureSourcePatterns": {
                "filesystem": r"\bstd::fs\b",
            },
            "unsafeAllowlist": {},
            "maxNewRustLines": 5,
            "lineExceptions": {},
        }
        self.metadata = {
            "packages": [
                package("pure", self.root, []),
                package("adapter", self.root, [dependency("pure", self.root)]),
            ]
        }
        self.write()

    def write(self) -> None:
        self.policy_path.write_text(
            json.dumps(self.policy, indent=2) + "\n", encoding="utf-8"
        )
        self.metadata_path.write_text(
            json.dumps(self.metadata, indent=2) + "\n", encoding="utf-8"
        )

    def run(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                sys.executable,
                str(CHECKER),
                "--repo-root",
                str(self.root),
                "--policy",
                str(self.policy_path),
                "--metadata-file",
                str(self.metadata_path),
            ],
            capture_output=True,
            text=True,
            check=False,
        )


def expect_rejection(fixture: Fixture, label: str, mutation: Callable[[Fixture], None]) -> None:
    fixture.reset()
    mutation(fixture)
    fixture.write()
    result = fixture.run()
    if result.returncode == 0:
        raise RuntimeError(f"architecture checker accepted {label}")
    print(f"Architecture checker rejected {label}.")


def main() -> None:
    fixture = Fixture()
    try:
        baseline = fixture.run()
        if baseline.returncode != 0:
            raise RuntimeError(f"baseline fixture failed: {baseline.stderr}")

        expect_rejection(
            fixture,
            "an unclassified workspace crate",
            lambda value: value.metadata["packages"].append(package("ghost", value.root, [])),
        )
        expect_rejection(
            fixture,
            "an unreviewed internal dependency edge",
            lambda value: value.metadata["packages"][0]["dependencies"].append(
                dependency("adapter", value.root)
            ),
        )
        expect_rejection(
            fixture,
            "a forbidden pure dependency",
            lambda value: value.metadata["packages"][0]["dependencies"].append(
                dependency("rand", value.root, external=True)
            ),
        )
        expect_rejection(
            fixture,
            "filesystem access in a pure crate",
            lambda value: (value.root / "engine/crates/pure/src/lib.rs").write_text(
                "use std::fs;\npub fn value() -> u8 { 1 }\n", encoding="utf-8"
            ),
        )
        expect_rejection(
            fixture,
            "a crate not inheriting workspace lints",
            lambda value: (value.root / "engine/crates/pure/Cargo.toml").write_text(
                "[package]\nname = \"pure\"\nversion = \"0.1.0\"\n",
                encoding="utf-8",
            ),
        )
        expect_rejection(
            fixture,
            "an unreviewed unsafe block",
            lambda value: (value.root / "engine/crates/pure/src/lib.rs").write_text(
                "pub unsafe fn value() -> u8 {\n    1\n}\n", encoding="utf-8"
            ),
        )
        expect_rejection(
            fixture,
            "a new oversized Rust source",
            lambda value: (value.root / "engine/crates/pure/src/lib.rs").write_text(
                "\n".join(["// line"] * 6) + "\n", encoding="utf-8"
            ),
        )
        expect_rejection(
            fixture,
            "an unknown policy field",
            lambda value: value.policy.update({"schemaVersion": 1}),
        )
    finally:
        fixture.close()
    print("Rust architecture negative tests passed.")


if __name__ == "__main__":
    main()
