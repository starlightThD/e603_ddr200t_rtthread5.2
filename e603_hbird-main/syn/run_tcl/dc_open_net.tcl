source -echo -verbose $env(SYN_ROOT)/setup/dc_setup.tcl
source -echo -verbose $env(SYN_ROOT)/run_tcl/dc.common_proc.tcl

#################################################################################
# Design Compiler Reference Methodology Script for Top-Down Flow
# Script: dc.tcl
# Version: K-2015.06 (July 13, 2015)
# Copyright (C) 2007-2015 Synopsys, Inc. All rights reserved.
#################################################################################

# Design Compiler must be run in topographical mode for SPG flow support
# SPG also requires a license for Design Compiler Graphical
#if {![shell_is_in_topographical_mode]} {
#  puts "RM-Error: dc_shell must be run in topographical mode for SPG support."
#  exit 1
#}

#################################################################################
# Additional Variables
#
# Add any additional variables needed for your flow here.
#################################################################################

# Enable the support of via resistance for RC estimation to improve the timing
# correlation with IC Compiler

set_app_var spg_enable_via_resistance_support true

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

# For more information about facilitating formal verification in the flow, refer
# to the following SolvNet article:
# "Resolving Inconclusive and Hard Verifications in Design Compiler"
# https://solvnet.synopsys.com/retrieve/033140.html

# Define the verification setup file for Formality
#set_svf ${RESULTS_DIR}/${DCRM_SVF_OUTPUT_FILE}

#################################################################################
# Setup SAIF Name Mapping Database
#
# Include an RTL SAIF for better power optimization and analysis.
#
# saif_map should be issued prior to RTL elaboration to create a name mapping
# database for better annotation.
################################################################################

saif_map -start

#################################################################################
# Read in the RTL Design
#
# Read in the RTL source files or read in the elaborated design (.ddc).
#################################################################################

define_design_lib WORK -path ./$SYN_TAG/WORK

read_ddc ${RESULTS_DIR}/${DCRM_FINAL_DDC_OUTPUT_FILE}
current_design ${DESIGN_NAME}
