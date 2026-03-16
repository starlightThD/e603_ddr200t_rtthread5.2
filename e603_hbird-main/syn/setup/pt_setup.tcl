# pt run in dc or run in standalone flow should source different setup file
if { [info exists env(SYN_ROOT)] } {
    set simple_etm 1
    source -echo -verbose $env(SYN_ROOT)/setup/dc_setup.tcl
} else {
    set simple_etm 0
    source -echo -verbose $env(PT_ROOT)/setup/pt_common_setup.tcl
}

source $env(SYN_ROOT)/run_tcl/pt_common_procs.tcl

# specify synthesis technology from env variable
#if { [info exists env(SYN_TECH)] } {
#    set syn_tech $env(SYN_TECH)
#} else {
#    puts "env variable SYN_TECH is not specified"
#    exit
#}

# date_tag
if { [info exists env(DATE_TAG)] } {
    set date_tag $env(DATE_TAG)
} else {
    puts "env variable DATE_TAG is not specified"
    exit
}

# pt_noise
if { [info exists env(PT_NOISE)] } {
    set pt_noise $env(PT_NOISE)
} else {
    set pt_noise 0
}

# pt_power
if { [info exists env(PT_POWER)] } {
    set pt_power $env(PT_POWER)
} else {
    set pt_power 0
}

# eco physically aware
if { [info exists env(PHYSICALLY_AWARE_ECO)] } {
    set physically_aware_eco $env(PHYSICALLY_AWARE_ECO)
} else {
    set physically_aware_eco 0
}

# fast_eco_mode
# o setup - Setup timing violation
# o hold  - Hold timing violation
# o max_transition  - Maximum transition violation
# o max_capacitance - Maximum capacitance violation
# o max_fanout - Maximum fanout violation
# o noise - Noise violation
# The following keywords are also accepted:
# o timing - Same as {setup hold}
# o drc - Same as {max_transition max_capacitance max_fanout}
if { [info exists env(FAST_ECO_MODE)] } {
    set fast_eco_mode $env(FAST_ECO_MODE)
} else {
    set fast_eco_mode ""
}

# quickly check if all needed files exist before starting session
set_app_var sh_new_variable_message    false
set_app_var sh_source_uses_search_path true
set_app_var sh_continue_on_error       true
# this var is very important, keep pg connections from pg netlist, no need
# to load upf again here.
# set_app_var link_keep_pg_connectivity  true
set_app_var link_create_black_boxes    false
set_app_var extract_model_db_naming_compatibility false

########################################################
# potential vars for PT model extraction:
#
#    extract_model_capacitance_limit
#    extract_model_clock_transition_limit
#    extract_model_data_transition_limit
#    extract_model_enable_report_delay_calculation
#    extract_model_gating_as_nochange
#    extract_model_num_capacitance_points
#    extract_model_num_clock_transition_points
#    extract_model_num_data_transition_points
#    extract_model_status_level
#    extract_model_with_clock_latency_arcs
#    extract_model_with_non_sequential_arcs
#    timing_clock_gating_propagate_enable
#    timing_disable_clock_gating_checks
#    timing_enable_preset_clear_arcs
#    extract_model_with_ccs_timing
#######################################################
set_app_var timing_enable_preset_clear_arcs               false
set_app_var timing_disable_clock_gating_checks            false
# below two are combined to be used for including ccs timing
if { $simple_etm == 0 } {
    set_app_var extract_model_with_ccs_timing                 true
}
set_app_var delay_calc_waveform_analysis_mode             full_design
set_app_var extract_model_status_level                    low
set_app_var extract_model_enable_report_delay_calculation true
set_app_var extract_model_write_case_values_to_constraint_file true
# include pg infomation into lib
if { $use_upf_flow == 1 } {
    set extract_model_include_upf_data true
}

#######################################################
## timing analysis variables
#######################################################
set_app_var timing_report_unconstrained_paths               true
set_app_var timing_enable_max_capacitance_set_case_analysis true
set_app_var timing_enable_max_transition_set_case_analysis  true
set_app_var sdc_save_source_file_information                true
set_app_var timing_early_launch_at_borrowing_latches        false
set_app_var report_default_significant_digits               6
set_app_var timing_remove_clock_reconvergence_pessimism     true
set_app_var timing_save_pin_arrival_and_slack               true
set_app_var timing_save_pin_arrival_and_required            true
set_app_var pba_exhaustive_endpoint_path_limit              100

#######################################################
## signal integrity analysis variables
#######################################################
if { $pt_noise == 1 } {
    set_app_var si_enable_analysis                              true 
    set_app_var si_analysis_logical_correlation_mode            true
    set_app_var si_xtalk_double_switching_mode                  clock_network 
}

#######################################################
## eco related variables
#######################################################
set_app_var eco_enable_more_scenarios_than_hosts            true
set_app_var eco_enable_fixing_clock_used_as_data            true
set_app_var timing_report_include_eco_attributes            true
set_app_var eco_report_unfixed_reason_max_endpoints         100
if { $physically_aware_eco == 1 } {
    set_app_var eco_insert_buffer_search_distance_in_site_rows  8
    set_app_var read_parasitics_load_locations                  true
    set_app_var eco_allow_filler_cells_as_open_sites            true
}

if { $fast_eco_mode != "" } {
    set_app_var eco_save_session_data_type $fast_eco_mode
}

#######################################################
## switching activity power analysis variables
#######################################################
if { $pt_power == 1 } {
    set_app_var power_enable_analysis              true 
    set_app_var power_enable_multi_rail_analysis   true 
    set_app_var power_analysis_mode                averaged 
}

# netlist files specified from evn var
if { [info exists env(NETLIST_FILES)] } {
    set netlist_files $env(NETLIST_FILES)
} else {
    set netlist_files ""
}

# pt_adjust_io_clock_latency_script
if { [info exists env(PT_ADJUST_IO_CLOCK_LATENCY_SCRIPT)] } {
    set pt_adjust_io_clock_latency_script $env(PT_ADJUST_IO_CLOCK_LATENCY_SCRIPT)
} else {
    set pt_adjust_io_clock_latency_script ""
}

# pt_path_group_script
if { [info exists env(PT_PATH_GROUP_SCRIPT)] } {
    set pt_path_group_script $env(PT_PATH_GROUP_SCRIPT)
} else {
    set pt_path_group_script ""
}

if { [info exists env(PT_ROOT)] } {
    set_app_var parasitics_log_file $env(PT_ROOT)/$PT_REPORTS_DIR/parasitics.log
}

##################################################################
#    update search_path var                                      #
#    append user defined search paths into search_path including #
#    : path where netlists/sdc are located                       #
##################################################################
if {[info exists env(USER_SEARCH_DIRS)]} {
    set search_path [concat $search_path $env(USER_SEARCH_DIRS)]
}

set_app_var search_path [lsort -unique $search_path]
set_app_var link_path   [lsort -unique $link_path]

puts "INFO: search path are: $search_path"
puts "INFO: link_path are:   $link_path"
