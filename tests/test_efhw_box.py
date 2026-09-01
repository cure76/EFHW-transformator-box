#!/usr/bin/env python3
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCAD = ROOT / "efhw_box.scad"

REQUIRED_PARAMS = [
    "part",
    "ratio",
    "inner_x",
    "inner_y",
    "inner_z",
    "wall",
    "floor_t",
    "lid_t",
    "rim_w",
    "trough_w",
    "trough_d",
    "corner_r",
    "chamfer",
    "fit_clearance",
    "boss_d",
    "boss_pilot_d",
    "tab_len",
    "drain_d",
    "so_flange",
    "so_hole_spacing",
    "so_barrel_d",
    "m4_d",
    "label_depth",
]

REQUIRED_MODULES = [
    "base",
    "lid",
    "preview_assembly",
    "body_outline",
    "cavity",
    "screw_bosses",
    "sealant_trough",
    "mounting_tab",
    "drain_holes",
    "so239_cutout",
    "m4_cutout",
    "lid_label",
]


class TestEfhwBox(unittest.TestCase):
    def test_scad_exists(self):
        self.assertTrue(SCAD.is_file(), f"missing {SCAD}")

    def test_required_params_present(self):
        text = SCAD.read_text(encoding="utf-8")
        missing = [name for name in REQUIRED_PARAMS if name not in text]
        self.assertEqual(missing, [], f"missing params: {missing}")

    def test_default_ratio_is_64(self):
        text = SCAD.read_text(encoding="utf-8")
        self.assertRegex(text, r"ratio\s*=\s*64")

    def test_inner_cavity_matches_spec(self):
        text = SCAD.read_text(encoding="utf-8")
        self.assertRegex(text, r"inner_x\s*=\s*108")
        self.assertRegex(text, r"inner_y\s*=\s*85")
        self.assertRegex(text, r"inner_z\s*=\s*28")
        self.assertRegex(text, r"wall\s*=\s*2\.8")

    def test_required_modules_present(self):
        text = SCAD.read_text(encoding="utf-8")
        missing = [m for m in REQUIRED_MODULES if f"module {m}" not in text]
        self.assertEqual(missing, [], f"missing modules: {missing}")

    def test_part_dispatch_present(self):
        text = SCAD.read_text(encoding="utf-8")
        self.assertIn('part == "base"', text)
        self.assertIn('part == "lid"', text)
        self.assertIn('part == "preview"', text)

    def test_trough_and_boss_params(self):
        text = SCAD.read_text(encoding="utf-8")
        self.assertRegex(text, r"trough_w\s*=\s*4")
        self.assertRegex(text, r"trough_d\s*=\s*1")
        self.assertRegex(text, r"boss_pilot_d\s*=\s*2\.5")

    def test_body_outline_is_not_empty(self):
        text = SCAD.read_text(encoding="utf-8")
        start = text.index("module body_outline")
        chunk = text[start : start + 800]
        self.assertIn("polygon", chunk)
        self.assertIn("offset", chunk)

    def _openscad(self, args):
        exe = shutil.which("openscad")
        if not exe:
            self.skipTest("openscad not on PATH")
        return subprocess.run(
            [exe, *args],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )

    def test_openscad_csg_base(self):
        with tempfile.TemporaryDirectory() as td:
            out = Path(td) / "base.csg"
            r = self._openscad(
                ["-o", str(out), "-D", 'part="base"', str(SCAD)]
            )
            self.assertEqual(r.returncode, 0, r.stderr)
            self.assertGreater(out.stat().st_size, 100)


if __name__ == "__main__":
    unittest.main()
