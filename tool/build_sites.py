#!/usr/bin/env python3
"""Stage only the homepage and engine website, including current Rust API docs."""

from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def build():
    subprocess.run(
        ["cargo", "doc", "--workspace", "--no-deps", "--locked"],
        cwd=ROOT / "engine", check=True,
    )
    for name in ("homepage", "engine-docs"):
        output = ROOT / "build" / name
        if output.exists():
            shutil.rmtree(output)
        output.mkdir(parents=True)
        if name == "engine-docs":
            shutil.copytree(ROOT / "engine/target/doc", output, dirs_exist_ok=True)
        for source in (ROOT / "deploy" / name).rglob("index.html"):
            relative = source.relative_to(ROOT / "deploy" / name)
            # Homepage uses extensionless files; engine uses directory indexes.
            target = output / (
                relative if name == "engine-docs" or relative.parent == Path(".")
                else relative.parent
            )
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
        assets = output / "assets"
        (assets / "main_menu").mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / "assets/main_menu/background2.jpg", assets / "main_menu")
        shutil.copytree(ROOT / "assets/fonts", assets / "fonts", dirs_exist_ok=True)
        shutil.copy2(ROOT / "assets/homepage/favicon.png", output / "favicon.png")
        if name == "homepage":
            shutil.copy2(ROOT / "assets/homepage/apple-touch-icon.png", output)
            for image in ("logo.png", "aonw-mobile.png"):
                shutil.copy2(ROOT / "assets" / image, assets)
            shutil.copytree(ROOT / "assets/homepage/platform-icons", assets / "platform-icons")
        print(f"Staged {output}")


if __name__ == "__main__":
    build()
