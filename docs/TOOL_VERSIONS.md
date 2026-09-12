# Tool versions

Liberty (`lib/`), the tech files (`tech/`) and the `snps/` collateral are plain
text and version-independent. The build products described in
`scripts/README.md` are **not** — this file records what produced them and what
that means when you rebuild.

## Currently installed (verified by `-version`)

| Tool | Version | Binary |
|---|---|---|
| **Library Compiler** | `Y-2026.03` (Feb 25, 2026) | `/home/synopsys/lc/Y-2026.03/bin/lc_shell` |
| **IC Compiler II** | `Y-2026.03` (May 19, 2026) | `/home/synopsys/icc2/Y-2026.03/bin/icc2_shell` |
| **IC Compiler II LM** | `Y-2026.03` (May 19, 2026) | `/home/synopsys/icc2/Y-2026.03/bin/icc2_lm_shell` |
| **PrimeTime** | `Y-2026.03` (Feb 25, 2026) | `/home/synopsys/prime/Y-2026.03/bin/pt_shell` |

Platform: Rocky Linux 8.10, x86-64 (kernel 4.18.0-553).

## What produced the original build products

- The **`.db` set** was compiled by Library Compiler `Y-2026.03` — the version
  still installed above. 88/88 files compiled cleanly.
- The **`.ndm` reference libraries** were built by IC Compiler II
  **`X-2025.06-SP1-707-T-20251209`** (Dec 9, 2025; base build 2025-07-07).
  **That ICC2 is no longer installed** — the box has since moved to
  `Y-2026.03`.

This is a concrete example of why the binaries are not committed here: the
tool that wrote them is already gone, so shipping them would have shipped
something unopenable.

## What that means for restoring

- **`lib/*.lib`, `tech/*.tf`, `snps/*`** — text. Use with any tool version.
- **`.db`** — Liberty `.db` is broadly forward-compatible, but one written by
  a newer LC may be rejected by an *older* DC/ICC2. Rebuilding takes minutes,
  so rebuild rather than debug a version mismatch:
  `lc_shell -f scripts/01_build_db.tcl`.
- **`.ndm`** — ICC2 reference libraries are tied tightly to the tool version
  that wrote them; one from a different major release will generally not open.
  Always rebuild on whatever ICC2 you actually have:
  `icc2_lm_shell -f scripts/02_build_ref_ndm.tcl`.

The sources and the recipes are the durable artifacts; the binaries are
disposable.

## Install layout gotcha

On this installation each tool has its **own** install tree. Neither Library
Compiler nor ICC2 lives under `syn/`, which is easy to get wrong because `syn/`
is where `dc_shell` and `design_vision` are:

```
/home/synopsys/lc/Y-2026.03/bin/lc_shell        <- correct
/home/synopsys/syn/Y-2026.03/bin/lc_shell       <- does not exist

/home/synopsys/icc2/Y-2026.03/bin/icc2_shell    <- correct
/home/synopsys/icc2/Y-2026.03/bin/icc2_lm_shell <- correct
/home/synopsys/syn/Y-2026.03/bin/icc2_shell     <- does not exist
```

Note also that `icc2_lm_shell -version` self-reports as `lm_shell`.

Check with `-version` rather than assuming a layout; these paths are specific
to this install and say nothing about where your site puts things.
