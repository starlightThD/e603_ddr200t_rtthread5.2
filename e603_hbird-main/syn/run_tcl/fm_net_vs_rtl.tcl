source -echo -verbose $env(SYN_ROOT)/setup/dc_setup.tcl

#################################################################################
# performing setup
#################################################################################

set user_fm_cons_tcl $env(SYN_ROOT)/constraints/fm_cons.tcl

set_app_var synopsys_auto_setup true
set_app_var verification_set_undriven_signals SYNTHESIS
set_app_var hdlin_unresolved_modules error
#set_app_var verification_force_upf_supplies_on false
set_app_var verification_force_upf_supplies_on true
set_app_var verification_blackbox_match_mode Identity

# upf related settings
set_app_var hdlin_allow_partial_pg_netlist true
set_app_var upf_ground_logic_value 0
set_app_var upf_implementation_based_on_file_headers false
set_app_var upf_implemented_constructs {}
set_app_var upf_warn_on_failed_unresolved_check true
set_app_var upf_warn_on_failed_port_attribute_check true

# clock-gating match strategy
set_app_var verification_clock_gate_reverse_gating true
set_app_var verification_clock_gate_hold_mode      low
set_app_var verification_failing_point_limit       100

set_host_options -max_cores 8

#################################################################################
# Read in the SVF file(s)
#################################################################################

set_svf $env(SYN_ROOT)/${RESULTS_DIR}/${DCRM_SVF_OUTPUT_FILE}

#################################################################################
# Read in the libraries
#################################################################################

foreach tech_lib "${TARGET_LIBRARY_FILES} ${ADDITIONAL_LINK_LIB_FILES}" {
  read_db -technology_library $tech_lib
}

#################################################################################
# Read in the Reference Design as verilog/vhdl source code
#################################################################################

puts "RM-Info: Sourcing script file [which $env(SYN_ROOT)/${RESULTS_DIR}/${DCRM_AUTOREAD_RTL_SCRIPT}]\n"
source -verbose $env(SYN_ROOT)/${RESULTS_DIR}/${DCRM_AUTOREAD_RTL_SCRIPT}

set_top r:/WORK/${DESIGN_NAME}

if { $use_upf_flow == 1 } {
    if {[file exists [which $upf_file]]} {
        puts "INFO: Loading reference upf file $upf_file."
        load_upf -r $upf_file 
        analyze_upf
    } else {
        puts "Error: reference upf file $upf_file is not found or not defined."
        exit
    }
}

#################################################################################
# Read in the Implementation Design from DC-RM results
#
# Choose the format that is used in your flow.
#################################################################################
read_verilog -netlist -libname WORK -i $env(SYN_ROOT)/${RESULTS_DIR}/${DCRM_FINAL_VERILOG_OUTPUT_FILE}

set_top i:/WORK/${DESIGN_NAME}

if { $use_upf_flow == 1 } {
    set impl_upf_file $env(SYN_ROOT)/${RESULTS_DIR}/${DCRM_FINAL_UPF_OUTPUT_FILE}
    if {[file exists [which $impl_upf_file]]} {
        puts "INFO: Loading implementation upf file $impl_upf_file."
        load_upf -i $impl_upf_file 
        analyze_upf
    } else {
        puts "Error: implementation $impl_upf_file is not found or not defined."
        exit
    }
}

#################################################################################
# source user defined formality constraint file before match 
#################################################################################
if {[file exists [which $user_fm_cons_tcl]]} {
    puts "INFO: Sourcing formality constraint file $user_fm_cons_tcl"
    source -verbose $user_fm_cons_tcl
}

#################################################################################
# Match compare points and report unmatched points 
#################################################################################

match

report_unmatched_points > ${FM_REPORTS_DIR}/${FMRM_UNMATCHED_POINTS_REPORT}

##################################################################################
## Verify and Report
##################################################################################

if { ![verify] } {  
  save_session -replace ${FM_REPORTS_DIR}/${FMRM_FAILING_SESSION_NAME}
  report_failing_points > ${FM_REPORTS_DIR}/${FMRM_FAILING_POINTS_REPORT}
  report_aborted        > ${FM_REPORTS_DIR}/${FMRM_ABORTED_POINTS_REPORT}
  analyze_points -all   > ${FM_REPORTS_DIR}/${FMRM_ANALYZE_POINTS_REPORT}
  set fm_passed FALSE
} else {
  set fm_passed TRUE
}

save_session ./${FM_TAG}/${DESIGN_NAME}.net_vs_rtl.session

if { $open_gui == 1 } {
    start_gui
}

exit
