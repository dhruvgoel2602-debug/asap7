# Provenance and licensing

This repository aggregates third-party PDK collateral with local patches.
Nothing here is proprietary or license-encumbered; every part is
redistributable under the terms below.

## `lib/` — ASAP7 Liberty timing libraries

106 NLDM `.lib` files, unmodified from the ASAP7 7nm predictive PDK.

- **License:** BSD 3-Clause (see `LICENSE`, and the header of every `.lib`)
- **Copyright:** 2020 Lawrence T. Clark, Vinay Vashishtha, or Arizona State University
- **Upstream:** <https://github.com/The-OpenROAD-Project/asap7> ·
  <https://asap.asu.edu/>
- BSD 3-Clause permits redistribution in source form provided the copyright
  notice, conditions, and disclaimer are retained. They are retained inline
  in each file — **do not strip the `.lib` headers.**

Naming note: several `*_220122.lib` INVBUF files declare an internal library
name of `..._211120`. That mismatch is upstream's, not a local edit. Use
`list_libs` after `read_lib` to get the real name before `write_lib`.

The `*_FAKE.lib` (DFFHQN variants) and `fakeram*/fakeregfile*` files are
ASAP7's placeholder macros, shipped upstream under the same terms.

## `snps/` — Synopsys supplemental technology files

Layer maps, GDS in/out translation tables, ITF sources, and the prebuilt
`tlu_plus` parasitic technology file.

- **License:** Unlicense — public domain (see `snps/LICENSE`)
- **Upstream:** <https://github.com/snishizawa/asap7_snps>
- Taken at commit `ec386fe` ("Add note"), unmodified.

## `tech/` — technology files

- `asap07_icc_upstream.tf` — verbatim `icc/asap07_icc.tf` from `asap7_snps`
  (Unlicense).
- `asap07_icc_fixed.tf` — the above with three local fixes (multi-Vt marker
  layers, correct `asap7sc7p5t` site tile, `gridResolution = 4`). Derived
  from public-domain input; offered under the same terms as the rest of this
  repository.
- `asap07_icc.fixes.diff` — generated, `diff -u` of the two.

## `docs/`, `scripts/`

Written locally for this archive. No third-party content.

## Not included

LEF and GDS layout for ASAP7 are **not** redistributed here. Obtain them from
the upstream ASAP7 / OpenROAD-flow-scripts repositories — see `README.md`.
