# Tool versions this collateral was built and verified with

The tech file, the `.db` set and the `.ndm` reference libraries were produced
on the following installation. Liberty (`lib/`) and the `snps/` files are
plain text and version-independent; the **derived binaries are not**.

| Tool | Version | Binary |
|---|---|---|
| **Library Compiler** | `Y-2026.03` (Feb 25, 2026) | `/home/synopsys/lc/Y-2026.03/bin/lc_shell` |
| **IC Compiler II** | `X-2025.06-SP1-707-T-20251209` (Dec 9, 2025, base build 2025-07-07) | `/home/synopsys/syn/Y-2026.03/bin/icc2_shell` |
| **IC Compiler II LM** | same as ICC2 | `icc2_lm_shell` |
| **PrimeTime** | `Y-2026.03` | `/home/synopsys/prime/Y-2026.03/bin/pt_shell` |

Platform: Rocky Linux 8.10, x86-64 (kernel 4.18.0-553).

## What that means for restoring

- **`lib/*.lib`, `tech/*.tf`, `snps/*`** — text. Use with any tool version.
- **`.db`** — Liberty `.db` is broadly forward-compatible, but a `.db` written
  by LC `Y-2026.03` may be rejected by an *older* DC/ICC2. Rebuilding from
  `lib/` takes minutes, so just rebuild rather than debug a version mismatch:
  `lc_shell -f scripts/01_build_db.tcl`.
- **`.ndm`** — ICC2 reference libraries are tied much more tightly to the tool
  version that wrote them. An NDM from `X-2025.06-SP1` will generally **not**
  open in a different major release. Always rebuild on the target install:
  `icc2_lm_shell -f scripts/02_build_ref_ndm.tcl`.

This is why neither is committed here. The sources and the recipes are the
durable artifacts; the binaries are disposable.

## Install layout gotcha

Library Compiler lives in its **own install tree**, not under `syn/`:

```
/home/synopsys/lc/Y-2026.03/bin/lc_shell      <- correct
/home/synopsys/syn/Y-2026.03/bin/lc_shell     <- does not exist
```

`icc2_shell` and `icc2_lm_shell` come from the `syn/` tree, even though a
separate `/home/synopsys/icc2/Y-2026.03/` also exists.
