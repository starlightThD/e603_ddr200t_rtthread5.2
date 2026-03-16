#################################################################################
## script is used to run power analysis for netlist
#################################################################################

source -echo -verbose $env(SYN_ROOT)/setup/pt_setup.tcl

if {[info exists env(NAME_MAP_FILE)]} {
    set name_map_file $env(NAME_MAP_FILE)
} else {
    set name_map_file "gate"
}

if {[info exists env(SAIF_FILE)]} {
    set activity_file $env(SAIF_FILE)
} else {
    puts "Error: env var SAIF_FILE is not provided"
    exit
}

if {[info exists env(STRIP_PATH)]} {
    set strip_path $env(STRIP_PATH)
} else {
    puts "Error: env var STRIP_PATH is not provided"
    exit
}

read_verilog $env(SYN_ROOT)/${RESULTS_DIR}/${DCRM_FINAL_VERILOG_OUTPUT_FILE}

link_design $DESIGN_NAME

current_design $DESIGN_NAME 

# Load sdc files for timing update
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
        load_upf $upf_file
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

##################################################################  
#    Power Switching Activity Annotation Section                 #  
##################################################################  
source $name_map_file                                   

read_saif $activity_file -strip_path $strip_path    

report_switching_activity -list_not_annotated -include {rtl} > $PT_REPORTS_DIR/${DESIGN_NAME}.activity.rpt

##################################################################
#    Power Analysis Section                                      #
##################################################################
## run power analysis
check_power  > $PT_REPORTS_DIR/${DESIGN_NAME}_check_power.report

update_power  

report_power > $PT_REPORTS_DIR/${DESIGN_NAME}_report_power.report

# Clock Gating & Vth Group Reporting Section
report_clock_gate_savings > $PT_REPORTS_DIR/${DESIGN_NAME}_clock_gate_savings.rpt  

# Set Vth attribute for each library if not set already
foreach_in_collection l [get_libs] {
        if {[get_attribute [get_lib $l] default_threshold_voltage_group] == ""} {
                set lname [get_object_name [get_lib $l]]
                set_user_attribute [get_lib $l] default_threshold_voltage_group $lname -class lib
        }
}

report_power -threshold_voltage_group > $PT_REPORTS_DIR/${DESIGN_NAME}_pwr.per_lib_leakage
report_threshold_voltage_group > $PT_REPORTS_DIR/${DESIGN_NAME}_pwr.per_volt_threshold_group

exit
