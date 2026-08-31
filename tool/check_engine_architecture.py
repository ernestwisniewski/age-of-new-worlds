#!/usr/bin/env python3
"""Fail-closed architecture and source ratchet for the Rust workspace."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


POLICY_KEYS = {
    "provenance",
    "workspaceManifest",
    "crateDependencies",
    "pureCrates",
    "forbiddenPureDependencies",
    "forbiddenPureSourcePatterns",
    "unsafeAllowlist",
    "maxNewRustLines",
    "lineExceptions",
}
PROVENANCE_KEYS = {"reviewedDate", "rustc", "cargo", "methodology"}
UNSAFE_PATTERN = re.compile(r"\bunsafe\b")


class ArchitectureFailure(RuntimeError):
    """An actionable architecture-policy failure."""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument(
        "--policy",
        type=Path,
        default=Path("engine/quality/architecture_policy.json"),
    )
    parser.add_argument("--metadata-file", type=Path)
    return parser.parse_args()


def strict_object(value: Any, label: str, keys: set[str]) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ArchitectureFailure(f"{label} must be an object")
    unknown = set(value) - keys
    missing = keys - set(value)
    if unknown or missing:
        raise ArchitectureFailure(
            f"{label} keys differ; missing={sorted(missing)}, unknown={sorted(unknown)}"
        )
    return value


def string_list(value: Any, label: str) -> list[str]:
    if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
        raise ArchitectureFailure(f"{label} must be a string list")
    if len(value) != len(set(value)):
        raise ArchitectureFailure(f"{label} contains duplicates")
    return value


def load_policy(path: Path) -> dict[str, Any]:
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ArchitectureFailure(f"cannot read policy {path}: {error}") from error
    policy = strict_object(raw, "architecture policy", POLICY_KEYS)
    provenance = strict_object(
        policy["provenance"], "architecture provenance", PROVENANCE_KEYS
    )
    for key, value in provenance.items():
        if not isinstance(value, str) or not value:
            raise ArchitectureFailure(f"architecture provenance {key} is required")
    if provenance["methodology"] != "exact-crate-edges-pure-source-unsafe-and-line-ratchet":
        raise ArchitectureFailure("architecture methodology differs")
    if not isinstance(policy["workspaceManifest"], str):
        raise ArchitectureFailure("workspaceManifest must be a string")
    if not isinstance(policy["crateDependencies"], dict):
        raise ArchitectureFailure("crateDependencies must be an object")
    for crate, dependencies in policy["crateDependencies"].items():
        if not isinstance(crate, str):
            raise ArchitectureFailure("crateDependencies keys must be strings")
        string_list(dependencies, f"crateDependencies.{crate}")
    string_list(policy["pureCrates"], "pureCrates")
    string_list(policy["forbiddenPureDependencies"], "forbiddenPureDependencies")
    patterns = policy["forbiddenPureSourcePatterns"]
    if not isinstance(patterns, dict) or not patterns:
        raise ArchitectureFailure("forbiddenPureSourcePatterns must be a non-empty object")
    for rule, pattern in patterns.items():
        if not isinstance(rule, str) or not isinstance(pattern, str):
            raise ArchitectureFailure("source pattern entries must be strings")
        try:
            re.compile(pattern)
        except re.error as error:
            raise ArchitectureFailure(f"invalid source pattern {rule}: {error}") from error
    unsafe = policy["unsafeAllowlist"]
    if not isinstance(unsafe, dict):
        raise ArchitectureFailure("unsafeAllowlist must be an object")
    for path_value, evidence in unsafe.items():
        if not isinstance(path_value, str):
            raise ArchitectureFailure("unsafeAllowlist paths must be strings")
        evidence = strict_object(
            evidence,
            f"unsafeAllowlist.{path_value}",
            {"occurrences", "normalizedLineSha256"},
        )
        if not isinstance(evidence["occurrences"], int) or evidence["occurrences"] <= 0:
            raise ArchitectureFailure(f"unsafe occurrences invalid for {path_value}")
        if not re.fullmatch(r"[0-9a-f]{64}", evidence["normalizedLineSha256"]):
            raise ArchitectureFailure(f"unsafe hash invalid for {path_value}")
    if not isinstance(policy["maxNewRustLines"], int) or policy["maxNewRustLines"] <= 0:
        raise ArchitectureFailure("maxNewRustLines must be a positive integer")
    exceptions = policy["lineExceptions"]
    if not isinstance(exceptions, dict):
        raise ArchitectureFailure("lineExceptions must be an object")
    for path_value, ceiling in exceptions.items():
        if not isinstance(path_value, str) or not isinstance(ceiling, int) or ceiling <= 0:
            raise ArchitectureFailure("lineExceptions must map paths to positive integers")
    return policy


def resolve_repo_path(repo_root: Path, value: str, label: str) -> Path:
    relative = Path(value)
    if relative.is_absolute() or ".." in relative.parts:
        raise ArchitectureFailure(f"{label} must be repository-relative: {value}")
    resolved = (repo_root / relative).resolve()
    try:
        resolved.relative_to(repo_root)
    except ValueError as error:
        raise ArchitectureFailure(f"{label} escapes repository: {value}") from error
    return resolved


def load_metadata(
    repo_root: Path, policy: dict[str, Any], metadata_file: Path | None
) -> dict[str, Any]:
    if metadata_file is not None:
        metadata_path = metadata_file if metadata_file.is_absolute() else repo_root / metadata_file
        try:
            value = json.loads(metadata_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            raise ArchitectureFailure(f"cannot read metadata fixture: {error}") from error
    else:
        manifest = resolve_repo_path(repo_root, policy["workspaceManifest"], "workspaceManifest")
        command = [
            "cargo",
            "metadata",
            "--manifest-path",
            str(manifest),
            "--locked",
            "--no-deps",
            "--format-version",
            "1",
        ]
        result = subprocess.run(command, capture_output=True, text=True, check=False)
        if result.returncode != 0:
            raise ArchitectureFailure(f"cargo metadata failed:\n{result.stderr.strip()}")
        try:
            value = json.loads(result.stdout)
        except json.JSONDecodeError as error:
            raise ArchitectureFailure(f"cargo metadata returned invalid JSON: {error}") from error
    if not isinstance(value, dict) or not isinstance(value.get("packages"), list):
        raise ArchitectureFailure("metadata must contain a packages list")
    return value


def package_map(metadata: dict[str, Any]) -> dict[str, dict[str, Any]]:
    packages: dict[str, dict[str, Any]] = {}
    for package in metadata["packages"]:
        if not isinstance(package, dict) or not isinstance(package.get("name"), str):
            raise ArchitectureFailure("metadata contains a malformed package")
        name = package["name"]
        if name in packages:
            raise ArchitectureFailure(f"duplicate workspace package: {name}")
        if not isinstance(package.get("manifest_path"), str):
            raise ArchitectureFailure(f"package {name} has no manifest_path")
        if not isinstance(package.get("dependencies"), list):
            raise ArchitectureFailure(f"package {name} has no dependency list")
        packages[name] = package
    return packages


def check_dependencies(packages: dict[str, dict[str, Any]], policy: dict[str, Any]) -> None:
    expected = policy["crateDependencies"]
    if set(packages) != set(expected):
        raise ArchitectureFailure(
            "workspace crate census differs; "
            f"missing={sorted(set(expected) - set(packages))}, "
            f"unclassified={sorted(set(packages) - set(expected))}"
        )
    workspace_names = set(packages)
    forbidden = set(policy["forbiddenPureDependencies"])
    pure = set(policy["pureCrates"])
    if not pure <= workspace_names:
        raise ArchitectureFailure(f"unknown pure crates: {sorted(pure - workspace_names)}")
    for name, package in packages.items():
        actual_edges: set[str] = set()
        direct_names: set[str] = set()
        for dependency in package["dependencies"]:
            if not isinstance(dependency, dict) or not isinstance(dependency.get("name"), str):
                raise ArchitectureFailure(f"package {name} has malformed dependency metadata")
            dependency_name = dependency["name"]
            direct_names.add(dependency_name)
            if dependency_name in workspace_names:
                kind = dependency.get("kind") or "normal"
                actual_edges.add(f"{kind}:{dependency_name}")
        expected_edges = set(expected[name])
        if actual_edges != expected_edges:
            raise ArchitectureFailure(
                f"internal dependency edges differ for {name}; "
                f"missing={sorted(expected_edges - actual_edges)}, "
                f"unexpected={sorted(actual_edges - expected_edges)}"
            )
        if name in pure and direct_names & forbidden:
            raise ArchitectureFailure(
                f"pure crate {name} has forbidden dependencies: {sorted(direct_names & forbidden)}"
            )


def check_lints(repo_root: Path, packages: dict[str, dict[str, Any]]) -> None:
    inherited = re.compile(r"(?m)^\[lints\]\s*\nworkspace\s*=\s*true\s*$")
    for name, package in packages.items():
        manifest = Path(package["manifest_path"])
        if not manifest.is_absolute():
            manifest = repo_root / manifest
        try:
            source = manifest.read_text(encoding="utf-8")
        except OSError as error:
            raise ArchitectureFailure(f"cannot read manifest for {name}: {error}") from error
        if inherited.search(source) is None:
            raise ArchitectureFailure(f"crate {name} must inherit [lints] workspace = true")


def check_pure_sources(
    repo_root: Path, packages: dict[str, dict[str, Any]], policy: dict[str, Any]
) -> None:
    patterns = {
        rule: re.compile(pattern)
        for rule, pattern in policy["forbiddenPureSourcePatterns"].items()
    }
    for name in policy["pureCrates"]:
        manifest = Path(packages[name]["manifest_path"])
        if not manifest.is_absolute():
            manifest = repo_root / manifest
        source_root = manifest.parent / "src"
        for path in sorted(source_root.rglob("*.rs")):
            source = path.read_text(encoding="utf-8")
            for rule, pattern in patterns.items():
                match = pattern.search(source)
                if match is not None:
                    relative = path.resolve().relative_to(repo_root).as_posix()
                    line = source.count("\n", 0, match.start()) + 1
                    raise ArchitectureFailure(
                        f"pure crate {name} uses forbidden {rule} API at {relative}:{line}"
                    )


def unsafe_evidence(path: Path) -> tuple[int, str] | None:
    lines = [
        line.strip()
        for line in path.read_text(encoding="utf-8").splitlines()
        if UNSAFE_PATTERN.search(line)
    ]
    if not lines:
        return None
    digest = hashlib.sha256(("\n".join(lines) + "\n").encode()).hexdigest()
    return len(lines), digest


def check_unsafe_and_lines(repo_root: Path, policy: dict[str, Any]) -> None:
    workspace = resolve_repo_path(repo_root, policy["workspaceManifest"], "workspaceManifest").parent
    actual_unsafe: dict[str, tuple[int, str]] = {}
    rust_files = sorted(
        path for path in workspace.joinpath("crates").rglob("*.rs") if "target" not in path.parts
    )
    for path in rust_files:
        evidence = unsafe_evidence(path)
        if evidence is not None:
            actual_unsafe[path.resolve().relative_to(repo_root).as_posix()] = evidence
    expected_unsafe = {
        path_value: (entry["occurrences"], entry["normalizedLineSha256"])
        for path_value, entry in policy["unsafeAllowlist"].items()
    }
    if actual_unsafe != expected_unsafe:
        raise ArchitectureFailure(
            "unsafe source census differs; "
            f"expected={expected_unsafe}, actual={actual_unsafe}"
        )

    maximum = policy["maxNewRustLines"]
    exceptions = policy["lineExceptions"]
    observed_exceptions: set[str] = set()
    for path in rust_files:
        relative = path.resolve().relative_to(repo_root).as_posix()
        line_count = len(path.read_text(encoding="utf-8").splitlines())
        if relative in exceptions:
            observed_exceptions.add(relative)
            if line_count > exceptions[relative]:
                raise ArchitectureFailure(
                    f"Rust source debt grew at {relative}: {line_count} > {exceptions[relative]}"
                )
            if line_count <= maximum:
                raise ArchitectureFailure(f"stale line exception is no longer needed: {relative}")
        elif line_count > maximum:
            raise ArchitectureFailure(
                f"new Rust source exceeds {maximum} lines: {relative} has {line_count}"
            )
    missing_exceptions = set(exceptions) - observed_exceptions
    if missing_exceptions:
        raise ArchitectureFailure(f"line exceptions reference missing files: {sorted(missing_exceptions)}")


def run() -> None:
    args = parse_args()
    repo_root = args.repo_root.resolve()
    policy_path = args.policy if args.policy.is_absolute() else repo_root / args.policy
    policy = load_policy(policy_path)
    if args.metadata_file is None:
        engine_root = resolve_repo_path(
            repo_root, policy["workspaceManifest"], "workspaceManifest"
        ).parent
        tool_versions = [
            (["rustc", "--version"], "rustc"),
            (["cargo", "--version"], "cargo"),
        ]
        for command, field in tool_versions:
            result = subprocess.run(
                command, cwd=engine_root, capture_output=True, text=True, check=False
            )
            if result.returncode != 0 or result.stdout.strip() != policy["provenance"][field]:
                raise ArchitectureFailure(
                    f"architecture {field} provenance differs: {result.stdout.strip()!r}"
                )
    metadata = load_metadata(repo_root, policy, args.metadata_file)
    packages = package_map(metadata)
    check_dependencies(packages, policy)
    check_lints(repo_root, packages)
    check_pure_sources(repo_root, packages, policy)
    check_unsafe_and_lines(repo_root, policy)
    print(
        "Engine architecture check passed: "
        f"{len(packages)} crates, {len(policy['pureCrates'])} pure, "
        f"{len(policy['unsafeAllowlist'])} reviewed unsafe files."
    )


if __name__ == "__main__":
    try:
        run()
    except ArchitectureFailure as error:
        print(f"Engine architecture check failed: {error}", file=sys.stderr)
        raise SystemExit(1) from error
