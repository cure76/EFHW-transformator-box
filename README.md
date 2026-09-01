# EFHW transformer box (FT 240-43)

OpenSCAD enclosure for a 1:49 or 1:64 EFHW unun on one FT 240-43. Print in PETG.

## Open the model

- `part = "preview"` — assembled view
- `part = "base"` — export the box
- `part = "lid"` — export the lid (inner face on the bed, label on top)
- `ratio = 64` (default) or `49` — lid text `1:64` / `1:49` plus `250W SSB PEP`

File: `efhw_box.scad`. No libraries.

## Print (PETG)

- Layer 0.2 mm, at least 3 perimeters (walls are 2.8 mm).
- Base: cavity up. Trough, bosses, and tab need no supports.
- Lid: inner face on the bed, label on top. Label recesses form in the last layers.
- Do not drill holes after printing.

The weather seal is the silicone trough plus the lid plate overhang, which acts
as a drip cap. There is no hanging wall over the seam.

## Fit

Cavity 85 × 108 × 28 mm is sized for ПЭТВ-2 1.25 mm on FT 240-43, with room for 1.5 mm. A Ø79 × 22 mm wound-core envelope must clear the corner bosses.

## Assembly

1. Fit SO-239, four M3 through the flange (clearance holes in PETG).
2. Fit M4 from inside; washer and nut outside after soldering the radiator.
3. Seat the toroid; optional silicone in the centre hole. No clips.
4. Solder: centre pin, flange ground, M4 tap.
5. Neutral-cure silicone bead in the rim trough.
6. Lid, four ~M3×10–12 mm self-tappers into the bosses (pilot 2.5 mm).
7. Leave the two drain holes at the SO-239 end open.

Hang from the tab; SO-239 points down.

## Tests

`python3 tests/test_efhw_box.py`

OpenSCAD CLI is optional; without it, render checks are skipped.
