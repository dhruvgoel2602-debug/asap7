# Regeneration scripts

The `.db` and `.ndm` binaries are not committed — they are derived,
tool-version-specific, and cheap to rebuild. These scripts rebuild them.
Run both from the **repository root**.

## `01_build_db.tcl` — Liberty → db

```bash
lc_shell -f scripts/01_build_db.tcl
```

Compiles every `lib/*.lib` to `db_out/<same-name>.db`. No extra inputs
needed. Prints a pass/fail tally and exits non-zero if anything failed.

## `02_build_ref_ndm.tcl` — LEF + tech file → physical reference NDM

```bash
export ASAP7_LEF_DIR=/path/to/OpenROAD-flow-scripts/flow/platforms/asap7/lef
icc2_lm_shell -f scripts/02_build_ref_ndm.tcl
```

Builds `ASAP7_ref.ndm` (RVT), `ASAP7_LVT_ref.ndm`, `ASAP7_SLVT_ref.ndm` from
`tech/asap07_icc_fixed.tf` plus the ASAP7 LEF.

**LEF is not redistributed in this repo** — get it from
<https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts> and point
`ASAP7_LEF_DIR` at `flow/platforms/asap7/lef`. Expected filenames:

- `asap7_tech_1x_201209.lef` (tech)
- `asap7sc7p5t_28_{R,L,SL}_1x_220121a.lef` (cells, per Vt)

If upstream has renamed these, edit the `FLAVOURS` table at the top of the
script.

## Cell-level NDMs (optional)

ICC2 can also build per-group cached cell libraries (`CLIBs/`) from a frame
library plus the `.db`. That is an optimization, not a requirement — the
reference NDM plus `link_library` is enough to run the flow. If you want
them, ICC2's `create_workspace` / `read_ndm` / `read_db` /
`process_workspaces` sequence generates them; see
`docs/ICC2_FLOW_NOTES.md`.
