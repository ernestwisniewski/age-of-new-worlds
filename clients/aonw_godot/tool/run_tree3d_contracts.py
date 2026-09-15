#!/usr/bin/env python3
"""Verify Tree3D's installed descriptor and native meshes in an isolated project."""
from __future__ import annotations

import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--project", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--expect-feature", action="append", default=[])
    args = parser.parse_args()
    project = args.project.resolve()
    with tempfile.TemporaryDirectory(prefix="aonw-tree3d-contracts-") as directory:
        root = Path(directory)
        shutil.copytree(project / "addons/Tree3D", root / "addons/Tree3D",
                        ignore=shutil.ignore_patterns("*.import"))
        for name in ("tests/test_tree3d_extension.gd", "tests/fixtures/tree3d/upstream-v1.1.0.gdextension.txt"):
            target = root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(project / name, target)
        (root / "project.godot").write_text('config_version=5\n[application]\nconfig/name="Tree3D contracts"\n')
        base = [args.godot, "--headless", "--audio-driver", "Dummy", "--path", str(root)]
        # Explicit load_extension exercises Godot's real library loader without
        # importing unrelated editor plugins, textures or the Rust game boundary.
        commands = [base + ["--script", "res://tests/test_tree3d_extension.gd", "--"]
                    + ["--expect-feature=" + feature for feature in args.expect_feature]]
        for index, command in enumerate(commands):
            result = subprocess.run(command, capture_output=True, text=True, timeout=90)
            output = result.stdout + result.stderr
            print(output, flush=True)
            Path(f"tree3d-contract-{index}.log").write_text(output)
            if result.returncode or any(marker in output for marker in ("ERROR:", "SCRIPT ERROR", "Parse Error", "Compile Error")):
                raise RuntimeError(f"Tree3D contract failed (exit {result.returncode}): " + " ".join(command))
            if "Tree3D extension: PASS" not in output:
                raise RuntimeError("Native Tree3D test did not reach its success marker")


if __name__ == "__main__":
    main()
