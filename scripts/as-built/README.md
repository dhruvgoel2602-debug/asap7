# As-built workspace configs (historical record)

These 16 `.tcl` files are what **ICC2 itself generated** while building the
cached cell libraries (`CLIBs/`) on the original machine — captured verbatim
from `CLIBs/.scripts/`.

They are kept as a record of exactly how the libraries that were in use got
built, including `-scale_factor 4000` and the `lib.workspace.*` app options
actually in force.

**They are not runnable as-is.** They contain absolute paths from the build
machine and reference a temp-file tech file that no longer exists:

```tcl
set FRAME_LIBS {/home/vlsilab/SynopsysFlow/v3_rebuild/ASAP7_ref_v3.ndm}
set DB_FILES   {/home/vlsilab/SynopsysFlow/db_out/asap7sc7p5t_INVBUF_RVT_TT_nldm_220122.db}
set TECH_FILE  "/tmp/.tARL1477868/_tech9xvusB"        # gone
```

To rebuild, use `../01_build_db.tcl` and `../02_build_ref_ndm.tcl` instead,
which are parameterized and path-independent.

Note the pattern they show: a cell library is a workspace seeded with the
physical reference NDM (`read_ndm`) plus the timing `.db` (`read_db`), then
`process_workspaces`. Also visible here is the filename/internal-name
mismatch — the file is `..._220122.db`, the workspace is named `..._211120`.

Built with ICC2 `X-2025.06-SP1`; see `../../docs/TOOL_VERSIONS.md`.
