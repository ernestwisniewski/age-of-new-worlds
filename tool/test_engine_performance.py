#!/usr/bin/env python3
"""Negative fixtures for the portable engine performance gate."""

from __future__ import annotations

import csv
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any, Callable


REPO_ROOT = Path(__file__).resolve().parent.parent
CHECKER = REPO_ROOT / "tool/check_engine_performance.py"
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


class Fixture:
    def __init__(self) -> None:
        self.root = Path(tempfile.mkdtemp(prefix="aonw-engine-performance-"))
        self.rows: dict[str, dict[str, str]] = {}
        self.baseline: dict[str, Any] = {}
        self.reset()

    def close(self) -> None:
        shutil.rmtree(self.root)

    def reset(self) -> None:
        self.rows = {
            "engine": row("apply", "0000000000000001", work=True),
            "runtime": row("runtime_dispatch_accepted", "0000000000000002"),
            "ai": row("strategic_plan", "0000000000000003"),
        }
        rustc = version(["rustc", "--version"])
        cargo = version(["cargo", "--version"])
        ceilings = {
            f"{scope}/{value['workload']}/1200/1": ceiling(value, scope == "engine")
            for scope, value in self.rows.items()
        }
        self.baseline = {
            "provenance": {
                "rustc": rustc,
                "cargo": cargo,
                "allocator": {
                    "name": "stats_alloc",
                    "version": "0.1.10",
                    "source": "https://crates.io/crates/stats_alloc/0.1.10",
                },
                "measurement": {
                    "threads": 1,
                    "setup": "outside",
                    "warmupIterations": 3,
                    "timings": "diagnostic-only",
                },
                "reviewedDate": "2099-01-01",
            },
            "stage": "engine",
            "columns": COLUMNS,
            "ceilings": dict(sorted(ceilings.items())),
        }
        self.write()

    def path(self, name: str) -> Path:
        return self.root / f"{name}.csv"

    def write(self) -> None:
        write_csv(self.path("engine"), ENGINE_HEADER, self.rows["engine"])
        write_csv(self.path("runtime"), RUNTIME_HEADER, self.rows["runtime"])
        write_csv(self.path("ai"), RUNTIME_HEADER, self.rows["ai"])
        (self.root / "baseline.json").write_text(
            json.dumps(self.baseline) + "\n", encoding="utf-8"
        )

    def run(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                sys.executable,
                str(CHECKER),
                "check",
                "--repo-root",
                str(REPO_ROOT),
                "--engine-csv",
                str(self.path("engine")),
                "--runtime-csv",
                str(self.path("runtime")),
                "--ai-csv",
                str(self.path("ai")),
                "--baseline",
                str(self.root / "baseline.json"),
                "--report",
                str(self.root / "report.json"),
            ],
            capture_output=True,
            text=True,
            check=False,
        )


def row(workload: str, signature: str, *, work: bool = False) -> dict[str, str]:
    value = {
        "workload": workload,
        "tiles": "1200",
        "units": "1",
        "iterations": "20",
        "allocations": "10",
        "reallocations": "2",
        "allocated_bytes": "1000",
        "payload_bytes": "100",
        "signature": signature,
        "median_ns": "50",
        "p95_ns": "100",
    }
    if work:
        value.update(
            {
                "frontier_pops": "3",
                "expanded_tiles": "2",
                "examined_edges": "6",
                "heap_pushes": "7",
                "route_records": "7",
            }
        )
    return value


def ceiling(value: dict[str, str], work: bool) -> list[Any]:
    return [
        value["signature"],
        20,
        10,
        2,
        1000,
        100,
        *([3, 2, 6, 7, 7] if work else [0, 0, 0, 0, 0]),
    ]


def version(command: list[str]) -> str:
    return subprocess.run(command, capture_output=True, text=True, check=True).stdout.strip()


def write_csv(path: Path, header: list[str], value: dict[str, str]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=header)
        writer.writeheader()
        writer.writerow(value)


def expect_rejection(
    fixture: Fixture, label: str, mutation: Callable[[Fixture], None]
) -> None:
    fixture.reset()
    mutation(fixture)
    fixture.write()
    result = fixture.run()
    if result.returncode == 0:
        raise RuntimeError(f"engine performance checker accepted {label}")
    print(f"Engine performance checker rejected {label}.")


def main() -> None:
    fixture = Fixture()
    try:
        baseline = fixture.run()
        if baseline.returncode != 0:
            raise RuntimeError(f"baseline fixture failed: {baseline.stderr}")
        expect_rejection(
            fixture,
            "result-signature drift",
            lambda value: value.rows["engine"].update(
                {"signature": "0000000000000009"}
            ),
        )
        expect_rejection(
            fixture,
            "an allocation regression",
            lambda value: value.rows["runtime"].update({"allocations": "11"}),
        )
        expect_rejection(
            fixture,
            "an allocated-byte regression",
            lambda value: value.rows["ai"].update({"allocated_bytes": "1001"}),
        )
        expect_rejection(
            fixture,
            "a payload regression",
            lambda value: value.rows["runtime"].update({"payload_bytes": "101"}),
        )
        expect_rejection(
            fixture,
            "a work-counter regression",
            lambda value: value.rows["engine"].update({"frontier_pops": "4"}),
        )
        expect_rejection(
            fixture,
            "a reduced sample count",
            lambda value: value.rows["ai"].update({"iterations": "19"}),
        )
        expect_rejection(
            fixture,
            "an unreviewed workload",
            lambda value: value.rows["ai"].update({"workload": "mcts_plan"}),
        )
        expect_rejection(
            fixture,
            "an unknown baseline field",
            lambda value: value.baseline.update({"compatibilityMode": True}),
        )
    finally:
        fixture.close()
    print("Engine performance negative tests passed.")


if __name__ == "__main__":
    main()
