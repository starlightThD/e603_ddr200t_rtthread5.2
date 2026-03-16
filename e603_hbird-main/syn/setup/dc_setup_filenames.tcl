puts "RM-Info: Running script [info script]\n"

#################################################################################
# Design Compiler Reference Methodology Filenames Setup
# Script: dc_setup_filenames.tcl
# Version: K-2015.06 (July 13, 2015)
# Copyright (C) 2010-2015 Synopsys, Inc. All rights reserved.
#################################################################################

#################################################################################
# Use this file to customize the filenames used in the Design Compiler
# Reference Methodology scripts.  This file is designed to be sourced at the
# beginning of the dc_setup.tcl file after sourcing the common_setup.tcl file.
#
# Note that the variables presented in this file depend on the type of flow
# selected when generating the reference methodology files.
#
# Example.
#    If you set DFT flow as FALSE, you will not see DFT related filename
#    variables in this file.
#
# When reusing this file for different flows or newer release, ensure that
# all the required filename variables are defined.  One way to do this is
# to source the default dc_setup_filenames.tcl file and then override the
# default settings as needed for your design.
#
# The default values are backwards compatible with older
# Design Compiler Reference Methodology releases.
#
# Note: Care should be taken when modifying the names of output files
#       that are used in other scripts or tools.
#################################################################################

#################################################################################
# General Flow Files
#################################################################################
set RTL_FILELIST                                        $env(RTL_FILELIST)
set SYN_TAG                                             $env(SYN_TAG)

if { [info exists env(SAIF_FILE)] } {
    set SAIF_FILE                                       $env(SAIF_FILE)
} else {
    set SAIF_FILE                                       ""
}

if { [info exists env(FM_TAG)] } {
    set FM_TAG                                          $env(FM_TAG)
} else {
    set FM_TAG                                          fm_$SYN_TAG
}

if { [info exists env(PT_TAG)] } {
    set PT_TAG                                          $env(PT_TAG)
} else {
    set PT_TAG                                          pt_$SYN_TAG
}

if { [info exists env(VCLP_TAG)] } {
    set VCLP_TAG                                        $env(VCLP_TAG)
} else {
    set VCLP_TAG                                        vclp_$SYN_TAG
}

##########################
# Milkyway Library Names #
##########################

set DCRM_MW_LIBRARY_NAME                                $SYN_TAG/${DESIGN_NAME}_MWLIB
set DCRM_FINAL_MW_CEL_NAME                              ${DESIGN_NAME}_DCT

###############
# Input Files #
###############

set DCRM_SDC_INPUT_FILE                                 $env(SDC_FILE)
set DCRM_CONSTRAINTS_INPUT_FILE                         $SYN_TAG/constraints/${DESIGN_NAME}.constraints.tcl
set DCRM_IDEAL_NETWORK_CONS_TCL                         $SYN_TAG/constraints/ideal_network_cons.tcl
set DCRM_ASYNC_FIFO_CONS_TCL                            $SYN_TAG/constraints/async_fifo_cons.tcl

###########
# Reports #
###########
set REPORTS_DIR                                         $SYN_TAG/reports
set RESULTS_DIR                                         $SYN_TAG/results

set DCRM_CHECK_LIBRARY_REPORT                           ${DESIGN_NAME}.check_library.rpt

set DCRM_CONSISTENCY_CHECK_ENV_FILE                     ${DESIGN_NAME}.compile_ultra.env
set DCRM_CHECK_DESIGN_REPORT                            ${DESIGN_NAME}.check_design.rpt
set DCRM_ANALYZE_DATAPATH_EXTRACTION_REPORT             ${DESIGN_NAME}.analyze_datapath_extraction.rpt
set DCRM_ALL_VIOLATIONS_REPORT                          ${DESIGN_NAME}.all_violations.rpt

set DCRM_FINAL_QOR_REPORT                               ${DESIGN_NAME}.mapped.qor.rpt
set DCRM_FINAL_TIMING_REPORT                            ${DESIGN_NAME}.mapped.timing.rpt
set DCRM_FINAL_AREA_REPORT                              ${DESIGN_NAME}.mapped.area.rpt
set DCRM_FINAL_POWER_REPORT                             ${DESIGN_NAME}.mapped.power.rpt
set DCRM_FINAL_POWER_DOMAIN_REPORT                      ${DESIGN_NAME}.mapped.power_domain.rpt
set DCRM_FINAL_POWER_CHECK_REPORT                       ${DESIGN_NAME}.mapped.power_check.rpt
set DCRM_FINAL_MV_ANALYSIS_REPORT                       ${DESIGN_NAME}.mapped.mv_analysis.rpt
set DCRM_FINAL_CLOCK_GATING_REPORT                      ${DESIGN_NAME}.mapped.clock_gating.rpt
set DCRM_FINAL_CLOCK_GATING_STRUCTURE_REPORT            ${DESIGN_NAME}.mapped.clock_gating_structure.rpt
set DCRM_FINAL_SELF_GATING_REPORT                       ${DESIGN_NAME}.mapped.self_gating.rpt
set DCRM_THRESHOLD_VOLTAGE_GROUP_REPORT                 ${DESIGN_NAME}.mapped.threshold.voltage.group.rpt
set DCRM_INSTANTIATE_CLOCK_GATES_REPORT                 ${DESIGN_NAME}.instatiate_clock_gates.rpt

set DCRM_INIT_COMP_TIMING_REPORT                        ${DESIGN_NAME}.init_comp.mapped.timing.rpt
set DCRM_INIT_COMP_IN2OUT_TIMING_REPORT                 ${DESIGN_NAME}.init_comp.mapped.in2out_timing.rpt
set DCRM_INIT_COMP_IN2REG_TIMING_REPORT                 ${DESIGN_NAME}.init_comp.mapped.in2reg_timing.rpt
set DCRM_INIT_COMP_REG2OUT_TIMING_REPORT                ${DESIGN_NAME}.init_comp.mapped.reg2out_timing.rpt
set DCRM_INIT_COMP_REG2REG_TIMING_REPORT                ${DESIGN_NAME}.init_comp.mapped.reg2reg_timing.rpt
set DCRM_INIT_COMP_REG2LATCH_TIMING_REPORT              ${DESIGN_NAME}.init_comp.mapped.reg2latch_timing.rpt
set DCRM_INIT_COMP_REG2CG_EN_TIMING_REPORT              ${DESIGN_NAME}.init_comp.mapped.reg2cg_en_timing.rpt
set DCRM_INIT_COMP_REG2RAM_TIMING_REPORT                ${DESIGN_NAME}.init_comp.mapped.reg2ram_timing.rpt
set DCRM_INIT_COMP_RAM2REG_TIMING_REPORT                ${DESIGN_NAME}.init_comp.mapped.ram2reg_timing.rpt
set DCRM_INIT_COMP_IN2LATCH_TIMING_REPORT               ${DESIGN_NAME}.init_comp.mapped.in2latch_timing.rpt
set DCRM_INIT_COMP_LATCH2REG_TIMING_REPORT              ${DESIGN_NAME}.init_comp.mapped.latch2reg_timing.rpt

set DCRM_FINAL_IN2OUT_TIMING_REPORT                     ${DESIGN_NAME}.mapped.in2out_timing.rpt
set DCRM_FINAL_IN2REG_TIMING_REPORT                     ${DESIGN_NAME}.mapped.in2reg_timing.rpt
set DCRM_FINAL_REG2OUT_TIMING_REPORT                    ${DESIGN_NAME}.mapped.reg2out_timing.rpt
set DCRM_FINAL_REG2REG_TIMING_REPORT                    ${DESIGN_NAME}.mapped.reg2reg_timing.rpt
set DCRM_FINAL_REG2LATCH_TIMING_REPORT                  ${DESIGN_NAME}.mapped.reg2latch_timing.rpt
set DCRM_FINAL_REG2CG_EN_TIMING_REPORT                  ${DESIGN_NAME}.mapped.reg2cg_en_timing.rpt
set DCRM_FINAL_REG2RAM_TIMING_REPORT                    ${DESIGN_NAME}.mapped.reg2ram_timing.rpt
set DCRM_FINAL_RAM2REG_TIMING_REPORT                    ${DESIGN_NAME}.mapped.ram2reg_timing.rpt
set DCRM_FINAL_IN2LATCH_TIMING_REPORT                   ${DESIGN_NAME}.mapped.in2latch_timing.rpt
set DCRM_FINAL_LATCH2REG_TIMING_REPORT                  ${DESIGN_NAME}.mapped.latch2reg_timing.rpt

set DCRM_FINAL_IN2OUT_TIMING_SUM_REPORT                 ${DESIGN_NAME}.mapped.in2out_timing_summary.rpt
set DCRM_FINAL_IN2REG_TIMING_SUM_REPORT                 ${DESIGN_NAME}.mapped.in2reg_timing_summary.rpt
set DCRM_FINAL_REG2OUT_TIMING_SUM_REPORT                ${DESIGN_NAME}.mapped.reg2out_timing_summary.rpt
set DCRM_FINAL_REG2REG_TIMING_SUM_REPORT                ${DESIGN_NAME}.mapped.reg2reg_timing_summary.rpt
set DCRM_FINAL_REG2LATCH_TIMING_SUM_REPORT              ${DESIGN_NAME}.mapped.reg2latch_timing_summary.rpt
set DCRM_FINAL_REG2CG_EN_TIMING_SUM_REPORT              ${DESIGN_NAME}.mapped.reg2cg_en_timing_summary.rpt
set DCRM_FINAL_REG2RAM_TIMING_SUM_REPORT                ${DESIGN_NAME}.mapped.reg2ram_timing_summary.rpt
set DCRM_FINAL_RAM2REG_TIMING_SUM_REPORT                ${DESIGN_NAME}.mapped.ram2reg_timing_summary.rpt
set DCRM_FINAL_IN2LATCH_TIMING_SUM_REPORT               ${DESIGN_NAME}.mapped.in2latch_timing_summary.rpt
set DCRM_FINAL_LATCH2REG_TIMING_SUM_REPORT              ${DESIGN_NAME}.mapped.latch2reg_timing_summary.rpt
################
# Output Files #
################

set DCRM_AUTOREAD_RTL_SCRIPT                            ${DESIGN_NAME}.autoread_rtl.tcl
set DCRM_ELABORATED_DESIGN_DDC_OUTPUT_FILE              ${DESIGN_NAME}.elab.ddc
set DCRM_GTECH_VERILOG_OUTPUT_FILE                      ${DESIGN_NAME}.gtech.v
set DCRM_COMPILE_VERILOG_OUTPUT_FILE                    ${DESIGN_NAME}.compile.v
set DCRM_COMPILE_DDC_OUTPUT_FILE                        ${DESIGN_NAME}.compile.ddc
set DCRM_FINAL_DDC_OUTPUT_FILE                          ${DESIGN_NAME}.mapped.ddc
set DCRM_FINAL_PG_VERILOG_OUTPUT_FILE                   ${DESIGN_NAME}.mapped.pg.v
set DCRM_FINAL_VERILOG_OUTPUT_FILE                      ${DESIGN_NAME}.mapped.v
set DCRM_FINAL_SDC_OUTPUT_FILE                          ${DESIGN_NAME}.mapped.sdc

#################################################################################
# DCT Flow Files
#################################################################################

###################
# DCT Input Files #
###################

if {[info exist env(DEF_INPUT_FILE)]} {
set DCRM_DCT_DEF_INPUT_FILE                             $env(DEF_INPUT_FILE)
} else {
set DCRM_DCT_DEF_INPUT_FILE                             ""
}
if {[info exist env(DCRM_DCT_FLOORPLAN_INPUT_FILE)]} {
set DCRM_DCT_FLOORPLAN_INPUT_FILE                       $env(FLOORPLAN_INPUT_FILE)
} else {
set DCRM_DCT_FLOORPLAN_INPUT_FILE                       ""
}
if {[info exist env(DCRM_DCT_PHYSICAL_CONSTRAINTS_INPUT_FILE)]} {
set DCRM_DCT_PHYSICAL_CONSTRAINTS_INPUT_FILE            $env(PHYSICAL_CONSTRAINTS_INPUT_FILE)
} else {
set DCRM_DCT_PHYSICAL_CONSTRAINTS_INPUT_FILE            ""
}

###############
# DCT Reports #
###############

set DCRM_DCT_PHYSICAL_CONSTRAINTS_REPORT                ${DESIGN_NAME}.physical_constraints.rpt

set DCRM_DCT_FINAL_CONGESTION_REPORT                    ${DESIGN_NAME}.mapped.congestion.rpt
set DCRM_DCT_FINAL_CONGESTION_MAP_OUTPUT_FILE           ${DESIGN_NAME}.mapped.congestion_map.png
set DCRM_DCT_FINAL_CONGESTION_MAP_WINDOW_OUTPUT_FILE    ${DESIGN_NAME}.mapped.congestion_map_window.png

set DCRM_DCT_FINAL_QOR_SNAPSHOT_FOLDER                  ${DESIGN_NAME}.qor_snapshot
set DCRM_DCT_FINAL_QOR_SNAPSHOT_REPORT                  ${DESIGN_NAME}.qor_snapshot.rpt

####################
# UPF Files #
####################
set DCRM_FINAL_UPF_OUTPUT_FILE                          ${DESIGN_NAME}.dc.upf
set DCRM_FINAL_UPF_OUTPUT_SUP_FILE                      ${DESIGN_NAME}.dc_supplyment.upf

####################
# DCT Output Files #
####################

set DCRM_DCT_FLOORPLAN_OUTPUT_FILE                      ${DESIGN_NAME}.initial.fp

set DCRM_DCT_FINAL_FLOORPLAN_OUTPUT_FILE                ${DESIGN_NAME}.mapped.fp
set DCRM_DCT_FINAL_SPEF_OUTPUT_FILE                     ${DESIGN_NAME}.mapped.spef
set DCRM_DCT_FINAL_SDF_OUTPUT_FILE                      ${DESIGN_NAME}.mapped.sdf

# Uncomment the DCRM_DCT_SPG_PLACEMENT_OUTPUT_FILE variable setting to save the
# standard cell placement for physical guidance flow when ASCII hand-off to IC Compiler
# is used.

set DCRM_DCT_SPG_PLACEMENT_OUTPUT_FILE                  ${DESIGN_NAME}.mapped.std_cell.def

#################################################################################
# DFT Flow Files
#################################################################################

###################
# DFT Input Files #
###################

set DCRM_DFT_SIGNAL_SETUP_INPUT_FILE                    ${DESIGN_NAME}.dft_signal_defs.tcl
set DCRM_DFT_AUTOFIX_CONFIG_INPUT_FILE                  ${DESIGN_NAME}.dft_autofix_config.tcl

###############
# DFT Reports #
###############

set DCRM_DFT_DRC_CONFIGURED_VERBOSE_REPORT              ${DESIGN_NAME}.dft_drc_configured.rpt
set DCRM_DFT_SCAN_CONFIGURATION_REPORT                  ${DESIGN_NAME}.scan_config.rpt
set DCRM_DFT_COMPRESSION_CONFIGURATION_REPORT           ${DESIGN_NAME}.compression_config.rpt
set DCRM_DFT_PREVIEW_CONFIGURATION_REPORT               ${DESIGN_NAME}.report_dft_insertion_config.preview_dft.rpt
set DCRM_DFT_PREVIEW_DFT_SUMMARY_REPORT                 ${DESIGN_NAME}.preview_dft_summary.rpt
set DCRM_DFT_PREVIEW_DFT_ALL_REPORT                     ${DESIGN_NAME}.preview_dft.rpt

set DCRM_DFT_FINAL_SCAN_PATH_REPORT                     ${DESIGN_NAME}.mapped.scanpath.rpt
set DCRM_DFT_DRC_FINAL_REPORT                           ${DESIGN_NAME}.mapped.dft_drc_inserted.rpt
set DCRM_DFT_FINAL_SCAN_COMPR_SCAN_PATH_REPORT          ${DESIGN_NAME}.mapped.scanpath.scan_compression.rpt
set DCRM_DFT_DRC_FINAL_SCAN_COMPR_REPORT                ${DESIGN_NAME}.mapped.dft_drc_inserted.scan_compression.rpt
set DCRM_DFT_FINAL_CHECK_SCAN_DEF_REPORT                ${DESIGN_NAME}.mapped.check_scan_def.rpt
set DCRM_DFT_FINAL_DFT_SIGNALS_REPORT                   ${DESIGN_NAME}.mapped.dft_signals.rpt

####################
# DFT Output Files #
####################

set DCRM_DFT_FINAL_SCANDEF_OUTPUT_FILE                  ${DESIGN_NAME}.mapped.scandef
set DCRM_DFT_FINAL_EXPANDED_SCANDEF_OUTPUT_FILE         ${DESIGN_NAME}.mapped.expanded.scandef
set DCRM_DFT_FINAL_CTL_OUTPUT_FILE                      ${DESIGN_NAME}.mapped.ctl
set DCRM_DFT_FINAL_PROTOCOL_OUTPUT_FILE                 ${DESIGN_NAME}.mapped.scan.spf
set DCRM_DFT_FINAL_SCAN_COMPR_PROTOCOL_OUTPUT_FILE      ${DESIGN_NAME}.mapped.scancompress.spf


set MVRCRM_RTL_READ_SCRIPT                              ${DESIGN_NAME}.MVRC.read_design.tcl
set VCLPRM_RTL_READ_SCRIPT                              ${DESIGN_NAME}.VCLP.read_design.tcl

#################################################################################
# Formality Flow Files
#################################################################################
set FM_REPORTS_DIR                                      $FM_TAG/reports
set FM_RESULTS_DIR                                      $FM_TAG/results

set DCRM_SVF_OUTPUT_FILE                                ${DESIGN_NAME}.mapped.svf

set FMRM_UNMATCHED_POINTS_REPORT                        ${DESIGN_NAME}.fmv_unmatched_points.rpt

set FMRM_FAILING_SESSION_NAME                           ${DESIGN_NAME}
set FMRM_FAILING_POINTS_REPORT                          ${DESIGN_NAME}.fmv_failing_points.rpt
set FMRM_ABORTED_POINTS_REPORT                          ${DESIGN_NAME}.fmv_aborted_points.rpt
set FMRM_ANALYZE_POINTS_REPORT                          ${DESIGN_NAME}.fmv_analyze_points.rpt

#################################################################################
# VC-LP Flow Files
#################################################################################
set VCLP_REPORTS_DIR                                    $VCLP_TAG/reports
set VCLP_RESULTS_DIR                                    $VCLP_TAG/results

#################################################################################
# PT Flow Files
#################################################################################
set PT_REPORTS_DIR                                      $PT_TAG/reports
set PT_RESULTS_DIR                                      $PT_TAG/results

puts "RM-Info: Completed script [info script]\n"
