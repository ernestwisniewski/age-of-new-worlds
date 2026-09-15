"""Offline installer contracts. Run: python3 -m unittest discover -s .../tool -p test_install_reference_assets.py"""
import hashlib
import io
import json
from pathlib import Path
import tempfile
import unittest
import zipfile
from unittest.mock import patch
import install_reference_assets as assets

class InstallerTests(unittest.TestCase):
    def test_verified_bytes(self):
        self.assertEqual(assets.verified(b"scan", hashlib.sha256(b"scan").hexdigest()), b"scan")
        with self.assertRaises(ValueError):
            assets.verified(b"tampered", hashlib.sha256(b"scan").hexdigest())

    def test_archive_rejects_traversal_and_symlinks(self):
        for name in ("../outside", "/outside", "addons\\outside", "C:/outside"):
            buffer = io.BytesIO()
            with zipfile.ZipFile(buffer, "w") as archive:
                archive.writestr(name, b"no")
            with self.assertRaises(ValueError):
                assets.archive_files(buffer.getvalue())
        buffer = io.BytesIO()
        with zipfile.ZipFile(buffer, "w") as archive:
            info = zipfile.ZipInfo("link")
            info.external_attr = 0o120777 << 16
            archive.writestr(info, "target")
        with self.assertRaises(ValueError):
            assets.archive_files(buffer.getvalue())

    def test_unapproved_urls(self):
        for url in ("http://api.polyhaven.com", "https://evil.example/scan", "https://u:p@github.com/file"):
            with self.assertRaises(ValueError):
                assets.validate_url(url)

    def test_scan_lock_reinstall_and_tamper_detection(self):
        payload = b"fake image used only by the offline installer test"
        entry = {"url": "https://dl.polyhaven.org/scan.jpg", "md5": hashlib.md5(payload).hexdigest(), "size": len(payload)}
        metadata = {channel: {"1k": {"jpg": entry}} for channel in assets.CHANNELS.values()}
        calls = []
        def fetch(url):
            calls.append(url)
            return json.dumps(metadata).encode() if "api.polyhaven" in url else payload
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            assets.install_scans(project, fetch)
            target = project / "assets/reference_materials"
            self.assertEqual(len(json.loads((target / "assets.lock.json").read_text())["files"]), 18)
            calls.clear()
            assets.install_scans(project, fetch)
            self.assertEqual(calls, [])
            (target / "grass_diffuse.jpg").write_bytes(b"user edit")
            with self.assertRaises(ValueError):
                assets.install_scans(project, fetch)
            self.assertEqual((target / "grass_diffuse.jpg").read_bytes(), b"user edit")

    def test_unmanaged_addon_is_not_overwritten(self):
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            addon = project / "addons/Tree3D"
            addon.mkdir(parents=True)
            (addon / "custom.gd").write_text("user code")
            with self.assertRaises(ValueError):
                assets.install_trees(project, lambda url: self.fail("Must not download"))


class TreeDescriptorTests(unittest.TestCase):
    RAW = (Path(__file__).resolve().parents[1] / "tests/fixtures/tree3d/upstream-v1.1.0.gdextension.txt").read_bytes()
    BINARY = "addons/Tree3D/libTree3D.macos.template_debug.universal"

    def managed_install(self, project):
        files = {assets.TREE_DESCRIPTOR: self.RAW, self.BINARY: b"binary fixture",
                 "assets/reference_materials/trees/bark.jpg": b"texture fixture"}
        for name, payload in files.items():
            path = project / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(payload)
        stamp = project / "addons/Tree3D/.aonw-install.json"
        stamp.write_text(json.dumps({"version": assets.VERSION, "files": {
            name: hashlib.sha256(payload).hexdigest() for name, payload in files.items()}}))
        return stamp

    def offline(self, url):
        self.fail("Managed repair must not download: " + url)

    def test_normalization_is_narrow_and_idempotent(self):
        raw = b'# comment\r\n  # second\r\nurl="https://example.test/#fragment"\r\n; valid\r\n'
        expected = raw.replace(b'# comment', b'; comment').replace(b'# second', b'; second')
        self.assertEqual(assets.normalize_tree3d_descriptor(raw), expected)
        self.assertEqual(assets.normalize_tree3d_descriptor(expected), expected)
        self.assertEqual(hashlib.sha256(self.RAW).hexdigest(), assets.UPSTREAM_DESCRIPTOR_SHA256)
        self.assertEqual(hashlib.sha256(assets.normalize_tree3d_descriptor(self.RAW)).hexdigest(), assets.FIXED_DESCRIPTOR_SHA256)

    def test_existing_install_is_repaired_offline_and_stays_idempotent(self):
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            stamp = self.managed_install(project)
            assets.install_trees(project, self.offline)
            fixed = assets.normalize_tree3d_descriptor(self.RAW)
            self.assertEqual((project / assets.TREE_DESCRIPTOR).read_bytes(), fixed)
            self.assertEqual(json.loads(stamp.read_text())["files"][assets.TREE_DESCRIPTOR], hashlib.sha256(fixed).hexdigest())
            self.assertEqual((project / self.BINARY).read_bytes(), b"binary fixture")
            before = {p: (p.read_bytes(), p.stat().st_mtime_ns) for p in project.rglob('*') if p.is_file()}
            assets.install_trees(project, self.offline)
            self.assertEqual(before, {p: (p.read_bytes(), p.stat().st_mtime_ns) for p in before})

    def test_modified_or_missing_managed_files_are_not_overwritten(self):
        for name in (assets.TREE_DESCRIPTOR, self.BINARY):
            for missing in (False, True):
                with self.subTest(name=name, missing=missing), tempfile.TemporaryDirectory() as directory:
                    project = Path(directory)
                    self.managed_install(project)
                    path = project / name
                    path.unlink() if missing else path.write_bytes(b"user edit")
                    before = {p: p.read_bytes() for p in project.rglob('*') if p.is_file()}
                    with self.assertRaises(ValueError):
                        assets.install_trees(project, self.offline)
                    self.assertEqual(before, {p: p.read_bytes() for p in project.rglob('*') if p.is_file()})

    def test_interrupted_manifest_write_is_recoverable(self):
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            stamp = self.managed_install(project)
            original_write = assets.atomic_write
            def fail_stamp(path, payload):
                if path == stamp:
                    raise OSError("simulated interrupted manifest write")
                original_write(path, payload)
            with patch.object(assets, "atomic_write", side_effect=fail_stamp), self.assertRaises(OSError):
                assets.install_trees(project, self.offline)
            # Descriptor has new bytes, manifest still has the original digest.
            assets.install_trees(project, self.offline)
            self.assertEqual(json.loads(stamp.read_text())["files"][assets.TREE_DESCRIPTOR], assets.FIXED_DESCRIPTOR_SHA256)

    def test_fresh_install_normalizes_only_the_descriptor_after_hash_verification(self):
        def zipped(files):
            buffer = io.BytesIO()
            with zipfile.ZipFile(buffer, "w") as archive:
                for name, payload in files.items():
                    archive.writestr(name, payload)
            return buffer.getvalue()
        addon = zipped({assets.TREE_DESCRIPTOR: self.RAW, self.BINARY: b"native binary",
                        "addons/Tree3D/example.gd": b"# valid GDScript comment"})
        demo = zipped({"demo/" + name: b"texture" for name in assets.TREE_TEXTURES})
        archives = {"addon": ("addon.zip", hashlib.sha256(addon).hexdigest()),
                    "demo": ("demo.zip", hashlib.sha256(demo).hexdigest())}
        with tempfile.TemporaryDirectory() as directory, patch.dict(assets.ARCHIVES, archives, clear=True):
            project = Path(directory)
            assets.install_trees(project, lambda url: addon if url.endswith("/addon.zip") else demo)
            self.assertEqual((project / assets.TREE_DESCRIPTOR).read_bytes(), assets.normalize_tree3d_descriptor(self.RAW))
            self.assertEqual((project / "addons/Tree3D/example.gd").read_bytes(), b"# valid GDScript comment")
            assets.install_trees(project, self.offline)

    def test_trees_only_never_installs_ground_scans(self):
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            (project / "project.godot").touch()
            self.managed_install(project)
            with patch("sys.argv", ["installer", "--project", str(project), "--trees-only"]), patch.object(assets, "install_scans") as scans:
                assets.main()
                scans.assert_not_called()


if __name__ == "__main__":
    unittest.main()
