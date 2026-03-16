source -echo -verbose $env(SYN_ROOT)/setup/dc_setup.tcl
source -echo -verbose $env(SYN_ROOT)/run_tcl/dc.common_proc.tcl

#################################################################################
# Design Compiler Reference Methodology Script for Top-Down Flow
# Script: dc.tcl
# Version: K-2015.06 (July 13, 2015)
# Copyright (C) 2007-2015 Synopsys, Inc. All rights reserved.
#################################################################################

#################################################################################
# Additional Variables
#
# Add any additional variables needed for your flow here.
#################################################################################
set_app_var report_default_significant_digits     6
set_app_var hdlin_infer_multibit                  default_all

# Enable the support of via resistance for RC estimation to improve the timing
# correlation with IC Compiler
set_app_var spg_enable_via_resistance_support     true

set_app_var timing_enable_multiple_clocks_per_reg true

# suppress errors, those must be reviewed before final sign-off
set suppress_errors $ignore_errors
# suppress some info/warning from printing out to reduce log as well as improving runtime
suppress_message  {OPT-319 AUTOREAD-303 HDL-193 OPT-1056 VER-130 VO-12 TIM-179 UID-51}

#################################################################################
# Setup for Formality Verification
#################################################################################

# In the event of an inconclusive (or hard) verification, we recommend using
# the set_verification_priority commands provided from the analyze_points command
# in Formality. The set_verification_priority commands target specific
# operators to reduce verification complexity while minimizing QoR impact.
# The set_verification_priority commands should be applied after the design
# is read and elaborated.

# For designs that don't have tight QoR constraints and don't have register retiming,
# you can use the following variable to enable the highest productivity single pass flow.
# This flow modifies the optimizations to make verification easier.
# This variable setting should be applied prior to reading in the RTL for the design.

# set_app_var simplified_verification_mode true
set_svf ${RESULTS_DIR}/${DCRM_SVF_OUTPUT_FILE}

# for svf formality use
set_app_var hdlin_enable_hier_map                 true

#################################################################################
# Setup SAIF Name Mapping Database
#
# Include an RTL SAIF for better power optimization and analysis.
#
# saif_map should be issued prior to RTL elaboration to create a name mapping
# database for better annotation.
################################################################################

saif_map -start

if { $use_upf_flow == 1 } {
    source -echo -verbose $env(SYN_ROOT)/run_tcl/upf_vars.tcl
} else {
    set_app_var dc_allow_rtl_pg false
}

#################################################################################
# Read in the RTL Design
#
# Read in the RTL source files or read in the elaborated design (.ddc).
#################################################################################
set_app_var hdlin_autoread_verilog_extensions     ".v .vh";
set_app_var hdlin_autoread_sverilog_extensions    ".sv .sverilog";

define_design_lib work -path ./$SYN_TAG/WORK

# Note: When autoread is used ${RTL_SOURCE_FILES} can include a list of
#       both directories and files.
if {$DFT_FILELIST == ""} {
    analyze -autoread \
            -library WORK \
            -rebuild \
            -recursive \
            -define $ana_define_opts \
            -top ${DESIGN_NAME} \
            -output_script ${RESULTS_DIR}/${DCRM_AUTOREAD_RTL_SCRIPT} \
            ${RTL_SOURCE_FILES}
} else {
    analyze \
    -format verilog \
    -library WORK \
    -define $ana_define_opts \
    -vcs "-f ${DFT_FILELIST}"
}
elaborate ${DESIGN_NAME}
link

# You can read an elaborated design from the same release.
# Using an elaborated design from an older release will not give the best results.

# read_ddc ${DCRM_ELABORATED_DESIGN_DDC_OUTPUT_FILE}
current_design ${DESIGN_NAME}

# below commands used for svf creation
set_verification_top

# doing uniquify for whole design
set_app_var uniquify_naming_style "${DESIGN_NAME}_%s_%d"
if { $force_uniquify == 1 } {
    uniquify -force
} else {
    uniquify
}

rename_design -prefix ${DESIGN_NAME}_  [ remove_from_collection  [all_designs]  [get_designs ${DESIGN_NAME}]]

#################################################################################
# Library Modifications
#
# Apply library modifications after the libraries are loaded.
#################################################################################
if {[file exists [which ${LIBRARY_DONT_USE_FILE}]]} {
    puts "RM-Info: Sourcing script file [which ${LIBRARY_DONT_USE_FILE}]\n"
    source -echo -verbose ${LIBRARY_DONT_USE_FILE}
}

#################################################################################
# set ideal_networks at incremental stage to avoid assign statements in netlist
#################################################################################
if {[file exists [which ${DCRM_IDEAL_NETWORK_CONS_TCL}]]} {
    puts "RM-Info: Sourcing script file [which ${DCRM_IDEAL_NETWORK_CONS_TCL}]\n"
    source -echo -verbose ${DCRM_IDEAL_NETWORK_CONS_TCL}
}

#################################################################################
# Apply Logical Design Constraints
#################################################################################

if {[file exists [which ${DCRM_CONSTRAINTS_INPUT_FILE}]]} {
    puts "RM-Info: Sourcing script file [which ${DCRM_CONSTRAINTS_INPUT_FILE}]\n"
    source -echo -verbose ${DCRM_CONSTRAINTS_INPUT_FILE}
} else {
    puts "Error: cannot find sdc input file, please double check"
    exit
}

#################################################################################
# set constraints on async fifo cdc path
#################################################################################
if {[file exists [which ${DCRM_ASYNC_FIFO_CONS_TCL}]]} {
    if {$use_async_fifo_cons == 1} {
        puts "RM-Info: Sourcing script file [which ${DCRM_ASYNC_FIFO_CONS_TCL}]\n"
        source -echo -verbose ${DCRM_ASYNC_FIFO_CONS_TCL}
    }
}

# redirect those two commands to background
redirect -bg -max_cores 1 /dev/null {write -hierarchy -format ddc     -output ${RESULTS_DIR}/${DCRM_ELABORATED_DESIGN_DDC_OUTPUT_FILE}}
redirect -bg -max_cores 1 /dev/null {write -hierarchy -format verilog -output ${RESULTS_DIR}/${DCRM_GTECH_VERILOG_OUTPUT_FILE}}

# load upf file
if { $use_upf_flow == 1 } {
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


if {$link_only == 1} {
    exit
}

#################################################################################
# Apply DFT setup
#################################################################################
if { $insert_dft_logic == 1 } {
    ## setup for tessent
    if { $dft_tool == "tessent" } {
        if { [info exists env(DFT_SDC_FILE)] } {
            if {[file exists [which $env(DFT_SDC_FILE)]]} {
                puts "RM-Info: Sourcing dft sdc file $env(DFT_SDC_FILE)"
                source -echo -verbose $env(DFT_SDC_FILE)
            }
        }
    }
}

#################################################################################
# Power Optimization Section
#################################################################################

#############################################################################
# Clock Gating Setup
#############################################################################
# If you do not want clock-gating to optimize your user instantiated
# clock-gating cells, you should set the pwr_preserve_cg attribute upon
# those clock-gating cells.

# clkgate cell has been set as dont_touch inside the module, so comment below out
# set_preserve_clock_gating [get_cell <user_clock_gating_cells>]

# The compile_ultra and insert_clock_gating commands use the default settings of
# the set_clock_gating_style command during clock-gate insertion. The default
# settings of the set_clock_gating_style command is suitable for most designs.

# Default clock_gating_style suits most designs.  Change only if necessary.
set_app_var power_cg_reconfig_stages              false
set_app_var power_cg_balance_stages               false
set_app_var power_cg_auto_identify                false
set_app_var power_cg_gated_clock_net_naming_style "CLKGATING_%c_%g_%d"
set_app_var power_cg_module_naming_style          "POWERMODULE_%e_%t_%d"
set_app_var power_cg_cell_naming_style            "POWERGATING_%c_%n_%d"

#set_clock_gating_style -positive_edge_logic {integrated} -negative_edge_logic {integrated} -control_point before -max_fanout 24 -num_stages 1

# Clock gate insertion is now performed during compile_ultra -gate_clock
# so insert_clock_gating is no longer recommended at this step.

# The following setting can be used to enable global clock gating.
# With global clock gating, common enables are extracted across hierarchies
# which results in fewer redundant clock gates.
set compile_clock_gating_through_hierarchy true

# For better timing optimization of enable logic, clock latency for
# clock gating cells can be optionally specified.

# set_clock_gate_latency -clock <clock_name> -stage <stage_num> \
#         -fanout_latency {fanout_range1 latency_val1 fanout_range2 latency_val2 ...}

# You can use "set_self_gating_options" command to specify self-gating
# options when -self_gating option is used in addition to -gate_clock
# option at the compile_ultra command. To inserts self-gate on clock-gated
# registers, uncomment the following line, below options is only used in dcg flow
# set_self_gating_options -interaction_with_clock_gating insert

# To improve enable timing in high performance designs, physically aware clock gating
# is available in Design Compiler topographical for Synopsys Physical Guidance (SPG)
# flow. This flow works best with a corresponding IC Compiler  SPG flow. To enable
# physically aware clock gating in Design Compiler Graphical, uncomment the
# following setting:

#############################################################################
# Apply Power Optimization Constraints
#############################################################################

# Include a SAIF file, if possible, for power optimization.  If a SAIF file
# is not provided, the default toggle rate of 0.1 will be used for propagating
# switching activity. instance name should be saparated with '/', such as tb_top/dut
if {[file exists [which ${SAIF_FILE}]]} {
    puts "RM-Info: Reading Saif file [which ${SAIF_FILE}]\n"
    if {[info exists env(POWER_TARGET_INST)]} {
        current_design $env(POWER_TARGET_INST)
        read_saif -auto_map_names -input $SAIF_FILE -instance $saif_instance_hier -verbose
        current_design ${DESIGN_NAME}
    } else {
        read_saif -auto_map_names -input $SAIF_FILE -instance $saif_instance_hier -verbose
    }
}

# Low power placement may save additional dynamic power by shortening the net lengths
# of nets with high switching activity, in physical guidance flow.
# Enable dynamic power optimization for low power placement to work.
# Reading a SAIF file is also recommended to get accurate switching activity information.
set_dynamic_optimization true

if {[shell_is_in_topographical_mode]} {
    set_app_var power_low_power_placement true
    # For multi-Vth design, replace the following to set the threshold voltage groups in the libraries.

    # set_attribute <my_hvt_lib> default_threshold_voltage_group HVT -type string
    # set_attribute <my_lvt_lib> default_threshold_voltage_group LVT -type string
}

if { $LIB_HAS_RVT == 1} {
    set_attribute $lib_rvt default_threshold_voltage_group RVT -type string

    if {$LIB_RVT_PERC != 0} {
        set_multi_vth_constraint -lvth_groups RVT -lvth_percentage $LIB_RVT_PERC  -type hard
    }
}

if { $LIB_HAS_LVT == 1} {
    set_attribute $lib_lvt default_threshold_voltage_group LVT -type string

    if {$LIB_LVT_PERC != 0} {
        set_multi_vth_constraint -lvth_groups LVT -lvth_percentage $LIB_LVT_PERC  -type hard
    }
}

if { $LIB_HAS_ULVT == 1} {
    set_attribute $lib_ulvt default_threshold_voltage_group ULVT -type string

    if {$LIB_ULVT_PERC != 0} {
        set_multi_vth_constraint -lvth_groups ULVT -lvth_percentage $LIB_ULVT_PERC  -type hard
    }
}


# Starting in J-2014.09, leakage optimization is the default flow and is always enabled.

if {[shell_is_in_topographical_mode]} {
    # Use the following command to enable power prediction using clock tree estimation.
    # set_power_prediction true -ct_references <LIB CELL LIST>
}

if {[shell_is_in_topographical_mode]} {
    ##################################################################################
    # Apply Physical Design Constraints
    #
    # Optional: Floorplan information can be read in here if available.
    # This is highly recommended for irregular floorplans.
    #
    # Floorplan constraints can be provided from one of the following sources:
    # * extract_physical_constraints with a DEF file
    # * read_floorplan with a floorplan file (written by write_floorplan)
    # * User generated Tcl physical constraints
    #
    ##################################################################################

    # Specify ignored layers for routing to improve correlation
    # Use the same ignored layers that will be used during place and route

    if { ${MIN_ROUTING_LAYER} != ""} {
      set_ignored_layers -min_routing_layer ${MIN_ROUTING_LAYER}
    }
    if { ${MAX_ROUTING_LAYER} != ""} {
      set_ignored_layers -max_routing_layer ${MAX_ROUTING_LAYER}
    }

    report_ignored_layers

    # If the macro names change after mapping and writing out the design due to
    # ungrouping or Verilog change_names renaming, it may be necessary to translate
    # the names to correspond to the cell names that exist before compile.

    # During DEF constraint extraction, extract_physical_constraints automatically
    # matches DEF names back to precompile names in memory using standard matching rules.
    # read_floorplan will also automatically perform this name matching.

    # Modify set_query_rules if other characters are used for hierarchy separators
    # or bus names.

    # set_query_rules  -hierarchical_separators {/ _ .} \
    #                  -bus_name_notations {[] __ ()}   \
    #                  -class {cell pin port net}       \
    #                  -wildcard                        \
    #                  -regsub_cumulative               \
    #                  -show

    ## For DEF floorplan input

    # The DEF file for Design Compiler Topographical can be written from IC Compiler using the following
    # recommended options:
    # icc_shell> write_def -version 5.7 -rows_tracks_gcells -fixed -pins -blockages -specialnets \
    #                      -vias -regions_groups -verbose -output ${DCRM_DCT_DEF_INPUT_FILE}

    if {[file exists [which ${DCRM_DCT_DEF_INPUT_FILE}]]} {
        # If you have physical only cells as a part of your floorplan DEF file, you can use
        # the -allow_physical_cells option with extract_physical_constraints to include
        # the physical only cells as a part of the floorplan in Design Compiler to improve correlation.
        #
        # Note: With -allow_physical_cells, new logical cells in the DEF file
        #       that have a fixed location will also be added to the design in memory.
        #       See the extract_physical_constraints manpage for more information about
        #       identifying the cells added to the design when using -allow_physical_cells.

        # extract_physical_constraints -allow_physical_cells ${DCRM_DCT_DEF_INPUT_FILE}

        puts "RM-Info: Reading in DEF file [which ${DCRM_DCT_DEF_INPUT_FILE}]\n"
        extract_physical_constraints ${DCRM_DCT_DEF_INPUT_FILE}
    }

    ## For floorplan file input

    # The floorplan file for Design Compiler Topographical can be written from IC Compiler using the following
    # recommended options:
    # Note: IC Compiler requires the use of -placement {terminal} with -create_terminal beginning in the
    #       D-2010.03-SP1 release.
    # icc_shell> write_floorplan -placement {io terminal hard_macro soft_macro} -create_terminal \
    #                            -row -create_bound -preroute -track ${DCRM_DCT_FLOORPLAN_INPUT_FILE}

    if {[file exists [which ${DCRM_DCT_FLOORPLAN_INPUT_FILE}]]} {
        puts "RM-Info: Reading in floorplan file [which ${DCRM_DCT_FLOORPLAN_INPUT_FILE}]\n"
        read_floorplan ${DCRM_DCT_FLOORPLAN_INPUT_FILE}
    }

    if {[file exists [which ${DCRM_DCT_PHYSICAL_CONSTRAINTS_INPUT_FILE}]]} {
        # For Tcl constraints, the name matching feature must be explicitly enabled
        # and will also use the set_query_rules setttings. This should be turned off
        # after the constraint read in order to minimize runtime.

        set_app_var enable_rule_based_query true
        puts "RM-Info: Sourcing script file [which ${DCRM_DCT_PHYSICAL_CONSTRAINTS_INPUT_FILE}]\n"
        source -echo -verbose ${DCRM_DCT_PHYSICAL_CONSTRAINTS_INPUT_FILE}
        set_app_var enable_rule_based_query false
    }

    # Use write_floorplan to save the applied floorplan.
    # Note: A secondary floorplan file ${DCRM_DCT_FLOORPLAN_OUTPUT_FILE}.objects
    #       might also be written to capture physical-only objects in the design.
    #       This file should be read in before reading the main floorplan file.

    write_floorplan -all ${RESULTS_DIR}/${DCRM_DCT_FLOORPLAN_OUTPUT_FILE}

    # Verify that all the desired physical constraints have been applied
    # Add the -pre_route option to include pre-routes in the report
    report_physical_constraints > ${REPORTS_DIR}/${DCRM_DCT_PHYSICAL_CONSTRAINTS_REPORT}
}

#################################################################################
# Save the compile environment snapshot for the Consistency Checker utility.
#
# This utility checks for inconsistent settings between Design Compiler and
# IC Compiler which can contribute to correlation mismatches.
#
# Download this utility from SolvNet.  See the following SolvNet article for
# complete details:
#
# https://solvnet.synopsys.com/retrieve/026366.html
#
# The article is titled: "Using the Consistency Checker to Automatically Compare
# Environment Settings Between Design Compiler and IC Compiler"
#################################################################################

# Uncomment the following to snapshot the environment for the Consistency Checker

# write_environment -consistency -output ${REPORTS_DIR}/${DCRM_CONSISTENCY_CHECK_ENV_FILE}

#################################################################################
# Check for Design Problems
#################################################################################

# running below three commands in parallel to save runtime
redirect -bg -max_cores 1 ${REPORTS_DIR}/${DCRM_CHECK_DESIGN_REPORT} {check_design}
redirect -bg -max_cores 1 ${REPORTS_DIR}/check_timing_pre_compile.rpt {check_timing}
redirect -bg -max_cores 1 ${REPORTS_DIR}/clocks_info.rpt {report_clock -groups} 

# The analyze_datapath_extraction command can help you to analyze why certain data
# paths are no extracted, uncomment the following line to report analyisis.

# analyze_datapath_extraction > ${REPORTS_DIR}/${DCRM_ANALYZE_DATAPATH_EXTRACTION_REPORT}

#################################################################################
# Compile the Design
#
# Recommended Options:
#
#     -scan
#     -gate_clock (-self_gating)
#     -retime
#     -spg
#
# Use compile_ultra as your starting point. For test-ready compile, include
# the -scan option with the first compile and any subsequent compiles.
#
# Use -gate_clock to insert clock-gating logic during optimization.  This
# is now the recommended methodology for clock gating.
#
# Use -self_gating option in addition to -gate_clock for potentially saving
# additional dynamic power, in topographical mode only. Registers that are
# not clock gated will be considered for XOR self gating.
# XOR self gating should be performed along with clock gating, using -gate_clock
# and -self_gating options. XOR self gates will be inserted only if there is
# potential power saving without degrading the timing.
# An accurate switching activity annotation either by reading in a saif
# file or through set_switching_activity command is recommended.
# You can use "set_self_gating_options" command to specify self-gating
# options.
#
# Use -retime to enable adaptive retiming optimization for further timing benefit.
#
# Use the -spg option to enable Design Compiler Graphical physical guidance flow.
# The physical guidance flow improves QoR, area and timing correlation, and congestion.
# It also improves place_opt runtime in IC Compiler.
#
# Note: In addition to -spg option you can enable the support of via resistance for
#       RC estimation to improve the timing correlation with IC Compiler by using the
#       following setting:
#
set_app_var spg_enable_via_resistance_support true
#
# You can selectively enable or disable the congestion optimization on parts of
# the design by using the set_congestion_optimization command.
# This option requires a license for Design Compiler Graphical.
#
# The constant propagation is enabled when boundary optimization is disabled. In
# order to stop constant propagation you can do the following
#
# set_compile_directives -constant_propagation false <object_list>
#
# Note: Layer optimization is on by default in Design Compiler Graphical, to
#       improve the the accuracy of certain net delay during optimization.
#       To disable the the automatic layer optimization you can use the
#       -no_auto_layer_optimization option.
#
#################################################################################

set placer_enable_enhanced_router true
set placer_congestion_effort medium
#set_preferred_routing_direction -layers {metal1 metal3 metal5 metal7} -direction horizontal
#set_preferred_routing_direction -layers {metal2 metal4 metal6 metal8} -direction  vertical

if {[shell_is_in_topographical_mode]} {

    set_app_var power_cg_physically_aware_cg true

    # Use the "-check_only" option of "compile_ultra" to verify that your
    # libraries and design are complete and that optimization will not fail
    # in topographical mode.  Use the same options as will be used in compile_ultra.
    if { $insert_dft_logic == 1 } {
        compile_ultra -scan -gate_clock -self_gating -spg -check_only
    } else {
        compile_ultra -gate_clock -self_gating -spg -check_only
    }
}

# set map_only to cell list from config
if { $has_map_only_cells == 1 } {
    foreach cell {$MAP_ONLY_CELLS} {
        set_map_only [get_cells {$cell}]
    }
}

# set_ungroup false to some specified cells
if { $has_dont_ungroup_cells == 1 } {
    set_dont_ungroup_hierarchy "$DONT_UNGROUP_CELLS"
}

if { $syn_flatten == 1 } {
    ungroup -all -flatten -start_level $syn_flatten_level
} else {
    if { $has_ungroup_cells == 1 } {
        foreach ug_cell $xl_ungroup_cells {
            puts "INFO: ungrouping cell $ug_cell"
            ungroup [get_cells $ug_cell] -flatten
        }
    }
}

# below commands only used for fixing multiple port nets
set_fix_multiple_port_nets -all -buffer_constants

current_design ${DESIGN_NAME}

# disable design rule for synthesis experiment to reduce comp time
if { $do_exp == 1 } {
    #puts "INFO: running compile_ultra experimentally."
    source $env(SYN_ROOT)/run_tcl/write_dummy_lib.tcl -echo
    #redirect -bg -max_cores 1 /dev/null {write -format verilog -hierarchy -pg -output ${RESULTS_DIR}/${DCRM_FINAL_PG_VERILOG_OUTPUT_FILE}}
    #redirect -bg -max_cores 1 /dev/null {write -format verilog -hierarchy -output ${RESULTS_DIR}/${DCRM_FINAL_VERILOG_OUTPUT_FILE}}
    #write -format ddc -hierarchy -output ${RESULTS_DIR}/${DCRM_COMPILE_DDC_OUTPUT_FILE}
    exit
} else {
    if {[shell_is_in_topographical_mode]} {
        if {$syn_mode == 2} {
            compile_ultra -gate_clock -no_seq_output_inversion -spg -no_autoungroup
        } else {
            compile_ultra -gate_clock -no_seq_output_inversion -no_autoungroup
        }
    } else {
        if { $insert_dft_logic == 1 } {
            compile_ultra -scan -gate_clock -no_seq_output_inversion -no_autoungroup
        } else {
            compile_ultra -gate_clock -no_seq_output_inversion -no_autoungroup 
        }
    }
}

analyze_rtl_congestion -nosplit > ${REPORTS_DIR}/dc_congestion.rpt

#################################################################################
# Save Design after First Compile
#################################################################################
write -format ddc -hierarchy -output ${RESULTS_DIR}/${DCRM_COMPILE_DDC_OUTPUT_FILE}
write -hierarchy -format verilog -output ${RESULTS_DIR}/${DCRM_COMPILE_VERILOG_OUTPUT_FILE}

#############################################################################
# DFT Signal Type Definitions
#
# These are design-specific settings that should be modified.
# The following are only examples and should not be used.
#############################################################################

#############################################################################
# DFT for Clock Gating
#
# This section includes variables and commands used only when clock gating
# has been performed in the design.
#############################################################################

# Use the following command to initialize clock gating cells for test that are
# made transparent with a signal held constant for testing, e.g. of type 'Constant'.
# The value set depends on the hierarchy depth of the clock-gating cells.
# This setting is not needed where clock-gating cells are controlled with scan enable.

# set_dft_drc_configuration -clock_gating_init_cycles 1

# To specify a dedicated ScanEnable/TestMode signal to be used for clock gating,
# use the "-usage clock_gating" option of the "set_dft_signal" command

# set_dft_signal -view spec -type <ScanEnable|TestMode> -port <dedicated port> -usage clock_gating

# You can specify the clock-gating connectivity of the ScanEnable/TestMode signals
# after they are predefined with set_dft_signal -usage clock_gating

# set_dft_connect <LABEL> -type clock_gating_control -source <DFT signal> [-target ...]

#############################################################################
# DFT Configuration
#############################################################################

if { $insert_dft_logic == 1 } {
    # Preserve the design name when writing to the database during DFT insertion.
    set_dft_insertion_configuration -preserve_design_name true

    # Do not perform synthesis optimization during DFT insertion.
    set_dft_insertion_configuration -synthesis_optimization none

    # Multibit cell handling
    # Specify -preserve_multibit_segment to false to treat the cells inside a
    # multibit component as discrete sequential cells. This improves balancing
    # of scan chains.
    # Starting I-2013.12 release, the default setting is false
    # set_scan_configuration -preserve_multibit_segment false

    ## DFT Clock Mixing Specification
    # For a hierarchical flow, don't mix clocks at the block level:
    # set_scan_configuration -clock_mixing no_mix

    # For a top-down methodology clock mixing is recommended, if possible:
    set_scan_configuration -clock_mixing mix_clocks
}

#############################################################################
# DFT AutoFix Configuration
#############################################################################

# Please refer to the DFT Compiler, DFTMAX, and DFTMAX Ultra User Guide, Chapter 12,
# "Advanced DFT Architecture Methodologies", "Using AutoFix" section.

# Please refer to the dc.dft_autofix_config.tcl file included with the
# Design Compiler Reference Methodology scripts for an example of a
# design-specific AutoFix configuration.

# Create a design-specific Autofix configuration file and uncomment the
# following line to source this file.

# source -echo -verbose ${DCRM_DFT_AUTOFIX_CONFIG_INPUT_FILE}

#############################################################################
# DFTMAX Ultra Compression Configuration
#############################################################################

# Comment out the following command or change the option to "-streaming_compression disable"
# to disable DFTMAX Ultra Compression during DFT insertion.

#set_dft_configuration -streaming_compression enable

 # DFTMAX Ultra Compression Options:
 #
 # You must use the set_streaming_compression_configuration command to specify
 # the streaming compression configuration.
 #
 # You must specify either -chain_count or -max_length to architect the
 # streaming codec.  If you specify both, -max_length takes precedence over
 # "-chain_count".
 #
 # -chain_count <l>
 #     Where <l> is the number of compressed scan chains
 #
 # -max_length <m>
 #     Where <m> is the maximum allowed length of streaming compression mode chains
 #
 # You should also specify -inputs and -outputs for the streaming codec
 #
 # -inputs <n>
 #     Where <n> is the number of scan data inputs used to drive the decompressor
 #
 # -outputs <o>
 #     Where <o> is the number of scan data onputs used to capture data from the compressor
 #
 #
 # The minimum compression ratio is 10. This is the ratio of number of scan chains
 # in compression mode to the number of scan inputs used in compression mode.
 #
 # If you are using an On-Chip Clock Controller with DFTMAX Ultra compression, the
 # clock control chain must be implemented as as an external clock chain. You should
 # allow for this extra chain in set_scan_configuration command.
 #
 # -clock <name>
 #    Specify the name of the clock to be used for the codec.
 #
 # If your design comtains multiple scan clocks, DFTMAX Ultra compression automatically chooses the dominant
 # scan clock for the codec clock. Use the -clock option to specify a partciular scan clock for the codec clock.
 # You can also use the -exclude_clocks option to prevent certain clocks from being used as the codec clock.
 #
 # For details on these and other DFTMAX Ultra compression options, please refer to the
 # DFT Compiler, DFTMAX, and DFTMAX Ultra User Guide, Chapter 25, "Using DFTMAX Ultra Compression".

 # set_streaming_compression_configuration -inputs <> -outputs <> -chain_count <>

 # DFTMAX Ultra automatically infers the intended flow based on your design. There
 # is no need to specify a Mixed Integration and Insertion (MII) flow or a Bottom
 # Up Integration (BUI) flow.

 # Use the following to define the test-mode signal to be used for DFTMAX Ultra
 # compression. Ensure that that test mode signals to be used for clockgating have
 # been configured with set_dft_signal -usage clock_gating.

 # set_dft_signal -view spec -type TestMode -port scan_compression_enable

 #############################################################################
 # DFT Pipelined Scan Data Configuration
 #############################################################################

# Use set_pipeline_scan_data_configuration to control how Pipelined Scan Data Registers
# should be inserted

# We recommend that you use the head_scan_flop true option to create head pipeline registers that
# hold their state during the capture cycle.
# You should also constrain ScanEnable to its inactive value during capture in ScanCompression modes

# Note: if you select the head_scan_flop true option, you can share the scan clock with the head_pipeline_clock.
#  If you do not select head_scan_flop true option, then you must use a dedicated head pipeline clock.

# Options:
#  -head_scan_flop true
#  -head_pipeline_clock  <name of clock for head pipeline registers>
#  -tail_pipeline_clock  <name of clock for tail pipeline registers>
#  -head_pipeline_stages <desired number of head pipeline stages>
#  -tail_pipeline_stages <desired number of tail pipeline stages>

# Example:

# set_pipeline_scan_data_configuration -head_pipeline_clock <clock_name> \
#   -tail_pipeline_clock <clock_name> \
#   -head_scan_flop true \
#   -head_pipeline_stages <x> \
#   -tail_pipeline_stages <y>
#############################################################################
# DFT Additional Setup
#############################################################################

# Add any additional design-specific DFT constraints here

#############################################################################
# Defining Multiple Test modes
#############################################################################

# Use the define_test_mode command to define additional test modes that you wish to build.
#
# If you have enabled DFTMAX or DFTMAX Ultra Compression, the tool will build two test modes by
# default: ScanCompression_mode and Internal_scan.
#
# If you wish to override the default test modes, you need to define the purpose of that test mode,
# then use the -base_mode and -test_mode options of set_scan_compression_configuration or
# set_streaming_compression_configuration command to define the correspondence between the two modes.
#
# Design Compiler shell switches to that test mode after a define_test_mode command.
#
# To define DFT signals or scan configuration for a particular test mode, specify -test_mode option
# for each modes that you have defined.
#
# At top level, use define_test_mode -target to specify the block level test mode that should be active in
# that mode. Please refer to the DFT Compiler, DFTMAX, and DFTMAX Ultra User Guide Chapter 25,
# "Using DFTMAX Ultra Compression", "DFTMAX Ultra Compression and Multiple Test Modes" section.
#
# Block level Example with DFTMAX Ultra Compression:
# Defining the test modes at block level
# define_test_mode MY_internal_scan -usage scan
# define_test_mode MY_streaming_compression -usage streaming_compression
#
# Specifying the DFT signals for each mode using the -test_mode option:
# set_dft_signal -port scan_input_port_1  -type ScanDataIn  -view spec -test_mode MY_internal_scan
# set_dft_signal -port scan_input_port_1  -type ScanDataIn  -view spec -test_mode MY_streaming_compression
# set_dft_signal -port scan_output_port_1 -type ScanDataOut -view spec -test_mode MY_internal_scan
# set_dft_signal -port scan_output_port_1 -type ScanDataOut -view spec -test_mode MY_streaming_compression
#
# Specifying the scan configuration for each test mode:
# set_scan_configuration -chain_count <scan mode chain count> -test_mode MY_internal_scan
# set_scan_configuration -chain_count <compression mode chain count> -test_mode MY_streaming_compression
#
# Specify the correspondence between user-defined internal scan mode and user-defined compression mode
# set_streaming_compression_configuration -chain_count <compression mode chain count>  \
#                                         -base_mode MY_internal_scan -test_mode MY_streaming_compression
#
# Top level example with DFTMAX Ultra Compression:
# define_test_mode MY_top_streaming_compression -usage streaming_compression \
#   -target [list core1:MY_streaming_compression core2:MY_streaming_compression top]
#
###########################################################################
# Defining DFT partitions
###########################################################################
# Use the define_dft_partition command to define a set of clock domains, design references,
# hierarchical cells, or sequential leaf cells that you can specify scan and compression configuration.
# Then use the current_dft_partition command to set the current partition, then apply one or more
# supported test configuration commands to configure scan for that partition.
# Define any partition specific DFT signals in this section.
#
# Be sure to define any global scan and compression configuration and signals before define_dft_partition command.
#
# Please refer to the DFT Compiler, DFTMAX, and DFTMAX Ultra User Guide, Chapter 18,
# "Using DFTMAX Compression", "Top-Down Flat Compressed Scan Flow with Partitions" section.
#
# define_dft_partition <partition_1>       \
#   -include <list_of_cells_or_references> \
#   -clocks  <list of_clocks>
#
# define_dft_partition <partition_2>       \
#   -include <list_of_cells_or_references> \
#   -clocks  <list of_clocks>
#
# current_dft_partition <partition_1>
# <Scan and Compression configuration for partition_1>
# If you have defined multiple test modes, you must use -test_mode option when defining DFT signals.
# <DFT signals specific to partition_1>
#
# current_dft_partition <partition_2>
# <Scan and Compression configuration for partition_2>
# If you have defined multiple test modes, you must use -test_mode option when defining DFT signals.
# <DFT signals specific to partition_2>

#############################################################################
# DFT Test Protocol Creation
#############################################################################

if { $insert_dft_logic == 1 } {
    create_test_protocol

    #############################################################################
    # DFT Insertion
    #############################################################################
    # Use the -verbose version of dft_drc to assist in debugging if necessary

    dft_drc
    dft_drc -verbose                           > ${REPORTS_DIR}/${DCRM_DFT_DRC_CONFIGURED_VERBOSE_REPORT}
    report_scan_configuration                  > ${REPORTS_DIR}/${DCRM_DFT_SCAN_CONFIGURATION_REPORT}
    report_streaming_compression_configuration > ${REPORTS_DIR}/${DCRM_DFT_COMPRESSION_CONFIGURATION_REPORT}
    report_dft_insertion_configuration         > ${REPORTS_DIR}/${DCRM_DFT_PREVIEW_CONFIGURATION_REPORT}

    # Use the -show all version to preview_dft for more detailed report
    preview_dft                                > ${REPORTS_DIR}/${DCRM_DFT_PREVIEW_DFT_SUMMARY_REPORT}
    preview_dft -show all -test_points all     > ${REPORTS_DIR}/${DCRM_DFT_PREVIEW_DFT_ALL_REPORT}

    ########
    # Visualizing DFTMAX Ultra architecture
    #
    # Use the streaming_dft_planner command to visualize the currently configured DFTMAX Ultra architecture.
    #
    # Refer to the DFT Compiler, DFTMAX and DFTMAX Ultra User Guide, "Planning the Streaming DFT Architecture" section for more details.
    #
    ########

    streaming_dft_planner

    insert_dft
}

#############################################################################
# Re-create Default Path Groups
#
# In case of ports being created during insert_dft they need to be added
# to those path groups.
# Separating these paths can help improve optimization.
#############################################################################

source -echo -verbose $env(SYN_ROOT)/run_tcl/create_path_groups.tcl

if { $report_timing_for_init_comp == 1 } {
    parallel_execute [list \
        "report_timing -transition_time -nets -attributes -delay max -input_pins -max_paths 10 > ${REPORTS_DIR}/${DCRM_INIT_COMP_TIMING_REPORT}" \
        "report_timing -transition_time -nets -attributes -group in2out    -max_paths 2000 > ${REPORTS_DIR}/${DCRM_INIT_COMP_IN2OUT_TIMING_REPORT}" \
        "report_timing -transition_time -nets -attributes -group in2reg    -max_paths 2000 > ${REPORTS_DIR}/${DCRM_INIT_COMP_IN2REG_TIMING_REPORT}" \
        "report_timing -transition_time -nets -attributes -group reg2out   -max_paths 2000 > ${REPORTS_DIR}/${DCRM_INIT_COMP_REG2OUT_TIMING_REPORT}" \
        "report_timing -transition_time -nets -attributes -group reg2reg   -max_paths 2000 > ${REPORTS_DIR}/${DCRM_INIT_COMP_REG2REG_TIMING_REPORT}"]
    
    if { [sizeof_collection [all_registers -level_sensitive]] > 0 } {
        parallel_execute [list \
        "report_timing -transition_time -nets -attributes -group reg2latch -max_paths 2000 > ${REPORTS_DIR}/${DCRM_INIT_COMP_REG2LATCH_TIMING_REPORT}" \
        "report_timing -transition_time -nets -attributes -group in2latch  -max_paths 2000 > ${REPORTS_DIR}/${DCRM_INIT_COMP_IN2LATCH_TIMING_REPORT}" \
        "report_timing -transition_time -nets -attributes -group latch2reg -max_paths 2000 > ${REPORTS_DIR}/${DCRM_INIT_COMP_LATCH2REG_TIMING_REPORT}"]
    }

    if { $has_cg_cell == 1 } {
        report_timing -transition_time -nets -attributes -group reg2cg_en -max_paths 2000 > ${REPORTS_DIR}/${DCRM_INIT_COMP_REG2CG_EN_TIMING_REPORT}
    }

    if { $syn_with_sram == 1 } {
        report_timing -transition_time -nets -attributes -group reg2ram -max_paths 2000 > ${REPORTS_DIR}/${DCRM_INIT_COMP_REG2RAM_TIMING_REPORT}
        report_timing -transition_time -nets -attributes -group ram2reg -max_paths 2000 > ${REPORTS_DIR}/${DCRM_INIT_COMP_RAM2REG_TIMING_REPORT}
    }
}

#################################################################################
# DFT Incremental Compile
# Only required if scan chain insertion has been performed.
#################################################################################

# create_auto_path_groups -mode mapped

if {[file exists [which $user_path_groups_file]]} {
    source -echo -verbose $user_path_groups_file
}

if {[shell_is_in_topographical_mode]} {
    if { $insert_dft_logic == 1 } {
        compile_ultra -incremental -scan -gate_clock -no_seq_output_inversion -no_autoungroup
    } else {
        compile_ultra -incremental -gate_clock -no_seq_output_inversion -no_autoungroup
    }
} else {
    if {$syn_mode == 2} {
        compile_ultra -incremental -gate_clock -no_seq_output_inversion -spg -no_autoungroup
    } else {
        compile_ultra -incremental -gate_clock -no_seq_output_inversion -no_autoungroup
    }
}

# remove_auto_path_groups

if {[info exists env(DC_POST_TCL)]} {
    puts "INFO: running $env(DC_POST_TCL)"
    source -echo -verbose $env(DC_POST_TCL)
}

#################################################################################
# insert isolation cells and level shifters
#################################################################################
if { $use_upf_flow == 1 } {
    redirect -bg -max_cores 1 ${REPORTS_DIR}/${DCRM_FINAL_POWER_CHECK_REPORT} {check_mv_design -verbose}
}

#################################################################################
# High-effort area optimization
#
# optimize_netlist -area command, was introduced in I-2013.12 release to improve
# area of gate-level netlists. The command performs monotonic gate-to-gate
# optimization on mapped designs, thus improving area without degrading timing or
# leakage.
#################################################################################
optimize_netlist -area -no_seq_output_inversion

#################################################################################
## this part is reserved for native eco embeded in synthesis flow
#################################################################################
#if { $use_upf_flow == 1 } {
#    if { $power_switch_eco_en == 1 } {
#        puts "INFO: loading $env(PSW_ECO_SCRIPT) to do power switch control signal ecos."
#        source -echo -verbose $env(PSW_ECO_SCRIPT)
#    }
#}

#################################################################################
# Write Out Final Design and Reports
#
#        .ddc:   Recommended binary format used for subsequent Design Compiler sessions
#    Milkyway:   Recommended binary format for IC Compiler
#        .v  :   Verilog netlist for ASCII flow (Formality, PrimeTime, VCS)
#       .spef:   Topographical mode parasitics for PrimeTime
#        .sdf:   SDF backannotated topographical mode timing for PrimeTime
#        .sdc:   SDC constraints for ASCII flow
#
#################################################################################
define_name_rules verilog -dont_change_bus_members
change_names -rules verilog -hierarchy

#############################################################################
# DFT Write out Test Protocols and Reports
#############################################################################

# write_scan_def adds SCANDEF information to the design database in memory, so
# this command must be performed prior to writing out the design database
# containing binary SCANDEF.

if { $insert_dft_logic == 1 } {
    write_scan_def -output ${RESULTS_DIR}/${DCRM_DFT_FINAL_SCANDEF_OUTPUT_FILE}
    check_scan_def > ${REPORTS_DIR}/${DCRM_DFT_FINAL_CHECK_SCAN_DEF_REPORT}
    write_test_model -format ctl -output ${RESULTS_DIR}/${DCRM_DFT_FINAL_CTL_OUTPUT_FILE}

    report_dft_signal > ${REPORTS_DIR}/${DCRM_DFT_FINAL_DFT_SIGNALS_REPORT}

    # DFT outputs for standard scan mode

    write_test_protocol -test_mode Internal_scan -output ${RESULTS_DIR}/${DCRM_DFT_FINAL_PROTOCOL_OUTPUT_FILE}
    current_test_mode Internal_scan
    report_scan_path > ${REPORTS_DIR}/${DCRM_DFT_FINAL_SCAN_PATH_REPORT}
    dft_drc
    dft_drc -verbose > ${REPORTS_DIR}/${DCRM_DFT_DRC_FINAL_REPORT}
}

# Write and close SVF file and make it available for immediate use
set_svf -off

# DFT outputs for compressed scan mode
# If you have defined you own test modes, change the name of the test mode from
# "ScanCompression_mode" to the one that you have specified using define_test_mode command.

#write_test_protocol -test_mode ScanCompression_mode -output ${RESULTS_DIR}/${DCRM_DFT_FINAL_SCAN_COMPR_PROTOCOL_OUTPUT_FILE}
#current_test_mode ScanCompression_mode
#report_scan_path > ${REPORTS_DIR}/${DCRM_DFT_FINAL_SCAN_COMPR_SCAN_PATH_REPORT}
#dft_drc
#dft_drc -verbose > ${REPORTS_DIR}/${DCRM_DFT_DRC_FINAL_SCAN_COMPR_REPORT}

#################################################################################
# Write out Design
# VO-12 means there are unmapped components such as GTECH libs, dc will stop
# and exit when there is any VO-12 message happened in verilog generation
#################################################################################
unsuppress_message {VO-12}
set_message_info -id VO-12 -stop_on
# if upf is used for synthesis, also write out netlist with pg pins for review
if { $use_upf_flow == 1 } {
    redirect -bg -max_cores 1 /dev/null {write -format verilog -hierarchy -pg -output ${RESULTS_DIR}/${DCRM_FINAL_PG_VERILOG_OUTPUT_FILE}}
    redirect -bg -max_cores 1 /dev/null {write -format verilog -hierarchy -output ${RESULTS_DIR}/${DCRM_FINAL_VERILOG_OUTPUT_FILE}}
    redirect -bg -max_cores 1 /dev/null {write -format ddc     -hierarchy -output ${RESULTS_DIR}/${DCRM_FINAL_DDC_OUTPUT_FILE}}
} else {
    redirect -bg -max_cores 1 /dev/null {write -format verilog -hierarchy -output ${RESULTS_DIR}/${DCRM_FINAL_VERILOG_OUTPUT_FILE}}
    redirect -bg -max_cores 1 /dev/null {write -format ddc     -hierarchy -output ${RESULTS_DIR}/${DCRM_FINAL_DDC_OUTPUT_FILE}}
}

#################################################################################
# Write out Design Data
#################################################################################

#TODO Write out spef file just for pt auto power analasys, delete it after topgun topo mode can run
write_parasitics -output ${RESULTS_DIR}/${DCRM_DCT_FINAL_SPEF_OUTPUT_FILE}

if {[shell_is_in_topographical_mode]} {
    # Note: A secondary floorplan file ${DCRM_DCT_FINAL_FLOORPLAN_OUTPUT_FILE}.objects
    #       might also be written to capture physical-only objects in the design.
    #       This file should be read in before reading the main floorplan file.
    write_floorplan -all ${RESULTS_DIR}/${DCRM_DCT_FINAL_FLOORPLAN_OUTPUT_FILE}

    # If the DCRM_DCT_SPG_PLACEMENT_OUTPUT_FILE variable has been set in dc_setup_filenames.tcl
    # file then the standard cell physical guidance is being created to support SPG ASCII hand-off
    # to IC Compiler by the write_def command.
    # Invoking write_def commands requires a Design Compiler Graphical license or an IC Compiler
    # Design Planning license.

    if {[info exists DCRM_DCT_SPG_PLACEMENT_OUTPUT_FILE]} {
        write_def -components -output ${RESULTS_DIR}/${DCRM_DCT_SPG_PLACEMENT_OUTPUT_FILE}
    }

    # Write parasitics data from Design Compiler Topographical placement for static timing analysis
    write_parasitics -output ${RESULTS_DIR}/${DCRM_DCT_FINAL_SPEF_OUTPUT_FILE}

    # Write SDF backannotation data from Design Compiler Topographical placement for static timing analysis
    write_sdf ${RESULTS_DIR}/${DCRM_DCT_FINAL_SDF_OUTPUT_FILE}

    # Do not write out net RC info into SDC
    set_app_var write_sdc_output_lumped_net_capacitance false
    set_app_var write_sdc_output_net_resistance false
}

redirect -bg -max_cores 1 /dev/null {write_sdc -nosplit ${RESULTS_DIR}/${DCRM_FINAL_SDC_OUTPUT_FILE}}

# If SAIF is used, write out SAIF name mapping file for PrimeTime-PX
saif_map -type ptpx -write_map ${RESULTS_DIR}/${DESIGN_NAME}.mapped.SAIF.namemap

#################################################################################
# Generate Final Reports
#################################################################################

current_design ${DESIGN_NAME}

redirect -bg -max_cores 1 ${REPORTS_DIR}/${DCRM_FINAL_QOR_REPORT} {report_qor}

# Create a QoR snapshot of timing, physical, constraints, clock, power data, and routing on
# active scenarios and stores it in the location  specified  by  the icc_snapshot_storage_location
# variable.

if {[shell_is_in_topographical_mode]} {
    set icc_snapshot_storage_location ${REPORTS_DIR}/${DCRM_DCT_FINAL_QOR_SNAPSHOT_FOLDER}
    create_qor_snapshot -name ${DCRM_DCT_FINAL_QOR_SNAPSHOT_REPORT} > ${REPORTS_DIR}/${DCRM_DCT_FINAL_QOR_SNAPSHOT_REPORT}
}

source -echo -verbose $env(SYN_ROOT)/run_tcl/create_path_groups.tcl

parallel_execute [list \
    "report_timing -transition_time -nets -attributes -delay max -input_pins -max_paths 10 > ${REPORTS_DIR}/${DCRM_FINAL_TIMING_REPORT}" \
    "report_timing -transition_time -nets -attributes -input_pins -group in2out    -max_paths 1000 > ${REPORTS_DIR}/${DCRM_FINAL_IN2OUT_TIMING_REPORT}" \
    "report_timing -transition_time -nets -attributes -input_pins -group in2reg    -max_paths 1000 > ${REPORTS_DIR}/${DCRM_FINAL_IN2REG_TIMING_REPORT}" \
    "report_timing -transition_time -nets -attributes -input_pins -group reg2out   -max_paths 1000 > ${REPORTS_DIR}/${DCRM_FINAL_REG2OUT_TIMING_REPORT}" \
    "report_timing -transition_time -nets -attributes -input_pins -group reg2reg   -max_paths 1000 > ${REPORTS_DIR}/${DCRM_FINAL_REG2REG_TIMING_REPORT}" \
    "report_timing -transition_time -nets -attributes -input_pins -group in2out    -max_paths 1000 -path_type end > ${REPORTS_DIR}/${DCRM_FINAL_IN2OUT_TIMING_SUM_REPORT}" \
    "report_timing -transition_time -nets -attributes -input_pins -group in2reg    -max_paths 1000 -path_type end > ${REPORTS_DIR}/${DCRM_FINAL_IN2REG_TIMING_SUM_REPORT}" \
    "report_timing -transition_time -nets -attributes -input_pins -group reg2out   -max_paths 1000 -path_type end > ${REPORTS_DIR}/${DCRM_FINAL_REG2OUT_TIMING_SUM_REPORT}" \
    "report_timing -transition_time -nets -attributes -input_pins -group reg2reg   -max_paths 1000 -path_type end > ${REPORTS_DIR}/${DCRM_FINAL_REG2REG_TIMING_SUM_REPORT}"]

if { [sizeof_collection [all_registers -level_sensitive]] > 0 } {
    parallel_execute [list \
    "report_timing -transition_time -nets -attributes -input_pins -group reg2latch -max_paths 1000 > ${REPORTS_DIR}/${DCRM_FINAL_REG2LATCH_TIMING_REPORT}" \
    "report_timing -transition_time -nets -attributes -input_pins -group in2latch  -max_paths 1000 > ${REPORTS_DIR}/${DCRM_FINAL_IN2LATCH_TIMING_REPORT}" \
    "report_timing -transition_time -nets -attributes -input_pins -group latch2reg -max_paths 1000 > ${REPORTS_DIR}/${DCRM_FINAL_LATCH2REG_TIMING_REPORT}" \
    "report_timing -transition_time -nets -attributes -input_pins -group reg2latch -max_paths 1000 -path_type end > ${REPORTS_DIR}/${DCRM_FINAL_REG2LATCH_TIMING_SUM_REPORT}" \
    "report_timing -transition_time -nets -attributes -input_pins -group in2latch  -max_paths 1000 -path_type end > ${REPORTS_DIR}/${DCRM_FINAL_IN2LATCH_TIMING_SUM_REPORT}" \
    "report_timing -transition_time -nets -attributes -input_pins -group latch2reg -max_paths 1000 -path_type end > ${REPORTS_DIR}/${DCRM_FINAL_LATCH2REG_TIMING_SUM_REPORT}"]
}

if { $has_cg_cell == 1 } {
    report_timing -transition_time -nets -attributes -input_pins -group reg2cg_en -max_paths 2000 > ${REPORTS_DIR}/${DCRM_FINAL_REG2CG_EN_TIMING_REPORT}
}

if { $syn_with_sram == 1 } {
    report_timing -transition_time -nets -attributes -input_pins -group reg2ram -max_paths 2000 > ${REPORTS_DIR}/${DCRM_FINAL_REG2RAM_TIMING_REPORT}
    report_timing -transition_time -nets -attributes -input_pins -group ram2reg -max_paths 2000 > ${REPORTS_DIR}/${DCRM_FINAL_RAM2REG_TIMING_REPORT}
}

if {[shell_is_in_topographical_mode]} {
    redirect -bg -max_cores 1 ${REPORTS_DIR}/${DCRM_FINAL_AREA_REPORT} {report_area -physical -hier}
} else {
    redirect -bg -max_cores 1 ${REPORTS_DIR}/${DCRM_FINAL_AREA_REPORT} {report_area -hier}
}

if {[shell_is_in_topographical_mode]} {
    # report_congestion (topographical mode only) uses zroute for estimating and reporting
    # routing related congestion which improves the congestion correlation with IC Compiler.
    # Design Compiler Topographical supports create_route_guide command to be consistent with IC
    # Compiler after topographical mode synthesis.
    # Those commands require a license for Design Compiler Graphical.
    report_congestion > ${REPORTS_DIR}/${DCRM_DCT_FINAL_CONGESTION_REPORT}
    # Use the following to generate and write out a congestion map from batch mode
    # This requires a GUI session to be temporarily opened and closed so a valid DISPLAY
    # must be set in your UNIX environment.
    if {[info exists env(DISPLAY)]} {
        gui_start

        # Create a layout window
        set MyLayout [gui_create_window -type LayoutWindow]

        # Build congestion map in case report_congestion was not previously run
        report_congestion -build_map

        # Display congestion map in layout window
        gui_show_map -map "Global Route Congestion" -show true

        # Zoom full to display complete floorplan
        gui_zoom -window [gui_get_current_window -view] -full

        # Write the congestion map out to an image file
        # You can specify the output image type with -format png | xpm | jpg | bmp

        # The following saves only the congestion map without the legends
        gui_write_window_image -format png -file ${REPORTS_DIR}/${DCRM_DCT_FINAL_CONGESTION_MAP_OUTPUT_FILE}

        # The following saves the entire congestion map layout window with the legends
        gui_write_window_image -window ${MyLayout} -format png -file ${REPORTS_DIR}/${DCRM_DCT_FINAL_CONGESTION_MAP_WINDOW_OUTPUT_FILE}

        gui_stop
    } else {
        puts "Information: The DISPLAY environment variable is not set. Congestion map generation has been skipped."
    }
}

identify_clock_gating

# Use SAIF file for power analysis
# read_saif -auto_map_names -input ${DESIGN_NAME}.saif -instance < DESIGN_INSTANCE > -verbose
redirect -bg -max_cores 1 ${REPORTS_DIR}/${DCRM_FINAL_POWER_REPORT} {report_power}

if { $use_upf_flow == 1 } {
    redirect -bg -max_cores 1 ${REPORTS_DIR}/${DCRM_FINAL_POWER_DOMAIN_REPORT} {report_power_domain -verbose -hierarchy}
    redirect -bg -max_cores 1 /dev/null {save_upf ${RESULTS_DIR}/${DCRM_FINAL_UPF_OUTPUT_FILE}}
}

parallel_execute [list \
    "report_clock_gating -ungated -multi_stage -verbose > ${REPORTS_DIR}/${DCRM_FINAL_CLOCK_GATING_REPORT}" \
    "report_constraint -verbose >  ${REPORTS_DIR}/${DCRM_ALL_VIOLATIONS_REPORT}" \
    "report_threshold_voltage_group > ${REPORTS_DIR}/threshold_voltage_group.rpt" \
    "check_timing > ${REPORTS_DIR}/check_timing_post_compile.rpt"]

# check all register clock pins clocks attribute
if { $check_clock_pins == 1 } {
    set xl_all_reg_ck_pins [get_pins -hierarchical -filter "clock == true"]
    redirect ${REPORTS_DIR}/register_clocks.rpt {puts "###############################################"}
    redirect -append ${REPORTS_DIR}/register_clocks.rpt {puts "## Log generated from dc.tcl. used to check"}
    redirect -append ${REPORTS_DIR}/register_clocks.rpt {puts "## all clocks to register CK pin"}
    redirect -append ${REPORTS_DIR}/register_clocks.rpt {puts "###############################################"}
    foreach_in_collection xl_reg $xl_all_reg_ck_pins {
        set xl_reg_name [get_attribute $xl_reg full_name]
        redirect -append ${REPORTS_DIR}/register_clocks.rpt {puts $xl_reg_name}
        set xl_clks [get_object_name [get_clocks [get_attribute $xl_reg clocks]]]
        redirect -append ${REPORTS_DIR}/register_clocks.rpt {puts "$xl_clks"}
    }
}

# Uncomment the next line if you include the -self_gating to the compile_ultra command
# to report the XOR Self Gating information.
# report_self_gating  > ${REPORTS_DIR}/${DCRM_FINAL_SELF_GATING_REPORT}

# Uncomment the next line to reports the number, area, and  percentage  of cells
# for each threshold voltage group in the design.
# report_threshold_voltage_group > ${REPORTS_DIR}/${DCRM_THRESHOLD_VOLTAGE_GROUP_REPORT}

#################################################################################
# Write out Milkyway Design for Top-Down Flow
#
# This should be the last step in the script
#################################################################################

if {[shell_is_in_topographical_mode]} {
    # write_milkyway uses mw_design_library variable from dc_setup.tcl
    write_milkyway -overwrite -output ${DCRM_FINAL_MW_CEL_NAME}
}

#################################################################################
# Dump out script execution time and memory for analysis
#################################################################################
report_script_runtime > ${REPORTS_DIR}/dc_runtime_summary.rpt

# open gui if START_GUI env is set to 1
if { $open_gui == 1 } {
    start_gui
}

exit
