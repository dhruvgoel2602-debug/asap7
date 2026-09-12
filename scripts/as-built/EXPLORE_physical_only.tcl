set NDM_LIBS {}
set FRAME_LIBS {/home/vlsilab/SynopsysFlow/v3_rebuild/ASAP7_ref_v3.ndm}
set LEF_FILES {}
set DB_FILES {}
set TECH_FILE "/tmp/.tARL1477868/_tech9xvusB"

set_app_options -name lib.workspace.create_cached_lib -value true
set_app_options -name lib.workspace.include_design_filters -value {DECAPx10_ASAP7_75t_R DECAPx1_ASAP7_75t_R DECAPx2_ASAP7_75t_R DECAPx2b_ASAP7_75t_R DECAPx4_ASAP7_75t_R DECAPx6_ASAP7_75t_R FILLER_ASAP7_75t_R FILLERxp5_ASAP7_75t_R TAPCELL_ASAP7_75t_R TAPCELL_WITH_FILLER_ASAP7_75t_R}
#suppress_messages

set_app_options -name lib.workspace.allow_read_aggregate_lib -value true
create_workspace EXPLORE_physical_only -flow physical_only -scale_factor 4000
foreach frame $FRAME_LIBS {
  read_ndm $frame
}
process_workspaces -check_options {-allow_missing} -force -directory CLIBs -output EXPLORE_physical_only.ndm
