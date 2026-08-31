#!/usr/bin/env python3
"""Pinned-device latency and allocation gate for the engine runtime."""

from __future__ import annotations

import argparse
import csv
import io
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


HEADER = [
    "workload",
    "tiles",
    "units",
    "iterations",
    "allocations",
    "reallocations",
    "allocated_bytes",
    "payload_bytes",
    "signature",
    "median_ns",
    "p95_ns",
]
POLICY_KEYS = {
    "schemaVersion",
    "owner",
    "reviewedDate",
    "environment",
    "measurement",
    "budgets",
}
ENVIRONMENT_KEYS = {
    "operatingSystem",
    "operatingSystemVersion",
    "architecture",
    "hardwareModel",
    "processor",
    "memoryBytes",
    "rustc",
    "cargo",
}
MEASUREMENT_KEYS = {
    "benchmark",
    "profile",
    "threads",
    "warmupIterations",
    "sampleIterations",
    "setup",
}
BUDGET_KEYS = {
    "signature",
    "maxP95Ns",
    "maxAllocations",
    "maxAllocatedBytes",
    "maxPayloadBytes",
}


class PerformanceFailure(RuntimeError):
    """A malformed measurement or exceeded performance budget."""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["report", "check"])
    parser.add_argument(
        "--repo-root", type=Path, default=Path(__file__).resolve().parent.parent
    )
    parser.add_argument(
        "--policy",
        type=Path,
        default=Path("engine/quality/runtime_performance_policy.json"),
    )
    parser.add_argument(
        "--report",
        type=Path,
        default=Path("/tmp/aonw-engine-runtime-performance.json"),
    )
    parser.add_argument("--benchmark-csv", type=Path)
    parser.add_argument("--environment-json", type=Path)
    return parser.parse_args()


def strict_object(value: Any, label: str, keys: set[str]) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise PerformanceFailure(f"{label} must be an object")
    missing = keys - set(value)
    unknown = set(value) - keys
    if missing or unknown:
        raise PerformanceFailure(
            f"{label} keys differ; missing={sorted(missing)}, unknown={sorted(unknown)}"
        )
    return value


def read_json(path: Path, label: str) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise PerformanceFailure(f"cannot read {label} {path}: {error}") from error


def run(command: list[str], label: str, cwd: Path | None = None) -> str:
    result = subprocess.run(
        command, cwd=cwd, capture_output=True, text=True, check=False
    )
    if result.returncode != 0:
        diagnostic = result.stderr.strip() or result.stdout.strip()
        raise PerformanceFailure(f"{label} failed:\n{diagnostic}")
    return result.stdout.strip()


def benchmark_csv(repo_root: Path, fixture: Path | None) -> str:
    if fixture is not None:
        path = fixture if fixture.is_absolute() else repo_root / fixture
        try:
            return path.read_text(encoding="utf-8")
        except OSError as error:
            raise PerformanceFailure(f"cannot read benchmark CSV {path}: {error}") from error
    return run(
        [
            "cargo",
            "bench",
            "--locked",
            "-p",
            "aonw_local_runtime",
            "--bench",
            "runtime",
        ],
        "engine runtime benchmark",
        repo_root / "engine",
    )


def unsigned(row: dict[str, str], field: str, label: str) -> int:
    value = row.get(field)
    if value is None or re.fullmatch(r"\d+", value) is None:
        raise PerformanceFailure(f"{label}.{field} must be an unsigned integer")
    return int(value)


def parse_measurements(source: str) -> dict[str, dict[str, Any]]:
    header = ",".join(HEADER)
    lines = source.splitlines()
    try:
        start = lines.index(header)
    except ValueError as error:
        raise PerformanceFailure("benchmark CSV header is missing") from error
    reader = csv.DictReader(io.StringIO("\n".join(lines[start:])))
    if reader.fieldnames != HEADER:
        raise PerformanceFailure("benchmark CSV header differs")
    measurements: dict[str, dict[str, Any]] = {}
    for row_number, row in enumerate(reader, start=2):
        if None in row or any(value is None for value in row.values()):
            raise PerformanceFailure(f"benchmark CSV row {row_number} is malformed")
        workload = row["workload"]
        if re.fullmatch(r"[a-z][a-z0-9_]*", workload) is None:
            raise PerformanceFailure(f"invalid workload at benchmark CSV row {row_number}")
        key = f"{workload}/{unsigned(row, 'tiles', workload)}/{unsigned(row, 'units', workload)}"
        if key in measurements:
            raise PerformanceFailure(f"duplicate benchmark workload: {key}")
        signature = row["signature"]
        if re.fullmatch(r"[0-9a-f]{16}", signature) is None:
            raise PerformanceFailure(f"invalid signature for {key}")
        measurements[key] = {
            "iterations": unsigned(row, "iterations", key),
            "allocations": unsigned(row, "allocations", key),
            "reallocations": unsigned(row, "reallocations", key),
            "allocatedBytes": unsigned(row, "allocated_bytes", key),
            "payloadBytes": unsigned(row, "payload_bytes", key),
            "signature": signature,
            "medianNs": unsigned(row, "median_ns", key),
            "p95Ns": unsigned(row, "p95_ns", key),
        }
    if not measurements:
        raise PerformanceFailure("benchmark CSV has no workloads")
    return measurements


def current_environment() -> dict[str, Any]:
    memory = run(["sysctl", "-n", "hw.memsize"], "memory identity")
    return {
        "operatingSystem": run(["sw_vers", "-productName"], "operating system"),
        "operatingSystemVersion": run(
            ["sw_vers", "-productVersion"], "operating system version"
        ),
        "architecture": run(["uname", "-m"], "machine architecture"),
        "hardwareModel": run(["sysctl", "-n", "hw.model"], "hardware model"),
        "processor": run(
            ["sysctl", "-n", "machdep.cpu.brand_string"], "processor identity"
        ),
        "memoryBytes": int(memory),
        "rustc": run(["rustc", "--version"], "rustc version"),
        "cargo": run(["cargo", "--version"], "cargo version"),
    }


def load_environment(path: Path | None, repo_root: Path) -> dict[str, Any]:
    if path is None:
        return current_environment()
    resolved = path if path.is_absolute() else repo_root / path
    return strict_object(
        read_json(resolved, "environment fixture"),
        "environment fixture",
        ENVIRONMENT_KEYS,
    )


def load_policy(path: Path) -> dict[str, Any]:
    policy = strict_object(read_json(path, "performance policy"), "policy", POLICY_KEYS)
    if policy["schemaVersion"] != 1 or policy["owner"] != "engine-runtime":
        raise PerformanceFailure("performance policy identity differs")
    if re.fullmatch(r"\d{4}-\d{2}-\d{2}", policy["reviewedDate"]) is None:
        raise PerformanceFailure("performance policy reviewedDate differs")
    strict_object(policy["environment"], "policy.environment", ENVIRONMENT_KEYS)
    measurement = strict_object(
        policy["measurement"], "policy.measurement", MEASUREMENT_KEYS
    )
    if measurement != {
        "benchmark": "aonw_local_runtime/runtime",
        "profile": "bench",
        "threads": 1,
        "warmupIterations": 3,
        "sampleIterations": 20,
        "setup": "outside",
    }:
        raise PerformanceFailure("performance measurement contract differs")
    budgets = policy["budgets"]
    if (
        not isinstance(budgets, dict)
        or not budgets
        or list(budgets) != sorted(budgets, key=workload_sort_key)
    ):
        raise PerformanceFailure("performance budgets must be non-empty and sorted")
    for key, budget in budgets.items():
        if re.fullmatch(r"[a-z][a-z0-9_]*/\d+/\d+", key) is None:
            raise PerformanceFailure(f"invalid performance workload key: {key}")
        values = strict_object(budget, f"budget {key}", BUDGET_KEYS)
        if re.fullmatch(r"[0-9a-f]{16}", values["signature"]) is None:
            raise PerformanceFailure(f"invalid budget signature for {key}")
        for field in BUDGET_KEYS - {"signature"}:
            if not isinstance(values[field], int) or values[field] < 0:
                raise PerformanceFailure(f"budget {key}.{field} must be non-negative")
        if values["maxP95Ns"] == 0:
            raise PerformanceFailure(f"budget {key}.maxP95Ns must be positive")
    return policy


def workload_sort_key(key: str) -> tuple[str, int, int]:
    parts = key.rsplit("/", 2)
    if len(parts) != 3 or not parts[1].isdigit() or not parts[2].isdigit():
        return (key, -1, -1)
    return (parts[0], int(parts[1]), int(parts[2]))


def validate(
    policy: dict[str, Any], environment: dict[str, Any], measurements: dict[str, Any]
) -> None:
    if environment != policy["environment"]:
        differing = sorted(
            key
            for key in ENVIRONMENT_KEYS
            if environment.get(key) != policy["environment"].get(key)
        )
        raise PerformanceFailure(f"pinned environment differs: {differing}")
    iterations = policy["measurement"]["sampleIterations"]
    for key, budget in policy["budgets"].items():
        observed = measurements.get(key)
        if observed is None:
            raise PerformanceFailure(f"required performance workload is missing: {key}")
        if observed["iterations"] != iterations:
            raise PerformanceFailure(f"sample count differs for {key}")
        if observed["signature"] != budget["signature"]:
            raise PerformanceFailure(f"result signature differs for {key}")
        comparisons = {
            "p95Ns": "maxP95Ns",
            "allocations": "maxAllocations",
            "allocatedBytes": "maxAllocatedBytes",
            "payloadBytes": "maxPayloadBytes",
        }
        for observed_field, budget_field in comparisons.items():
            if observed[observed_field] > budget[budget_field]:
                raise PerformanceFailure(
                    f"{observed_field} budget exceeded for {key}: "
                    f"{observed[observed_field]} > {budget[budget_field]}"
                )


def write_report(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def main() -> None:
    args = parse_args()
    repo_root = args.repo_root.resolve()
    policy_path = args.policy if args.policy.is_absolute() else repo_root / args.policy
    policy = load_policy(policy_path)
    environment = load_environment(args.environment_json, repo_root)
    measurements = parse_measurements(benchmark_csv(repo_root, args.benchmark_csv))
    selected = {key: measurements[key] for key in policy["budgets"] if key in measurements}
    report = {
        "environment": environment,
        "measurement": policy["measurement"],
        "reviewedDate": policy["reviewedDate"],
        "workloads": selected,
    }
    report_path = args.report if args.report.is_absolute() else repo_root / args.report
    write_report(report_path, report)
    if args.mode == "check":
        validate(policy, environment, measurements)
        print(
            "Engine runtime performance check passed: "
            f"{len(selected)} workloads on {environment['hardwareModel']}."
        )
    else:
        print(f"Wrote engine runtime performance report to {report_path}.")


if __name__ == "__main__":
    try:
        main()
    except PerformanceFailure as error:
        print(f"Engine runtime performance check failed: {error}", file=sys.stderr)
        raise SystemExit(1) from error
