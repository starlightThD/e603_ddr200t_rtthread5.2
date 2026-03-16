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

# Enable the support of via resistance for RC estimation to improve the timing
# correlation with IC Compiler
set_app_var spg_enable_via_resistance_support     true

set_app_var timing_enable_multiple_clocks_per_reg true

# suppress errors, those must be reviewed before final sign-off
set suppress_errors $ignore_errors
# suppress some info/warning from printing out to reduce log as well as improving runtime
suppress_message  {OPT-319 AUTOREAD-303 HDL-193 OPT-1056 VER-130 VO-12 TIM-179 UID-51}

#################################################################################
# Setup SAIF Name Mapping Database
#
# Include an RTL SAIF for better power optimization and analysis.
#
# saif_map should be issued prior to RTL elaboration to create a name mapping
# database for better annotation.
################################################################################

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
if {[info exists env(ECO_NETLIST_FILE)]} {
    echo "INFO: reading eco netlist file $env(ECO_NETLIST_FILE)"
    read_verilog $env(ECO_NETLIST_FILE)
} else {
    echo "WARNING: no eco netlist file specified."
    exit
}

link

current_design ${DESIGN_NAME}

if {[info exists env(ECO_SCRIPT)]} {
    echo "INFO: sourcing eco script $env(ECO_SCRIPT)"
    source -echo -verbose $env(ECO_SCRIPT)
} else {
    echo "FATAL: ECO_SCRIPT is not provided"
    exit
}

write -format verilog -hierarchy -output $env(POST_ECO_NETLIST)
