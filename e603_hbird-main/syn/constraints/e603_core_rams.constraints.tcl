
if {[file exists [which ${DCRM_SDC_INPUT_FILE}]]} {
    puts "INFO: Reading SDC file [which ${DCRM_SDC_INPUT_FILE}]"
    source -echo -verbose ${DCRM_SDC_INPUT_FILE}
    update_timing
} else {
    puts "Error: sdc file not found."
    exit
}

if {[info exists env(USER_SDC_FILES)]} {
    foreach u_sdc $env(USER_SDC_FILES) {
        puts "INFO: loading user sdc file $u_sdc"
        source -echo -verbose $u_sdc
    }
}

if {![shell_is_in_topographical_mode]} {
    set auto_wire_load_selection false
    remove_attribute [get_libs] default_wire_load
    set_wire_load_mode  top
    # set_wire_load_model -name Zero
}


set_load [expr [load_of $NAND_CELL/A1]*5] [all_outputs]

set_driving_cell -no_design_rule -lib_cell $BUF_CELL -pin Z [remove_from_collection [all_inputs] [all_clocks]]

set_operating_conditions $env(OPER_COND)

set_max_fanout 32 [current_design]


# if max_data_transition is not explicitly specified in topgun_cfg.yaml,
# use the 0.5*(minimum default_max_transition from all target libraries)
set min_max_lib_trans 100.0
foreach lib_trans [get_attribute $libs default_max_transition] {
    if {$min_max_lib_trans > $lib_trans} {
        set min_max_lib_trans $lib_trans
    }
}
set_max_transition [expr 0.5*$min_max_lib_trans] [current_design]
