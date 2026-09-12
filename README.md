# ASAP7 — Synopsys-compatible collateral

ASAP7 7nm predictive PDK collateral, patched to work with the **Synopsys**
flow (Library Compiler, IC Compiler II / Fusion Compiler, StarRC, PrimeTime).

Stock ASAP7 ships for the Cadence/OpenROAD flow. The Synopsys technology file
that circulates for it (`asap7_snps`) is Milkyway-era and **does not build a
usable ICC2 reference library as-is** — `read_lef -include cell` errors on
unknown layers and `initialize_floorplan` dies with DPI-097. The fixed tech
file in `tech/` is the working one; the three fixes are described below.

## What's here

| Path | Contents | Origin |
|---|---|---|
| `tech/asap07_icc_fixed.tf` | **Working ICC2 tech file** — use this one | patched here |
| `tech/asap07_icc_upstream.tf` | Unpatched baseline, for diffing | `asap7_snps` |
| `tech/asap07_icc.fixes.diff` | The three fixes as a readable diff | — |
| `lib/*.lib` | 106 NLDM Liberty files, all corners × Vt × cell groups | ASAP7 (ASU) |
| `snps/icc/` | GDS in/out layer maps, layer table | `asap7_snps` |
| `snps/starrc/` | `tlu_plus` parasitic tech + `asap07.layermap` + ITF sources | `asap7_snps` |
| `docs/ICC2_FLOW_NOTES.md` | Build recipes, verified commands, known gotchas | written here |
| `docs/TOOL_VERSIONS.md` | Exact tool versions this was built/verified against | written here |
| `scripts/` | Regeneration scripts for `.db` and `.ndm` | written here |
| `scripts/as-built/` | The workspace configs ICC2 emitted during the original build | captured |

### What is deliberately *not* here

- **`.db` files** — compiled from `lib/*.lib` by `lc_shell`. Regenerate with
  `scripts/01_build_db.tcl` (~minutes for all 88).
- **`.ndm` reference libraries** — built from LEF + the fixed `.tf` by
  `icc2_lm_shell`. Regenerate with `scripts/02_build_ref_ndm.tcl`.
- **LEF and GDS** — *not redistributed here.* They come from the ASAP7
  platform in OpenROAD-flow-scripts and are needed to rebuild the `.ndm`:

  ```
  git clone https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts
  # LEF: flow/platforms/asap7/lef/asap7_tech_1x_201209.lef  (tech LEF)
  #      flow/platforms/asap7/lef/asap7sc7p5t_28_{R,L,SL}_1x_220121a.lef  (cells)
  ```

  Both `.db` and `.ndm` are derived, tool-version-specific binaries — they
  are cheap to rebuild and would bloat this repo, so only the *sources* and
  the *recipes* are archived. `.ndm` in particular does not survive an ICC2
  major-version change, so rebuilding on the target install is the correct
  move anyway. See `docs/TOOL_VERSIONS.md`.

## The three tech-file fixes

Against `tech/asap07_icc_upstream.tf` (see `tech/asap07_icc.fixes.diff`):

1. **Missing multi-Vt marker layers.** The old `.tf` predates ASAP7's
   `RVTN/RVTP/LVTN/LVTP/SLVTN/SLVTP` layers. Added as `Layer` blocks
   (layerNumber 40–45), so `read_lef -include cell` no longer errors on
   unknown layers.

2. **Wrong site / row height.** The old `Tile "unit"` was 0.216 × 1.080 —
   4× too large versus the real `SITE asap7sc7p5t` (0.054 × 0.270) in the
   LEF. Added a matching `Tile "asap7sc7p5t"` block, selected at build time
   with:
   ```tcl
   set_attribute [get_site_defs asap7sc7p5t] is_default true
   set_attribute [get_site_defs asap7sc7p5t] symmetry Y
   ```

3. **Wrong `gridResolution`.** Was `16` → litho grid pitch 16/4000 = 0.004,
   which does not divide the 0.054 site width, so `initialize_floorplan`
   fails with **DPI-097**. Set to `4` (0.001 grid = the real ASAP7
   manufacturing grid).

Fix 3 invalidates every physical reference library built before it — rebuild
all `.ndm` after changing it.

## Quick start

```bash
git clone <this repo> asap7 && cd asap7

# 1. Liberty -> db
lc_shell -f scripts/01_build_db.tcl                 # writes db_out/

# 2. LEF + fixed .tf -> physical reference NDM   (needs LEF, see above)
icc2_lm_shell -f scripts/02_build_ref_ndm.tcl       # writes ASAP7_{,LVT_,SLVT_}ref.ndm
```

Then in ICC2:

```tcl
set_ref_libs -ref_libs ASAP7_ref.ndm
set link_library "* db_out/asap7sc7p5t_SEQ_RVT_TT_nldm_220123.db ..."
read_parasitic_tech -tlup snps/starrc/tlu_plus \
                    -layermap snps/starrc/asap07.layermap -name asap7_default
```

The `.db` set was built with Library Compiler `Y-2026.03` and the `.ndm`
libraries with ICC2 `X-2025.06-SP1`, on Rocky Linux 8.10 — though that ICC2
is no longer installed there, which is part of why the binaries are not
committed. See `docs/TOOL_VERSIONS.md`.

Read `docs/ICC2_FLOW_NOTES.md` before running a real block — it documents
several non-obvious failures, including the `set_ref_libs` corner-scoping
trap that silently black-boxes placed cells.

## Licensing

- `lib/` — ASAP7, **BSD 3-Clause**, © 2020 Lawrence T. Clark, Vinay
  Vashishtha, Arizona State University. See `LICENSE`. The notice is also
  embedded in every `.lib` header; keep it there.
- `snps/` — from [`snishizawa/asap7_snps`](https://github.com/snishizawa/asap7_snps),
  released into the **public domain** (Unlicense). See `snps/LICENSE`.
- `tech/asap07_icc_fixed.tf` — a patch on the above; same terms.

See `NOTICE.md` for per-file provenance.
