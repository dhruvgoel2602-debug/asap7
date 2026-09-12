set NDM_LIBS {}
set FRAME_LIBS {/home/vlsilab/SynopsysFlow/v3_rebuild/ASAP7_ref_v3.ndm}
set LEF_FILES {}
set DB_FILES {/home/vlsilab/SynopsysFlow/db_out/asap7sc7p5t_OA_RVT_FF_nldm_211120.db}
set TECH_FILE "/tmp/.tARL1477868/_techWgEw9t"

set_app_options -name lib.workspace.create_cached_lib -value true
#suppress_messages

set_app_options -name lib.workspace.allow_read_aggregate_lib -value true
create_workspace asap7sc7p5t_OA_RVT_FF_nldm_211120 -scale_factor 4000
foreach frame $FRAME_LIBS {
  read_ndm $frame
}
read_db $DB_FILES
process_workspaces -check_options {-allow_missing} -force -directory CLIBs -output asap7sc7p5t_OA_RVT_FF_nldm_211120.ndm
