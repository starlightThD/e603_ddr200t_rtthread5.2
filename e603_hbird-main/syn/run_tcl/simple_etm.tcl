#################################################################################
## script is used to extracting timing models from netlist/sdc/upf
#################################################################################

source -echo -verbose $env(SYN_ROOT)/setup/pt_setup.tcl

read_verilog $env(SYN_ROOT)/${RESULTS_DIR}/${DCRM_FINAL_VERILOG_OUTPUT_FILE}

link_design $DESIGN_NAME

current_design $DESIGN_NAME 

#################################################################################
# Load sdc files for signal corruption checks
#################################################################################
set SDC_INPUT_FILE $env(SYN_ROOT)/${RESULTS_DIR}/${DCRM_FINAL_SDC_OUTPUT_FILE}
if {[file exists [which ${SDC_INPUT_FILE}]]} {
    puts "RM-Info: Reading SDC file [which ${SDC_INPUT_FILE}]"
    read_sdc -echo ${SDC_INPUT_FILE}
} else {
    puts "Error: sdc file not found."
    exit
}

# load upf file
if { $use_upf_flow == 1 } {
    set upf_file $env(SYN_ROOT)/${RESULTS_DIR}/${DCRM_FINAL_UPF_OUTPUT_FILE}
    if {[file exists [which $upf_file]]} {
        puts "RM-Info: Loading upf file [which $upf_file]\n"
        load_upf -echo $upf_file
    } else {
        puts "Error: cannot find upf file, please double check"
        exit
    }
}

# since dc_allow_rtl_pg is specified, there may be pg connections in rtl
# convert_pg is used to convert rtl pg connections into UPF constraints
if { $use_upf_flow == 1 } {
    source -echo -verbose $low_power_tcl
}

update_timing -full

extract_model -library_cell -test_design -output ${PT_RESULTS_DIR}/${DESIGN_NAME} -format {lib db}

exit
