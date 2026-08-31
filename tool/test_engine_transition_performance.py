#!/usr/bin/env python3
"""Negative fixtures for the pinned engine transition-performance gate."""

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
CHECKER = REPO_ROOT / "tool/check_engine_transition_performance.py"
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


class Fixture:
    def __init__(self) -> None:
        self.root = Path(tempfile.mkdtemp(prefix="aonw-engine-transition-performance-"))
        self.policy_path = self.root / "policy.json"
        self.environment_path = self.root / "environment.json"
        self.csv_path = self.root / "benchmark.csv"
        self.report_path = self.root / "report.json"
        self.policy: dict[str, Any] = {}
        self.row: dict[str, str] = {}
        self.reset()

    def close(self) -> None:
        shutil.rmtree(self.root)

    def reset(self) -> None:
        environment = {
            "operatingSystem": "macOS",
            "operatingSystemVersion": "fixture",
            "architecture": "arm64",
            "hardwareModel": "fixture-model",
            "processor": "fixture-processor",
            "memoryBytes": 1024,
            "rustc": "fixture-rustc",
            "cargo": "fixture-cargo",
        }
        self.policy = {
            "schemaVersion": 1,
            "owner": "engine",
            "reviewedDate": "2099-01-01",
            "environment": environment,
            "measurement": {
                "benchmark": "aonw_local_runtime/runtime",
                "profile": "bench",
                "threads": 1,
                "warmupIterations": 3,
                "sampleIterations": 20,
                "setup": "outside",
            },
            "budgets": {
                "runtime_dispatch_accepted/1200/1": {
                    "signature": "0000000000000001",
                    "maxP95Ns": 100,
                    "maxAllocations": 10,
                    "maxAllocatedBytes": 1000,
                    "maxPayloadBytes": 0,
                }
            },
        }
        self.row = {
            "workload": "runtime_dispatch_accepted",
            "tiles": "1200",
            "units": "1",
            "iterations": "20",
            "allocations": "10",
            "reallocations": "2",
            "allocated_bytes": "1000",
            "payload_bytes": "0",
            "signature": "0000000000000001",
            "median_ns": "50",
            "p95_ns": "100",
        }
        self.environment_path.write_text(
            json.dumps(environment) + "\n", encoding="utf-8"
        )
        self.write()

    def write(self) -> None:
        self.policy_path.write_text(json.dumps(self.policy) + "\n", encoding="utf-8")
        with self.csv_path.open("w", encoding="utf-8", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=HEADER)
            writer.writeheader()
            writer.writerow(self.row)

    def run(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                sys.executable,
                str(CHECKER),
                "check",
                "--repo-root",
                str(REPO_ROOT),
                "--policy",
                str(self.policy_path),
                "--benchmark-csv",
                str(self.csv_path),
                "--environment-json",
                str(self.environment_path),
                "--report",
                str(self.report_path),
            ],
            capture_output=True,
            text=True,
            check=False,
        )


def expect_rejection(
    fixture: Fixture, label: str, mutation: Callable[[Fixture], None]
) -> None:
    fixture.reset()
    mutation(fixture)
    fixture.write()
    result = fixture.run()
    if result.returncode == 0:
        raise RuntimeError(f"transition performance checker accepted {label}")
    print(f"Transition performance checker rejected {label}.")


def main() -> None:
    fixture = Fixture()
    try:
        baseline = fixture.run()
        if baseline.returncode != 0:
            raise RuntimeError(f"baseline fixture failed: {baseline.stderr}")
        expect_rejection(
            fixture,
            "a latency regression",
            lambda value: value.row.update({"p95_ns": "101"}),
        )
        expect_rejection(
            fixture,
            "an allocation regression",
            lambda value: value.row.update({"allocations": "11"}),
        )
        expect_rejection(
            fixture,
            "an allocated-byte regression",
            lambda value: value.row.update({"allocated_bytes": "1001"}),
        )
        expect_rejection(
            fixture,
            "a payload regression",
            lambda value: value.row.update({"payload_bytes": "1"}),
        )
        expect_rejection(
            fixture,
            "result-signature drift",
            lambda value: value.row.update({"signature": "0000000000000002"}),
        )
        expect_rejection(
            fixture,
            "a reduced sample count",
            lambda value: value.row.update({"iterations": "19"}),
        )
        expect_rejection(
            fixture,
            "a missing workload",
            lambda value: value.row.update({"workload": "runtime_snapshot"}),
        )
        expect_rejection(
            fixture,
            "an unknown policy field",
            lambda value: value.policy.update({"compatibilityMode": True}),
        )
        expect_rejection(
            fixture,
            "a different pinned environment",
            lambda value: value.policy["environment"].update(
                {"hardwareModel": "different-model"}
            ),
        )
    finally:
        fixture.close()
    print("Engine transition performance negative tests passed.")


if __name__ == "__main__":
    main()
