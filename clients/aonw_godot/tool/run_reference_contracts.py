#!/usr/bin/env python3
"""Run reference contracts in an isolated Godot project.

--visual-assets adds real Tree3D/PBR rendering; run that mode under Xvfb on CI.
This does not replace the full editor/native terrain tests or map art review.
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
    "tests/test_reference_surface.gd",
)


def run(godot: str, project: Path, visual_assets: bool = False) -> None:
    classes: dict[str, Path] = {}
    for path in project.rglob("*.gd"):
        if "addons" in path.parts or ".godot" in path.parts:
            continue
        match = re.search(r"^class_name\s+(\w+)", path.read_text(), re.MULTILINE)
        if match:
            classes[match[1]] = path
    tests = TESTS + (("tests/test_reference_surface_assets.gd",) if visual_assets else ())
    pending = [project / test for test in tests]
    selected: set[Path] = set()
    while pending:
        path = pending.pop()
        if path in selected:
            continue
        if not path.is_file():
            raise FileNotFoundError(f"Missing contract dependency: {path}")
        selected.add(path)
        text = path.read_text()
        pending += [project / ref for ref in re.findall(r'res://([^"\s]+\.(?:gdshader|gd))', text)]
        pending += [classes[name] for name in set(re.findall(r"\bAonw\w+", text)) if name in classes]
    with tempfile.TemporaryDirectory(prefix="aonw-reference-contracts-") as directory:
        root = Path(directory)
        for path in selected:
            target = root / path.relative_to(project)
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(path, target)
        if visual_assets:
            for folder in ("addons/Tree3D", "assets/reference_materials"):
                shutil.copytree(project / folder, root / folder, ignore=shutil.ignore_patterns("*.import", ".godot"))
        (root / "project.godot").write_text('config_version=5\n[application]\nconfig/name="Reference contracts"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
        base = [godot, "--audio-driver", "Dummy", "--rendering-method", "gl_compatibility",
                "--rendering-driver", "opengl3", "--path", str(root)]
        # Import and logic suites need no display or audio device. Only the asset
        # smoke test needs a real renderer, supplied by Xvfb/Mesa in CI.
        commands = [base + ["--headless", "--editor", "--import"]]
        commands += [base + ([] if test.endswith("_assets.gd") else ["--headless"])
                     + ["--script", "res://" + test] for test in tests]
        for index, command in enumerate(commands):
            try:
                result = subprocess.run(command, capture_output=True, text=True, timeout=300)
            except subprocess.TimeoutExpired as error:
                output = (error.stdout or b"") + (error.stderr or b"")
                Path(f"reference-landscape-{index}.log").write_bytes(output)
                print(output.decode(errors="replace"), flush=True)
                raise
            output = result.stdout + result.stderr
            Path(f"reference-landscape-{index}.log").write_text(output)
            print(output, flush=True)
            # Godot can exit zero after parser/shader failures. That is not a pass.
            if result.returncode != 0 or any(marker in output for marker in ("SCRIPT ERROR", "Parse Error", "Compile Error", "ERROR:")):
                raise RuntimeError(f"Godot contract command failed: {' '.join(command)}")
        if visual_assets:
            shutil.copyfile(root / "reference-landscape-smoke.png", Path.cwd() / "reference-landscape-smoke.png")
        print(f"Passed {len(tests)} Godot contract suites using {len(selected)} source scripts.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True)
    parser.add_argument("--project", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--visual-assets", action="store_true")
    args = parser.parse_args()
    run(args.godot, args.project.resolve(), args.visual_assets)
