#!/usr/bin/env python3
"""Run real Godot raster/UI/camera contracts without importing gameplay extensions.

Uses a temporary project with the exact transitive GDScript dependency closure.
This is NOT a substitute for test_reference_native_controls.gd or editor testing.
"""
from __future__ import annotations
import argparse
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

TESTS = (
    "tests/test_natural_relief.gd",
    "tests/test_reference_terrain.gd",
    "tests/test_reference_parameters.gd",
    "tests/test_reference_parameter_effects.gd",
)


def run(godot: str, project: Path) -> None:
    classes: dict[str, Path] = {}
    for path in project.rglob("*.gd"):
        if "addons" in path.parts or ".godot" in path.parts:
            continue
        match = re.search(r"^class_name\s+(\w+)", path.read_text(), re.MULTILINE)
        if match:
            classes[match[1]] = path
    pending = [project / test for test in TESTS]
    selected: set[Path] = set()
    while pending:
        path = pending.pop()
        if path in selected:
            continue
        if not path.is_file():
            raise FileNotFoundError(f"Missing contract dependency: {path}")
        selected.add(path)
        text = path.read_text()
        pending += [project / ref for ref in re.findall(r'res://([^"\s]+\.gd)', text)]
        pending += [classes[name] for name in set(re.findall(r"\bAonw\w+", text)) if name in classes]
    with tempfile.TemporaryDirectory(prefix="aonw-reference-contracts-") as directory:
        root = Path(directory)
        for path in selected:
            target = root / path.relative_to(project)
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(path, target)
        (root / "project.godot").write_text('config_version=5\n[application]\nconfig/name="Reference contracts"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
        commands = [[godot, "--headless", "--editor", "--path", str(root), "--import"]]
        commands += [[godot, "--headless", "--path", str(root), "--script", "res://" + test] for test in TESTS]
        for command in commands:
            result = subprocess.run(command, capture_output=True, text=True, timeout=180)
            output = result.stdout + result.stderr
            print(output, flush=True)
            # Godot can exit 0 after a script fails to parse. Do not report that as PASS.
            if result.returncode != 0 or any(marker in output for marker in ("SCRIPT ERROR", "Parse Error", "Compile Error", "ERROR:")):
                raise RuntimeError(f"Godot contract command failed: {' '.join(command)}")
        print(f"Passed {len(TESTS)} Godot contract suites using {len(selected)} source scripts.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True)
    parser.add_argument("--project", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    run(args.godot, args.project.resolve())
