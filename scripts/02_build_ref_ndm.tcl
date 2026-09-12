#-----------------------------------------------------------------------------
# LEF + fixed .tf -> ICC2 physical reference libraries (.ndm), one per Vt
#
#   icc2_lm_shell -f scripts/02_build_ref_ndm.tcl
#
# Run from the repo root. Writes ASAP7_ref.ndm / ASAP7_LVT_ref.ndm /
# ASAP7_SLVT_ref.ndm.
#
# LEF IS NOT IN THIS REPO. Point LEF_DIR at an ASAP7 platform checkout:
#   git clone https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts
#   LEF_DIR = <clone>/flow/platforms/asap7/lef
#-----------------------------------------------------------------------------

set LEF_DIR   [expr {[info exists ::env(ASAP7_LEF_DIR)] ? $::env(ASAP7_LEF_DIR) : "lef"}]
set TECH_FILE tech/asap07_icc_fixed.tf
set TECH_LEF  $LEF_DIR/asap7_tech_1x_201209.lef

# Vt flavour -> {cell LEF, output library}
set FLAVOURS {
    RVT   {asap7sc7p5t_28_R_1x_220121a.lef   ASAP7_ref.ndm}
    LVT   {asap7sc7p5t_28_L_1x_220121a.lef   ASAP7_LVT_ref.ndm}
    SLVT  {asap7sc7p5t_28_SL_1x_220121a.lef  ASAP7_SLVT_ref.ndm}
}

if {![file exists $TECH_FILE]} { puts "ERROR: missing $TECH_FILE"; exit 1 }
if {![file exists $TECH_LEF]}  {
    puts "ERROR: missing tech LEF at $TECH_LEF"
    puts "       set ASAP7_LEF_DIR to your ASAP7 platform lef/ directory"
    exit 1
}

foreach {vt spec} $FLAVOURS {
    lassign $spec cell_lef out_ndm
    set cell_lef $LEF_DIR/$cell_lef

    puts "\n================ $vt -> $out_ndm ================"
    if {![file exists $cell_lef]} {
        puts "SKIP: missing $cell_lef"
        continue
    }

    # scale_factor 4000 matches the .tf; gridResolution 4 in the fixed .tf
    # gives a 0.001 um manufacturing grid, which divides the 0.054 site width.
    create_workspace ASAP7_${vt}_ws -flow normal -scale_factor 4000 \
        -technology $TECH_FILE

    read_lef -include tech $TECH_LEF

    # Must come after the tech LEF and before the cell LEF: otherwise the
    # oversized legacy "unit" tile stays default and rows are 4x too tall.
    set_attribute [get_site_defs asap7sc7p5t] is_default true
    set_attribute [get_site_defs asap7sc7p5t] symmetry  Y

    read_lef -include cell $cell_lef

    check_workspace
    commit_workspace -output $out_ndm -force

    puts "built $out_ndm"
}

puts "\ndone. bind in ICC2 with:  set_ref_libs -ref_libs ASAP7_ref.ndm"
exit 0
