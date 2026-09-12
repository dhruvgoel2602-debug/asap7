#-----------------------------------------------------------------------------
# Liberty (.lib) -> Synopsys .db, for every library in lib/
#
#   lc_shell -f scripts/01_build_db.tcl
#
# Run from the repo root. Writes db_out/.
#
# Handles the ASAP7 quirk that a file's internal library name often does not
# match its filename (e.g. *_220122.lib declares *_211120): write_lib needs
# the internal name, so it is queried with list_libs after each read.
#-----------------------------------------------------------------------------

set LIB_DIR lib
set OUT_DIR db_out

file mkdir $OUT_DIR

set files [lsort [glob -nocomplain -directory $LIB_DIR *.lib]]
if {[llength $files] == 0} {
    puts "ERROR: no .lib files found in $LIB_DIR/"
    exit 1
}

set ok 0
set failed {}

foreach f $files {
    set base [file rootname [file tail $f]]
    puts "\n=== $base ==="

    # Snapshot what is already loaded so we can identify the new library.
    set before [list_libs -quiet]

    if {[catch {read_lib $f} err]} {
        puts "  READ FAILED: $err"
        lappend failed $base
        continue
    }

    # The newly added library is whatever list_libs gained.
    set after [list_libs -quiet]
    set new {}
    foreach l $after {
        if {[lsearch -exact $before $l] < 0} { lappend new $l }
    }
    if {[llength $new] == 0} {
        puts "  WARNING: no new library appeared; falling back to filename"
        set libname $base
    } else {
        set libname [lindex $new 0]
        if {$libname ne $base} {
            puts "  note: internal name '$libname' != filename '$base'"
        }
    }

    # Output is named after the FILE, so db names line up with lib/ on disk.
    if {[catch {write_lib $libname -format db -output $OUT_DIR/$base.db} err]} {
        puts "  WRITE FAILED: $err"
        lappend failed $base
        continue
    }

    incr ok
    remove_lib $libname
}

puts "\n----------------------------------------"
puts "compiled : $ok / [llength $files]"
if {[llength $failed]} {
    puts "FAILED   : [join $failed {, }]"
} else {
    puts "all libraries compiled cleanly"
}
puts "output   : $OUT_DIR/"
puts "----------------------------------------"

exit [expr {[llength $failed] ? 1 : 0}]
