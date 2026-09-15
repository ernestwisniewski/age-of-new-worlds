#!/usr/bin/env python3
"""Explicit, integrity-checked installation of reference-landscape visual assets.

Close Godot before running. No third-party Python packages are required.
Tree3D release archives are pinned by SHA-256. Poly Haven's first resolution uses
its published MD5; assets.lock.json records the URL and SHA-256 for later installs.
No downloads are performed by the Godot editor scripts. Existing managed Tree3D
installs are repaired in place; --trees-only skips unrelated ground scans.
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import tempfile
import urllib.request
from urllib.parse import urlparse
import zipfile

VERSION = "v1.1.0"
RELEASE = "https://github.com/JekSun97/gdTree3D/releases/download/" + VERSION + "/"
ARCHIVES = {
    "addon": ("Tree3D-addon-godot4.5.zip", "fb12f381ec19d1e9eb6339f8df85da474e9255ba0f86e5251df5d4599cc1b42d"),
    "demo": ("Tree3D-demo-project-godot4.5.zip", "85b6fdca3df7bc82e837097d80f08c4bfe5d4fdb1906a761637039f62b2c709e"),
}
TREE_DESCRIPTOR = "addons/Tree3D/Tree3D.gdextension"
# Exact upstream/fixed bytes for recovery after a descriptor write but before
# its manifest write. Never accept arbitrary local edits as an automatic repair.
UPSTREAM_DESCRIPTOR_SHA256 = "7a5b9daa5900af0cb9cc06156c033ec514262bf1279c9f33cb5193b2b341e2f0"
FIXED_DESCRIPTOR_SHA256 = "e3d4e2aadf3b84adc397d6da6c7f0a0679fb801407df8bb24d61ec34cb9951bc"
SCANS = {"grass": "leafy_grass", "forest": "forest_ground_04", "sand": "coast_sand_05",
         "snow": "snow_02", "rock": "rock_boulder_cracked", "mud": "brown_mud_03"}
CHANNELS = {"diffuse": "Diffuse", "normal": "nor_gl", "roughness": "Rough"}
TREE_TEXTURES = ("bark.jpg", "bark_normal.png", "Branches1.png", "Branches2.png", "Branches3.png")
MAX_BYTES = 80 * 1024 * 1024
ALLOWED_HOSTS = {"github.com", "release-assets.githubusercontent.com", "objects.githubusercontent.com",
                 "api.polyhaven.com", "dl.polyhaven.org", "cdn.polyhaven.com"}


def validate_url(url: str) -> None:
    parsed = urlparse(url)
    if parsed.scheme != "https" or parsed.hostname not in ALLOWED_HOSTS or parsed.username or parsed.password:
        raise ValueError(f"Unapproved asset URL: {url}")


class SafeRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        validate_url(newurl)
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def download(url: str) -> bytes:
    validate_url(url)
    request = urllib.request.Request(url, headers={"User-Agent": "AgeOfNewWorlds-reference-assets/1.0"})
    with urllib.request.build_opener(SafeRedirect).open(request, timeout=90) as response:
        validate_url(response.geturl())
        payload = response.read(MAX_BYTES + 1)
    if len(payload) > MAX_BYTES:
        raise ValueError("Asset exceeds download size limit")
    return payload


def verified(payload: bytes, expected: str, algorithm: str = "sha256") -> bytes:
    if not re.fullmatch(r"[0-9a-f]{%d}" % (64 if algorithm == "sha256" else 32), expected):
        raise ValueError("Malformed expected asset digest")
    if hashlib.new(algorithm, payload).hexdigest() != expected:
        raise ValueError("Asset checksum mismatch")
    return payload


def archive_files(payload: bytes) -> dict[str, bytes]:
    result = {}
    with zipfile.ZipFile(io.BytesIO(payload)) as archive:
        if sum(info.file_size for info in archive.infolist()) > MAX_BYTES * 4:
            raise ValueError("Expanded asset archive exceeds size limit")
        for info in archive.infolist():
            path = PurePosixPath(info.filename)
            if path.is_absolute() or ".." in path.parts or "\\" in info.filename or ":" in info.filename:
                raise ValueError("Unsafe archive path")
            if stat.S_ISLNK(info.external_attr >> 16):
                raise ValueError("Archive symlinks are not supported")
            if info.is_dir():
                continue
            if path.as_posix() in result:
                raise ValueError("Duplicate archive member")
            result[path.as_posix()] = archive.read(info)
    return result


def normalize_tree3d_descriptor(payload: bytes) -> bytes:
    """Godot ConfigFile comments start with ';', NOT GDScript's '#'.

    In the pinned upstream file, a '#' comment becomes part of the following
    macos.debug key, so the editor cannot find a library even though the
    universal Mach-O binary contains both arm64 and x86_64. Preserve CRLF and
    quoted '#' characters; change only whole-line comments in this descriptor.
    """
    return re.sub(rb"(?m)^([ \t]*)#", rb"\1;", payload)


def atomic_write(path: Path, payload: bytes) -> None:
    temporary: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as file:
            temporary = Path(file.name)
            file.write(payload)
        temporary.replace(path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def repair_managed_trees(project: Path, stamp: Path) -> None:
    record = json.loads(stamp.read_text())
    files = record.get("files", {})
    if record.get("version") != VERSION or not isinstance(files, dict) or TREE_DESCRIPTOR not in files:
        raise ValueError("Invalid or unsupported managed Tree3D manifest")
    descriptor = b""
    descriptor_digest = ""
    # Verify the whole installation BEFORE making any changes. In particular,
    # do not overwrite modified binaries, textures or custom library mappings.
    for name, digest in files.items():
        relative = PurePosixPath(name)
        if (relative.is_absolute() or ".." in relative.parts or "\\" in name or ":" in name
                or not name.startswith(("addons/Tree3D/", "assets/reference_materials/trees/"))):
            raise ValueError("Unsafe managed Tree3D path")
        path = project / name
        if not path.resolve().is_relative_to(project.resolve()) or not path.is_file():
            raise ValueError(f"Missing or unsafe managed Tree3D file: {name}")
        payload = path.read_bytes()
        actual = hashlib.sha256(payload).hexdigest()
        recovered = (name == TREE_DESCRIPTOR and digest == UPSTREAM_DESCRIPTOR_SHA256
                     and actual == FIXED_DESCRIPTOR_SHA256)
        if actual != digest and not recovered:
            raise ValueError(f"Managed Tree3D file was modified: {name}; preserve your edits before reinstalling")
        if name == TREE_DESCRIPTOR:
            descriptor = payload
            descriptor_digest = actual
    fixed = normalize_tree3d_descriptor(descriptor)
    fixed_digest = hashlib.sha256(fixed).hexdigest()
    if descriptor_digest != fixed_digest:
        atomic_write(project / TREE_DESCRIPTOR, fixed)
    if files[TREE_DESCRIPTOR] != fixed_digest:
        files[TREE_DESCRIPTOR] = fixed_digest
        atomic_write(stamp, (json.dumps(record, indent=2) + "\n").encode())


def install_trees(project: Path, fetch=download) -> None:
    target = project / "addons/Tree3D"
    stamp = target / ".aonw-install.json"
    if stamp.exists():
        repair_managed_trees(project, stamp)
        return
    if target.exists() and any(p.name not in {".gitignore", "README.md", "LICENSE.md"} for p in target.iterdir()):
        raise ValueError("Refusing to overwrite an unmanaged Tree3D installation")
    installed: dict[str, bytes] = {}
    for kind, (name, digest) in ARCHIVES.items():
        files = archive_files(verified(fetch(RELEASE + name), digest))
        if kind == "addon":
            for name, payload in files.items():
                parts = PurePosixPath(name).parts
                if "Tree3D" in parts:
                    relative = PurePosixPath(*parts[parts.index("Tree3D") + 1:])
                    if relative.name not in {"README.md", ".gitignore", "LICENSE.md"}:
                        installed[(Path("addons/Tree3D") / str(relative)).as_posix()] = payload
            if not any(name.endswith("Tree3D.gdextension") for name in installed):
                raise ValueError("Tree3D addon archive contains no extension descriptor")
        else:
            for texture in TREE_TEXTURES:
                matches = [data for name, data in files.items() if PurePosixPath(name).name == texture]
                if len(matches) != 1:
                    raise ValueError(f"Missing or ambiguous Tree3D demo texture: {texture}")
                installed["assets/reference_materials/trees/" + texture] = matches[0]
            licenses = [(name, data) for name, data in files.items() if PurePosixPath(name).name.lower() in {"license.md", "license.txt", "license"}]
            for index, (name, data) in enumerate(licenses):
                installed[f"assets/reference_materials/trees/UPSTREAM-LICENSE-{index}.txt"] = data
    if TREE_DESCRIPTOR not in installed:
        raise ValueError("Tree3D addon archive contains no root extension descriptor")
    installed[TREE_DESCRIPTOR] = normalize_tree3d_descriptor(installed[TREE_DESCRIPTOR])
    for name, payload in installed.items():
        destination = project / name
        if destination.exists() and destination.read_bytes() != payload:
            raise ValueError(f"Refusing to overwrite an existing asset: {destination}")
    for name, payload in installed.items():
        destination = project / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(payload)
    stamp.write_text(json.dumps({"version": VERSION, "files": {
        name: hashlib.sha256(data).hexdigest() for name, data in installed.items()}}, indent=2) + "\n")


def install_scans(project: Path, fetch=download) -> None:
    target = project / "assets/reference_materials"
    target.mkdir(parents=True, exist_ok=True)
    lock_path = target / "assets.lock.json"
    lock = json.loads(lock_path.read_text()) if lock_path.exists() else {"schema": 1, "files": {}}
    expected_names = {f"{layer}_{channel}.jpg" for layer in SCANS for channel in CHANNELS}
    if lock.get("schema") != 1 or not set(lock.get("files", {})).issubset(expected_names):
        raise ValueError("Invalid landscape asset lock file")
    with tempfile.TemporaryDirectory(prefix="aonw-scans-") as directory:
        staging = Path(directory)
        for layer, asset in SCANS.items():
            metadata = None
            for channel, map_name in CHANNELS.items():
                name = f"{layer}_{channel}.jpg"
                existing = target / name
                record = lock["files"].get(name)
                if record and existing.is_file():
                    verified(existing.read_bytes(), record["sha256"])
                    continue
                if record:
                    payload = verified(fetch(record["url"]), record["sha256"])
                else:
                    if metadata is None:
                        metadata = json.loads(fetch("https://api.polyhaven.com/files/" + asset))
                    entry = metadata.get(map_name, {}).get("1k", {}).get("jpg")
                    if not entry:
                        raise ValueError(f"No 1k JPG {map_name} scan for {asset}")
                    payload = verified(fetch(entry["url"]), entry["md5"], "md5")
                    if len(payload) != entry["size"]:
                        raise ValueError("Scan size differs from published metadata")
                    record = {"asset": asset, "source": "https://polyhaven.com/a/" + asset,
                              "license": "CC0-1.0", "url": entry["url"],
                              "sha256": hashlib.sha256(payload).hexdigest()}
                if existing.exists() and existing.read_bytes() != payload:
                    raise ValueError(f"Refusing to overwrite an existing scan: {existing}")
                (staging / name).write_bytes(payload)
                lock["files"][name] = record
        for path in staging.iterdir():
            shutil.copyfile(path, target / path.name)
        temporary_lock = target / "assets.lock.json.tmp"
        temporary_lock.write_text(json.dumps(lock, indent=2, sort_keys=True) + "\n")
        temporary_lock.replace(lock_path)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--trees-only", action="store_true", help="Install/repair Tree3D without downloading ground scans")
    parser.add_argument("--project", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    project = args.project.resolve()
    if not (project / "project.godot").is_file():
        parser.error("--project must point to clients/aonw_godot")
    install_trees(project)
    if args.trees_only:
        print("Tree3D v1.1.0 installed/verified with a valid macOS descriptor. Restart Godot.")
        return
    install_scans(project)
    print("Installed Tree3D v1.1.0 and six 1k PBR surface sets. Restart Godot before opening a reference map.")


if __name__ == "__main__":
    main()
