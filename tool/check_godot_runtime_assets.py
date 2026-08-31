#!/usr/bin/env python3
"""Validate the self-contained Godot map and terrain runtime package."""

from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path


MAP_HASHES = {
    "aonw2_starter": "4d5603cc00fa8963a71c23133570f89f43c734598d86579e12e1b1059da8712d",
    "dravonia": "64d8d98659a05cf6ba19fe7e0ae0d5e83b70f8b9da753cde9bf1459199519c82",
    "myranth": "1743616d03d54d04f53fc699c2a6ec2e1ba30f59665ddaa8776419fe06626571",
    "terenos": "c580c081e39a677e0d6f5e51f1654fe12b0274bfe9672c03994b9c61d1c88fec",
    "verdantia": "8765fc5eb23e7d715a97a743a533c6381988b7afbad57f208868223c6d46fbb5",
}
MAP_MANIFEST = "map_texture_manifest.json"
TERRAIN_MANIFEST = "terrain_compile.json"


class ContractError(RuntimeError):
    pass


def load_json(path: Path) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ContractError(f"cannot read JSON {path}: {error}") from error
    if not isinstance(value, dict):
        raise ContractError(f"JSON root must be an object: {path}")
    return value


def digest(path: Path) -> str:
    checksum = hashlib.sha256()
    try:
        with path.open("rb") as source:
            for chunk in iter(lambda: source.read(1024 * 1024), b""):
                checksum.update(chunk)
    except OSError as error:
        raise ContractError(f"cannot read asset {path}: {error}") from error
    return checksum.hexdigest()


def bundle_files(root: Path) -> set[str]:
    return {
        str(path.relative_to(root))
        for path in root.rglob("*")
        if path.is_file()
        and not path.name.startswith(".")
        and path.suffix != ".import"
    }


def check_map_bundle(workspace: Path, map_id: str) -> dict:
    content_map = workspace / "content" / "maps" / map_id / "map.json"
    godot_root = workspace / "clients" / "aonw_godot" / "assets" / "maps" / map_id
    flutter_root = workspace / "clients" / "aonw_flutter" / "assets" / "maps" / map_id
    map_document = load_json(content_map)
    if godot_root.joinpath("map.json").read_bytes() != content_map.read_bytes():
        raise ContractError(f"Godot map document differs from canonical content: {map_id}")
    if bundle_files(godot_root) != bundle_files(flutter_root):
        raise ContractError(f"Flutter and Godot map bundle files differ: {map_id}")
    for relative in bundle_files(godot_root):
        if digest(godot_root / relative) != digest(flutter_root / relative):
            raise ContractError(f"Flutter and Godot map bytes differ: {map_id}/{relative}")

    manifest = load_json(godot_root / MAP_MANIFEST)
    expected_identity = (
        map_id,
        MAP_HASHES[map_id],
        map_document.get("cols"),
        map_document.get("rows"),
    )
    actual_identity = (
        manifest.get("mapId"),
        manifest.get("mapContentHash"),
        manifest.get("cols"),
        manifest.get("rows"),
    )
    if actual_identity != expected_identity:
        raise ContractError(f"map bundle identity differs: {map_id}")
    pages = manifest.get("pages")
    if not isinstance(pages, list) or not pages:
        raise ContractError(f"map bundle has no pages: {map_id}")
    expected_files = {"map.json", MAP_MANIFEST}
    for page in pages:
        if not isinstance(page, dict):
            raise ContractError(f"map bundle page is invalid: {map_id}")
        name = page.get("file")
        if not isinstance(name, str) or Path(name).name != name:
            raise ContractError(f"map bundle page path is unsafe: {map_id}")
        if page.get("asset") != f"assets/runtime/maps/{map_id}/{name}":
            raise ContractError(f"map bundle logical asset path differs: {map_id}/{name}")
        if digest(godot_root / name) != page.get("sha256"):
            raise ContractError(f"map bundle page digest differs: {map_id}/{name}")
        expected_files.add(name)
    if bundle_files(godot_root) != expected_files:
        raise ContractError(f"map bundle contains stale files: {map_id}")
    return map_document


def check_terrain_bundle(workspace: Path, map_id: str, map_document: dict) -> None:
    root = (
        workspace
        / "clients"
        / "aonw_godot"
        / "assets"
        / "terrain_compiled"
        / map_id
    )
    manifest = load_json(root / TERRAIN_MANIFEST)
    expected_identity = (
        map_id,
        MAP_HASHES[map_id],
        map_document.get("cols"),
        map_document.get("rows"),
    )
    authoring = manifest.get("authoring")
    if not isinstance(authoring, dict):
        raise ContractError(f"terrain authoring metadata is invalid: {map_id}")
    actual_identity = (
        manifest.get("mapId"),
        manifest.get("mapContentHash"),
        authoring.get("cols"),
        authoring.get("rows"),
    )
    if actual_identity != expected_identity:
        raise ContractError(f"terrain bundle identity differs: {map_id}")
    layers = manifest.get("layers")
    if not isinstance(layers, dict) or set(layers) != {"base", "min", "max"}:
        raise ContractError(f"terrain layers differ: {map_id}")
    expected_files = {TERRAIN_MANIFEST}
    for layer_name, layer in layers.items():
        if not isinstance(layer, dict):
            raise ContractError(f"terrain layer is invalid: {map_id}/{layer_name}")
        name = layer.get("openExr")
        if not isinstance(name, str) or Path(name).name != name or not name.endswith(".exr"):
            raise ContractError(f"terrain layer path is unsafe: {map_id}/{layer_name}")
        if digest(root / name) != layer.get("openExrSha256"):
            raise ContractError(f"terrain layer digest differs: {map_id}/{layer_name}")
        expected_files.add(name)
    if bundle_files(root) != expected_files:
        raise ContractError(f"terrain bundle contains stale files: {map_id}")


def check_scenario(workspace: Path, map_id: str, map_document: dict) -> None:
    path = workspace / "clients" / "aonw_godot" / "assets" / "scenarios" / f"{map_id}.json"
    scenario = load_json(path)
    if scenario.get("scenarioId") != map_id or scenario.get("mapId") != map_id:
        raise ContractError(f"Godot preview scenario identity differs: {map_id}")
    units = scenario.get("initialUnits")
    if not isinstance(units, list) or not units:
        raise ContractError(f"Godot preview scenario has no units: {map_id}")
    for unit in units:
        if not isinstance(unit, dict):
            raise ContractError(f"Godot preview scenario unit is invalid: {map_id}")
        col, row = unit.get("col"), unit.get("row")
        if not isinstance(col, int) or not 0 <= col < map_document["cols"]:
            raise ContractError(f"Godot preview scenario column is invalid: {map_id}")
        if not isinstance(row, int) or not 0 <= row < map_document["rows"]:
            raise ContractError(f"Godot preview scenario row is invalid: {map_id}")


def main() -> int:
    workspace = Path(__file__).resolve().parent.parent
    try:
        for map_id in MAP_HASHES:
            map_document = check_map_bundle(workspace, map_id)
            check_terrain_bundle(workspace, map_id, map_document)
            check_scenario(workspace, map_id, map_document)
    except (ContractError, OSError) as error:
        print(f"Godot runtime asset contract failed: {error}", file=sys.stderr)
        return 1
    print("Godot runtime assets: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
