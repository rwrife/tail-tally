import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from tools.release import read_pubspec_version, validate, write_provenance


class VersionValidationTest(unittest.TestCase):
    def write_pubspec(self, directory: str, version: str) -> Path:
        path = Path(directory) / "pubspec.yaml"
        path.write_text(f"name: tail_tally\nversion: {version}\n", encoding="utf-8")
        return path

    def test_candidate_tag_matches_release_part_of_pubspec_version(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            pubspec = self.write_pubspec(directory, "0.1.0-rc.1+2")
            self.assertEqual(validate(pubspec, "v0.1.0-rc.1", None), "0.1.0-rc.1+2")

    def test_tag_mismatch_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            pubspec = self.write_pubspec(directory, "0.1.0-rc.1+2")
            with self.assertRaisesRegex(ValueError, "does not match"):
                validate(pubspec, "v0.1.0", None)

    def test_manual_expected_version_mismatch_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            pubspec = self.write_pubspec(directory, "0.1.0-rc.1+2")
            with self.assertRaisesRegex(ValueError, "requested version"):
                validate(pubspec, None, "0.1.0-rc.2+2")

    def test_invalid_or_duplicate_version_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            pubspec = self.write_pubspec(directory, "0.1+0")
            with self.assertRaisesRegex(ValueError, "SemVer"):
                read_pubspec_version(pubspec)
            pubspec.write_text("version: 0.1.0+1\nversion: 0.1.1+2\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "exactly one"):
                read_pubspec_version(pubspec)

    def test_numeric_prerelease_identifier_with_leading_zero_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            for version in ("0.1.0-01+2", "0.1.0-rc.01+2", "0.1.0-0.00+2"):
                with self.subTest(version=version):
                    pubspec = self.write_pubspec(directory, version)
                    with self.assertRaisesRegex(ValueError, "SemVer"):
                        read_pubspec_version(pubspec)

    def test_valid_semver_prerelease_identifiers_are_accepted(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            for version in ("0.1.0-0+2", "0.1.0-rc.1+2", "0.1.0-alpha-01+2"):
                with self.subTest(version=version):
                    pubspec = self.write_pubspec(directory, version)
                    self.assertEqual(read_pubspec_version(pubspec), version)


class ProvenanceTest(unittest.TestCase):
    def test_writes_sorted_checksums_and_reproduction_scope(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            second = root / "z-ios.tar.gz"
            first = root / "a-android.apk"
            second.write_bytes(b"ios")
            first.write_bytes(b"android")
            write_provenance(
                root,
                "0.1.0-rc.1+2",
                "a" * 40,
                "refs/tags/v0.1.0-rc.1",
                "https://github.com/rwrife/tail-tally/actions/runs/1",
                [second, first],
            )

            data = json.loads((root / "PROVENANCE.json").read_text(encoding="utf-8"))
            self.assertEqual([item["name"] for item in data["subjects"]], [first.name, second.name])
            self.assertIn("byte-identical output is not claimed", data["reproduction"]["claim"])
            sums = (root / "SHA256SUMS").read_text(encoding="utf-8")
            self.assertIn(hashlib.sha256(first.read_bytes()).hexdigest(), sums)
            self.assertIn("PROVENANCE.json", sums)


if __name__ == "__main__":
    unittest.main()
