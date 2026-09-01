#!/usr/bin/env python3
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCAD = ROOT / "efhw_box.scad"
README = ROOT / "README.md"

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
        self.assertRegex(text, r"inner_z\s*=\s*38")
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
        self.assertRegex(text, r"boss_d\s*=\s*12")
        self.assertRegex(text, r"boss_pilot_d\s*=\s*3\.2")
        self.assertRegex(text, r"lid_t\s*=\s*3\.6")
        self.assertRegex(text, r"lid_screw_d\s*=\s*4\.0")
        self.assertRegex(text, r"lid_csink_d\s*=\s*9\.0")
        self.assertRegex(text, r"lid_csink_h\s*=\s*2\.3")

    def test_body_outline_is_not_empty(self):
        text = SCAD.read_text(encoding="utf-8")
        start = text.index("module body_outline")
        chunk = text[start : start + 800]
        self.assertIn("polygon", chunk)
        self.assertIn("offset", chunk)

    def test_tab_and_drain_geometry_keywords(self):
        text = SCAD.read_text(encoding="utf-8")
        tab = text[text.index("module mounting_tab") : text.index("module drain_holes")]
        drain = text[text.index("module drain_holes") : text.index("module so239_cutout")]
        self.assertIn("hull", tab)
        self.assertIn("tab_center_hole_d", tab)
        self.assertIn("wall_y()", tab)
        self.assertRegex(text, r"tab_t\s*=\s*8")
        self.assertIn("drain_d", drain)
        self.assertIn("drain_y_off", drain)
        self.assertIn("inner_x", drain)
        self.assertIn("rotate", drain)

    def test_so239_and_m4_keywords(self):
        text = SCAD.read_text(encoding="utf-8")
        so = text[text.index("module so239_cutout") : text.index("module m4_cutout")]
        m4 = text[text.index("module m4_cutout") : text.index("module lid_label")]
        self.assertIn("so_flange", so)
        self.assertIn("so_hole_spacing", so)
        self.assertIn("so_barrel_d", so)
        self.assertIn("so_screw_d", so)
        self.assertIn("so_pad_t", so)
        self.assertIn("m4_head_af", m4)
        self.assertIn("m4_from_tail_inner", m4)
        self.assertIn("$fn = 6", m4)
        self.assertIn("cylinder", so)
        self.assertNotIn("flange_out", so)
        self.assertNotIn("flange_out", m4)

    def test_lid_has_drip_cap_overhang_and_countersink(self):
        text = SCAD.read_text(encoding="utf-8")
        self.assertIn("module lid_shell", text)
        lid = text[text.index("module lid_shell") : text.index("module preview_assembly")]
        self.assertIn("skirt_t + skirt_gap", lid)
        self.assertNotIn("skirt_h", lid)
        self.assertIn("lid_csink_d", lid)
        self.assertIn("body_outline", lid)

    def test_preview_keeps_lid_inner_face_down(self):
        text = SCAD.read_text(encoding="utf-8")
        preview = text[text.index("module preview_assembly") : text.index('if (part == "base")')]
        self.assertIn("translate([0, 0, base_h() + 0.15])", preview)
        self.assertNotIn("rotate([180, 0, 0])", preview)

    def test_readme_describes_drip_cap_without_hanging_wall(self):
        text = README.read_text(encoding="utf-8")
        self.assertIn("внутренней стороной на стол", text)
        self.assertIn("надпись сверху", text)
        self.assertIn("силикона в жёлобе", text)
        self.assertIn("свес крышки", text)
        self.assertIn("Нависающей юбки по шву нет", text)

    def test_label_uses_ratio_and_power_line(self):
        text = SCAD.read_text(encoding="utf-8")
        lab = text[
            text.index("module lid_label") : text.index("module lid_screw_holes")
        ]
        self.assertIn("250W SSB PEP", lab)
        self.assertIn('str("1:", ratio)', lab)
        self.assertIn("text", lab)

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

    def test_openscad_stl_base_and_lid(self):
        with tempfile.TemporaryDirectory() as td:
            for p, name in [("base", "base.stl"), ("lid", "lid.stl")]:
                out = Path(td) / name
                r = self._openscad(
                    ["-o", str(out), "-D", f'part="{p}"', str(SCAD)]
                )
                self.assertEqual(r.returncode, 0, r.stderr)
                self.assertGreater(out.stat().st_size, 10_000, name)


if __name__ == "__main__":
    unittest.main()
