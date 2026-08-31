#!/usr/bin/env python3
"""Portable engine work, allocation, payload, and result-signature gate."""

from __future__ import annotations

import argparse
import csv
import datetime
import io
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


ENGINE_HEADER = [
    "workload",
    "tiles",
    "units",
    "iterations",
    "allocations",
    "reallocations",
    "allocated_bytes",
    "payload_bytes",
    "frontier_pops",
    "expanded_tiles",
    "examined_edges",
    "heap_pushes",
    "route_records",
    "signature",
    "median_ns",
    "p95_ns",
]
RUNTIME_HEADER = [
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
COLUMNS = [
    "signature",
    "minimumIterations",
    "maxAllocations",
    "maxReallocations",
    "maxAllocatedBytes",
    "maxPayloadBytes",
    "maxFrontierPops",
    "maxExpandedTiles",
    "maxExaminedEdges",
    "maxHeapPushes",
    "maxRouteRecords",
]
BASELINE_KEYS = {"provenance", "stage", "columns", "ceilings"}
PROVENANCE_KEYS = {"rustc", "cargo", "allocator", "measurement", "reviewedDate"}
ALLOCATOR = {
    "name": "stats_alloc",
    "version": "0.1.10",
    "source": "https://crates.io/crates/stats_alloc/0.1.10",
}
MEASUREMENT = {
    "threads": 1,
    "setup": "outside",
    "warmupIterations": 3,
    "timings": "diagnostic-only",
}


class PerformanceFailure(RuntimeError):
    """A malformed benchmark or structural performance regression."""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["report", "check", "snapshot"])
    parser.add_argument(
        "--repo-root", type=Path, default=Path(__file__).resolve().parent.parent
    )
    parser.add_argument(
        "--baseline", type=Path, default=Path("engine/quality/performance_baseline.json")
    )
    parser.add_argument(
        "--report", type=Path, default=Path("/tmp/aonw-engine-performance.json")
    )
    parser.add_argument(
        "--snapshot", type=Path, default=Path("/tmp/aonw-engine-performance-baseline.json")
    )
    parser.add_argument("--engine-csv", type=Path)
    parser.add_argument("--runtime-csv", type=Path)
    parser.add_argument("--ai-csv", type=Path)
    parser.add_argument("--reviewed-date")
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


def benchmark_csv(
    repo_root: Path, package: str, benchmark: str, fixture: Path | None
) -> str:
    if fixture is not None:
        path = fixture if fixture.is_absolute() else repo_root / fixture
        try:
            return path.read_text(encoding="utf-8")
        except OSError as error:
            raise PerformanceFailure(f"cannot read benchmark CSV {path}: {error}") from error
    return run(
        ["cargo", "bench", "--locked", "-p", package, "--bench", benchmark],
        f"{package} {benchmark} benchmark",
        repo_root / "engine",
    )


def unsigned(row: dict[str, str], field: str, label: str) -> int:
    value = row.get(field)
    if value is None or re.fullmatch(r"\d+", value) is None:
        raise PerformanceFailure(f"{label}.{field} must be an unsigned integer")
    return int(value)


def parse_csv(
    source: str, scope: str, header: list[str]
) -> tuple[dict[str, Any], dict[str, Any]]:
    lines = source.splitlines()
    expected_header = ",".join(header)
    try:
        start = lines.index(expected_header)
    except ValueError as error:
        raise PerformanceFailure(f"{scope} benchmark CSV header is missing") from error
    reader = csv.DictReader(io.StringIO("\n".join(lines[start:])))
    if reader.fieldnames != header:
        raise PerformanceFailure(f"{scope} benchmark CSV header differs")
    stable: dict[str, Any] = {}
    timings: dict[str, Any] = {}
    for row_number, row in enumerate(reader, start=2):
        if None in row or any(value is None for value in row.values()):
            raise PerformanceFailure(f"{scope} CSV row {row_number} is malformed")
        workload = row["workload"]
        if re.fullmatch(r"[a-z][a-z0-9_]*", workload) is None:
            raise PerformanceFailure(f"invalid workload at {scope}:{row_number}")
        tiles = unsigned(row, "tiles", scope)
        units = unsigned(row, "units", scope)
        key = f"{scope}/{workload}/{tiles}/{units}"
        if key in stable:
            raise PerformanceFailure(f"duplicate performance workload: {key}")
        signature = row["signature"]
        if re.fullmatch(r"[0-9a-f]{16}", signature) is None:
            raise PerformanceFailure(f"invalid result signature for {key}")
        counters = [
            unsigned(row, field, key) if scope == "engine" else 0
            for field in [
                "frontier_pops",
                "expanded_tiles",
                "examined_edges",
                "heap_pushes",
                "route_records",
            ]
        ]
        stable[key] = [
            signature,
            unsigned(row, "iterations", key),
            unsigned(row, "allocations", key),
            unsigned(row, "reallocations", key),
            unsigned(row, "allocated_bytes", key),
            unsigned(row, "payload_bytes", key),
            *counters,
        ]
        timings[key] = {
            "medianNs": unsigned(row, "median_ns", key),
            "p95Ns": unsigned(row, "p95_ns", key),
        }
    if not stable:
        raise PerformanceFailure(f"{scope} benchmark has no workloads")
    return stable, timings


def provenance() -> dict[str, Any]:
    return {
        "rustc": run(["rustc", "--version"], "rustc version"),
        "cargo": run(["cargo", "--version"], "cargo version"),
        "allocator": ALLOCATOR,
        "measurement": MEASUREMENT,
    }


def build_report(args: argparse.Namespace, repo_root: Path) -> dict[str, Any]:
    sources = [
        ("engine", "aonw_engine", "movement", args.engine_csv, ENGINE_HEADER),
        ("runtime", "aonw_local_runtime", "runtime", args.runtime_csv, RUNTIME_HEADER),
        ("ai", "aonw_ai", "planner", args.ai_csv, RUNTIME_HEADER),
    ]
    stable: dict[str, Any] = {}
    timings: dict[str, Any] = {}
    for scope, package, benchmark, fixture, header in sources:
        parsed, parsed_timings = parse_csv(
            benchmark_csv(repo_root, package, benchmark, fixture), scope, header
        )
        overlap = set(stable) & set(parsed)
        if overlap:
            raise PerformanceFailure(f"performance workload keys overlap: {sorted(overlap)}")
        stable.update(parsed)
        timings.update(parsed_timings)
    return {
        "provenance": provenance(),
        "stage": "engine",
        "columns": COLUMNS,
        "stable": dict(sorted(stable.items())),
        "diagnosticTimings": dict(sorted(timings.items())),
    }


def load_baseline(path: Path) -> dict[str, Any]:
    baseline = strict_object(read_json(path, "performance baseline"), "baseline", BASELINE_KEYS)
    if baseline["stage"] != "engine" or baseline["columns"] != COLUMNS:
        raise PerformanceFailure("performance baseline identity differs")
    provenance_value = strict_object(
        baseline["provenance"], "baseline.provenance", PROVENANCE_KEYS
    )
    if provenance_value["allocator"] != ALLOCATOR or provenance_value["measurement"] != MEASUREMENT:
        raise PerformanceFailure("performance baseline measurement provenance differs")
    if re.fullmatch(r"\d{4}-\d{2}-\d{2}", provenance_value["reviewedDate"]) is None:
        raise PerformanceFailure("performance baseline reviewedDate differs")
    ceilings = baseline["ceilings"]
    if not isinstance(ceilings, dict) or not ceilings or list(ceilings) != sorted(ceilings):
        raise PerformanceFailure("performance ceilings must be non-empty and sorted")
    for key, values in ceilings.items():
        if not isinstance(values, list) or len(values) != len(COLUMNS):
            raise PerformanceFailure(f"performance ceiling shape differs for {key}")
        if re.fullmatch(r"[0-9a-f]{16}", values[0]) is None:
            raise PerformanceFailure(f"performance signature differs for {key}")
        if any(not isinstance(value, int) or value < 0 for value in values[1:]):
            raise PerformanceFailure(f"performance ceilings must be non-negative for {key}")
    return baseline


def validate(report: dict[str, Any], baseline: dict[str, Any]) -> None:
    expected_provenance = baseline["provenance"]
    for field in ["rustc", "cargo", "allocator", "measurement"]:
        if report["provenance"][field] != expected_provenance[field]:
            raise PerformanceFailure(f"performance provenance differs: {field}")
    observed = report["stable"]
    ceilings = baseline["ceilings"]
    if set(observed) != set(ceilings):
        raise PerformanceFailure(
            "performance workload census differs; "
            f"missing={sorted(set(ceilings) - set(observed))}, "
            f"unknown={sorted(set(observed) - set(ceilings))}"
        )
    for key, values in observed.items():
        ceiling = ceilings[key]
        if values[0] != ceiling[0]:
            raise PerformanceFailure(f"result signature differs for {key}")
        if values[1] < ceiling[1]:
            raise PerformanceFailure(f"sample count regressed for {key}")
        for index, column in enumerate(COLUMNS[2:], start=2):
            if values[index] > ceiling[index]:
                raise PerformanceFailure(
                    f"{column} exceeded for {key}: {values[index]} > {ceiling[index]}"
                )


def snapshot(report: dict[str, Any], reviewed_date: str) -> dict[str, Any]:
    if re.fullmatch(r"\d{4}-\d{2}-\d{2}", reviewed_date) is None:
        raise PerformanceFailure("snapshot reviewed date must use YYYY-MM-DD")
    return {
        "provenance": {**report["provenance"], "reviewedDate": reviewed_date},
        "stage": "engine",
        "columns": COLUMNS,
        "ceilings": report["stable"],
    }


def write_json(path: Path, value: Any, *, compact: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not compact:
        path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        return
    lines = [
        "{",
        f'  "provenance": {json.dumps(value["provenance"], sort_keys=True)},',
        f'  "stage": {json.dumps(value["stage"])},',
        f'  "columns": {json.dumps(value["columns"])},',
        '  "ceilings": {',
    ]
    items = list(value["ceilings"].items())
    for index, (key, ceiling) in enumerate(items):
        suffix = "," if index + 1 < len(items) else ""
        lines.append(f"    {json.dumps(key)}: {json.dumps(ceiling)}{suffix}")
    lines.extend(["  }", "}"])
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    args = parse_args()
    repo_root = args.repo_root.resolve()
    report = build_report(args, repo_root)
    report_path = args.report if args.report.is_absolute() else repo_root / args.report
    write_json(report_path, report)
    if args.mode == "report":
        print(f"Wrote engine performance report to {report_path}.")
        return
    if args.mode == "snapshot":
        reviewed_date = args.reviewed_date or datetime.date.today().isoformat()
        candidate = snapshot(report, reviewed_date)
        path = args.snapshot if args.snapshot.is_absolute() else repo_root / args.snapshot
        write_json(path, candidate, compact=True)
        print(f"Wrote engine performance baseline candidate to {path}.")
        return
    baseline_path = args.baseline if args.baseline.is_absolute() else repo_root / args.baseline
    validate(report, load_baseline(baseline_path))
    print(f"Engine performance check passed: {len(report['stable'])} workloads.")


if __name__ == "__main__":
    try:
        main()
    except PerformanceFailure as error:
        print(f"Engine performance check failed: {error}", file=sys.stderr)
        raise SystemExit(1) from error
