# ASAP7 + ICC2 flow notes

Working notes from bringing ASAP7 up on the Synopsys flow. These record
things that were *verified against the tools*, plus the failures that cost
the most time. Read the gotchas before running a real block.

Environment these were taken on: Rocky Linux 8.10, ICC2/Fusion Compiler
X-2025.06-SP1 (`/home/synopsys/syn/Y-2026.03/`), Library Compiler in a
**separate** install tree (`/home/synopsys/lc/Y-2026.03/bin/lc_shell`, *not*
under `syn/`).

---

## 1. Liberty → db (Library Compiler)

All 88 corner/Vt/group combinations compile cleanly.

**Gotcha:** some `.lib` files' internal `library (name) {...}` does not match
the filename — e.g. every `*_220122.lib` INVBUF file internally still says
`_211120`. `write_lib` takes the *internal* name, so query it first:

```tcl
read_lib asap7sc7p5t_INVBUF_RVT_TT_nldm_220122.lib
list_libs                                   ;# -> asap7sc7p5t_INVBUF_RVT_TT_nldm_211120
write_lib asap7sc7p5t_INVBUF_RVT_TT_nldm_211120 -format db -output db_out/...
```

See `scripts/01_build_db.tcl`, which does this automatically.

## 2. Physical reference library (icc2_lm_shell)

```tcl
create_workspace <NAME> -flow normal -scale_factor 4000 \
    -technology tech/asap07_icc_fixed.tf
read_lef -include tech <asap7_tech_1x_201209.lef>
set_attribute [get_site_defs asap7sc7p5t] is_default true
set_attribute [get_site_defs asap7sc7p5t] symmetry Y
read_lef -include cell <asap7sc7p5t_28_R_1x_220121a.lef>   ;# R / L / SL per Vt
check_workspace
commit_workspace -output ASAP7_ref.ndm -force
```

The two `set_attribute` calls matter: without them the workspace keeps the
old oversized `unit` tile as default and rows come out 4× too tall.

## 3. Parasitics

```tcl
read_parasitic_tech -tlup snps/starrc/tlu_plus \
                    -layermap snps/starrc/asap07.layermap -name asap7_default
set_parasitic_parameters -corners {TT_corner SS_corner FF_corner default} \
                         -early_spec asap7_default -late_spec asap7_default
```

**Gotcha:** the `default` corner exists implicitly per block and needs its own
assignment. Omitting it fails later in `clock_opt` with *"Corner default does
not have parasitic tech information"*.

## 4. MCMM — and the big trap

PVT and parasitics *are* correctly per-corner:

```tcl
create_corner <name>
current_corner <name>
set_pvt -corners {<name>} -voltage <V> -temperature <T>
create_mode functional
create_scenario -name <s> -mode functional -corner <name>
```

Voltages/temps used: **TT = 0.70 V / 25 °C**, **SS = 0.63 V / 125 °C**,
**FF = 0.77 V / −40 °C**.

> ### `set_ref_libs` is NOT corner-scoped
>
> `set_ref_libs -ref_libs <path>` sets **one global** logical-library binding
> for the whole block, regardless of `current_corner`. Calling it once per
> corner **overwrites** the previous binding — it does not accumulate.
>
> **Symptom:** cells placed while one corner's libraries were active silently
> become black boxes (`is_black_box == true`) once another corner's
> `set_ref_libs` replaces the binding.
>
> **Recovery:**
> ```tcl
> current_corner <X>
> set link_library "..."
> set_ref_libs -ref_libs ...
> link_block -force
> ```

**Practical consequence.** True simultaneous MCMM optimization is not
reliable this way. What works: implement (floorplan → place → CTS → route)
against **one** corner (TT); for signoff, re-bind libraries sequentially per
corner, re-link, check timing, then switch back to TT before continuing.
Genuine multi-corner optimization would need the cell libraries rebuilt as
proper multi-PVT-pane NDMs — a larger job, not attempted here.

## 5. Power/ground

```tcl
connect_pg_net -automatic
create_net VDD -power ; create_net VSS -ground
create_port VDD -direction in ; create_port VSS -direction in
connect_net VDD [get_ports VDD] ; connect_net VSS [get_ports VSS]

create_pg_ring_pattern ring_pattern -nets {VDD VSS} \
  -horizontal_layer M8 -horizontal_width 2 -horizontal_spacing 2 \
  -vertical_layer  M9 -vertical_width  2 -vertical_spacing  2
set_pg_strategy ring_strategy -core -pattern {{name: ring_pattern}{nets: {VDD VSS}}}
set_pg_strategy strap_strategy -core -pattern {{name: strap_pattern}{nets: {VDD VSS}}}
compile_pg
```

Note the nets go *inside* the pattern definition. Clean on a small FIFO:
12 wires, 10 vias, DRC-clean.

## 6. Floorplan / placement

```tcl
initialize_floorplan -core_utilization 0.7 -core_offset {5 5 5 5}
create_placement -effort high
legalize_placement
```

There is no `-core_aspect_ratio` flag. Clean run: 0 violations, 71 % util.

## 7. Synthesis (Design Compiler)

```tcl
set search_path [list db_out .]
set target_library "asap7sc7p5t_SEQ_RVT_TT_nldm_220123.db \
                    asap7sc7p5t_INVBUF_RVT_TT_nldm_220122.db \
                    asap7sc7p5t_AO_RVT_TT_nldm_211120.db \
                    asap7sc7p5t_OA_RVT_TT_nldm_211120.db \
                    asap7sc7p5t_SIMPLE_RVT_TT_nldm_211120.db"
set link_library "* $target_library"
read_verilog <rtl>.v ; current_design <top> ; link
read_sdc <constraints>.sdc
compile_ultra
write_verilog -hierarchy <out>.v ; write_sdc <out>.sdc
```

---

## Open issue at time of archiving

`clock_opt -to route_clock` fails on a block bound to the TT corner:

```
Warning: Cannot find default buffer/inverter for VA DEFAULT_VA ... (OPT-043)
Error:   Cannot find usable buffers or inverters. (OPT-045)
```

Ruled out: buffers/inverters *are* present in the linked library (`BUFx*`,
`INVx*`, `CKINVDCx*`); none are `dont_use`; `valid_purposes` includes `cts`;
voltage area `DEFAULT_VA` exists with correct `power_net`/`ground_net`; zero
black-box cells.

Untested hypotheses: (a) SDC clock definitions were lost during the
black-box/relink episode, so CTS has no clock to build against; (b) the
voltage area needs CTS buffers designated explicitly. Next probes:
`all_clocks`, `report_clock`, `help *default_buffer*`.

Also not done: routing, PrimeTime signoff, `write_gds`.

---

## Methodology that worked

When a command's syntax or behavior is unclear, **do not guess from memory** —
this install's command surface repeatedly differed from generic Synopsys
knowledge. In order:

1. `<command> -help` — full flag list, unlike the one-line `help *pattern*`.
2. The man page, which has worked examples that resolved several stuck
   points (`set_pg_strategy`, `create_scenario`):
   ```bash
   find /home/synopsys/syn/*/fusioncompiler/doc/ICC2/man/cat2/ -iname "<command>*"
   ```
3. For error codes:
   ```bash
   find /home/synopsys/syn/*/fusioncompiler/doc -iname "<ERRORCODE>*"
   ```
   These `.n` files explain the error and what to do next.
