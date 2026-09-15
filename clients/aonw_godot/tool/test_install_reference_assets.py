"""Offline installer contracts. Run: python3 -m unittest discover -s .../tool -p test_install_reference_assets.py"""
import hashlib
import io
import json
from pathlib import Path
import tempfile
import unittest
import zipfile
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

if __name__ == "__main__":
    unittest.main()
