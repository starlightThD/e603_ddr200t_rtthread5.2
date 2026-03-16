source -echo -verbose $env(SYN_ROOT)/setup/common_setup.tcl
source -echo -verbose $env(SYN_ROOT)/setup/dc_setup_filenames.tcl

puts "RM-Info: Running script [info script]\n"

#################################################################################
# Design Compiler Reference Methodology Setup for Top-Down Flow
# Script: dc_setup.tcl
# Version: K-2015.06 (July 13, 2015)
# Copyright (C) 2007-2015 Synopsys, Inc. All rights reserved.
#################################################################################

#################################################################################
# Setup Variables
#
# Modify settings in this section to customize your Design Compiler Reference
# Methodology run.
# Portions of dc_setup.tcl may be used by other tools so program name checks
# are performed where necessary.
#################################################################################

# The following setting removes new variable info messages from the end of the log file
set_app_var sh_new_variable_message false

if {$synopsys_program_name == "dc_shell"}  {
    #################################################################################
    # Design Compiler Setup Variables
    #################################################################################
    # Use the set_host_options command to enable multicore optimization to improve runtime.
    set_host_options -max_cores 8
    report_host_options

    # Change alib_library_analysis_path to point to a central cache of analyzed libraries
    # to save runtime and disk space.  The following setting only reflects the
    # default value and should be changed to a central location for best results.
    set_app_var alib_library_analysis_path ./$SYN_TAG
}

# get the list of source RTL files from rtl filelist
if {[info exists env(TOT)]} {
    set TOT $env(TOT)
} else {
    set TOT ".."
}
proc xl_expand_vars {origin_txt} {
    global TOT
    global PROJ_SRC_ROOT
    global PROJ_NAME
    set new_txt {}
    foreach xl_txt $origin_txt {
        set new_txt [concat $new_txt [subst $xl_txt]]
    }
    return $new_txt
}
set RTL_SOURCE_FILES [xl_expand_vars [exec cat $RTL_FILELIST]]

if {$synopsys_program_name == "fm_shell"} {

    set open_gui $env(START_GUI)

    set_app_var search_path ". $ADDITIONAL_SEARCH_PATH $search_path $env(INC_DIRS) $env(ALL_OTHER_STD_LIB_PATHS)"
    file mkdir ${FM_REPORTS_DIR}
    file mkdir ${FM_RESULTS_DIR}
}

# setup vclp libraries app var
if {$synopsys_program_name == "vcst"} {

    set open_gui $env(START_GUI)

    file mkdir ${VCLP_REPORTS_DIR}
    file mkdir ${VCLP_RESULTS_DIR}
    set search_path "$env(DC_HOME)/libraries/syn $env(DC_HOME)/dw/syn_ver"

    set search_path ". $ADDITIONAL_SEARCH_PATH $search_path $env(INC_DIRS)"
    set synthetic_library dw_foundation.sldb
    set target_library    ${TARGET_LIBRARY_FILES}
    set link_library      "$target_library $ADDITIONAL_LINK_LIB_FILES $synthetic_library"
}

# setup for primetime
if {$synopsys_program_name == "pt_shell"} {

    file mkdir ${PT_REPORTS_DIR}
    file mkdir ${PT_RESULTS_DIR}

    set search_path       ". $ADDITIONAL_SEARCH_PATH $search_path $env(INC_DIRS) $env(ALL_OTHER_STD_LIB_PATHS)"
    set target_library    ${TARGET_LIBRARY_FILES}

    set link_names $env(ALL_OTHER_STD_LIB_NAMES)
    set ALL_OTHER_STD_LIB_FILES {}
    foreach lib $link_names {
    lappend  ALL_OTHER_STD_LIB_FILES ${lib}
    }

    set link_path         "* $target_library $ADDITIONAL_LINK_LIB_FILES $ALL_OTHER_STD_LIB_FILES"

    set pvt_corner        $env(CORNER)
    # set operating mode: dft or func
    set work_mode         $env(WORK_MODE)

    set_host_options -max_cores 8

    ## upf low-power flow or not
    if [info exist env(UPF_EN)] {
        set low_power_tcl $env(LOW_POWER_TCL)
    }
}

# The remainder of the setup below should only be performed in Design Compiler
if {$synopsys_program_name == "dc_shell"} {
    set_app_var search_path ". $ADDITIONAL_SEARCH_PATH $search_path $env(INC_DIRS) $env(ALL_OTHER_STD_LIB_PATHS)"

    set mw_reference_library ${MW_REFERENCE_LIB_DIRS}
    if {$syn_with_sram == 1} {
        append mw_reference_library " " $sram_mw_libs
    }
    if {$has_extra_db == 1 && $extra_mw_dirs != ""} {
        append mw_reference_library " " $extra_mw_dirs
    }
    if {[info exists env(SYN_MODE)]} {
        set syn_mode $env(SYN_MODE)
    } else {
        set syn_mode 1
    }
    set mw_design_library    ${DCRM_MW_LIBRARY_NAME}
    set mw_site_name_mapping { {CORE unit} {Core unit} {core unit} }

    set corner            $env(CORNER)
    # set operating mode: dft or func
    set work_mode         $env(WORK_MODE)
    # set operating conditions
    set oper_cond         $env(OPER_COND)

    file mkdir ${REPORTS_DIR}
    file mkdir ${RESULTS_DIR}

    set_app_var target_library    ${TARGET_LIBRARY_FILES}
    set link_names $env(ALL_OTHER_STD_LIB_NAMES)
    set ALL_OTHER_STD_LIB_FILES {}
    foreach lib $link_names {
    lappend  ALL_OTHER_STD_LIB_FILES ${lib}
    }

    set_app_var synthetic_library dw_foundation.sldb
    set_app_var link_library      "* $target_library $ADDITIONAL_LINK_LIB_FILES $synthetic_library $ALL_OTHER_STD_LIB_FILES"

    # Set min libraries if they exist
    foreach {max_library min_library} $MIN_LIBRARY_FILES {
        set_min_library $max_library -min_version $min_library
    }

    # dump out case_analysis log to below log file

    # Set the variable to use Verilog libraries for Test Design Rule Checking
    # (See dc.tcl for details)
    # set_app_var test_simulation_library <list of Verilog library files>
    if {[shell_is_in_topographical_mode]} {

        puts "===========================================================\n"
        puts "          NOTE: DC is in topographical mode\n"
        puts "===========================================================\n"

        if {[info exists env(EXTEND_MW_LAYER)]} {
            if {$env(EXTEND_MW_LAYER) == 1} {
                extend_mw_layers
            }
        }

        # To activate the extended layer mode to support 4095 layers uncomment the extend_mw_layers command
        # before creating the Milkyway library. The extended layer mode is permanent and cannot be reverted
        # back to the 255 layer mode once activated.
        # extend_mw_layers

        # Only create new Milkyway design library if it doesn't already exist
        if {![file isdirectory $mw_design_library]} {
            create_mw_lib   -technology $TECH_FILE \
                            -mw_reference_library $mw_reference_library \
                            $mw_design_library
        } else {
          # If Milkyway design library already exists, ensure that it is consistent with specified Milkyway reference libraries
            set_mw_lib_reference $mw_design_library -mw_reference_library $mw_reference_library
        }

        open_mw_lib     $mw_design_library

        check_library > ${REPORTS_DIR}/${DCRM_CHECK_LIBRARY_REPORT}

        set_tlu_plus_files -max_tluplus $TLUPLUS_MAX_FILE \
                           -min_tluplus $TLUPLUS_MIN_FILE \
                           -tech2itf_map $MAP_FILE

        check_tlu_plus_files
    } else {
        puts "===========================================================\n"
        puts "          NOTE: DC is in wire load mode\n"
        puts "===========================================================\n"
    }

    # set map_only to cell list from config
    if [info exist env(MAP_ONLY_CELLS)] {
        set has_map_only_cells 1
        set MAP_ONLY_CELLS  $env(MAP_ONLY_CELLS)
    } else {
        set has_map_only_cells 0
    }

    # set ungroup_cells used to flatten
    if [info exist env(UNGROUP_CELLS)] {
        set has_ungroup_cells 1
        set xl_ungroup_cells  $env(UNGROUP_CELLS)
    } else {
        set has_ungroup_cells 0
    }

    # set_ungroup false to some specified cells
    if [info exist env(DONT_UNGROUP_CELLS)] {
        set has_dont_ungroup_cells 1
        set dont_ungroup_cells $env(DONT_UNGROUP_CELLS)
    } else {
        set has_dont_ungroup_cells 0
    }

    ## flatten the design or not in synthesis
    if [info exist env(SYN_FLATTEN)] {
        set syn_flatten $env(SYN_FLATTEN)
    } else {
        set syn_flatten 0
    }

    ## dft tool
    if [info exist env(DFT_TOOL)] {
        set dft_tool $env(DFT_TOOL)
    } else {
        set dft_tool ""
    }

    ## report timing after initial compile and before incremental compile
    if [info exist env(REPORT_TIMING_FOR_INIT_COMP)] {
        set report_timing_for_init_comp $env(REPORT_TIMING_FOR_INIT_COMP)
    } else {
        set report_timing_for_init_comp 0
    }

    if {$syn_flatten == 1} {
        set syn_flatten_level $env(SYN_FLATTEN_LEVEL)
    }

    ## insert dft or not
    if [info exist env(INSERT_DFT_LOGIC)] {
        set insert_dft_logic $env(INSERT_DFT_LOGIC)
    } else {
        set insert_dft_logic 0
    }

    ## upf low-power flow or not
    if [info exist env(UPF_EN)] {
        set low_power_tcl $env(LOW_POWER_TCL)
        if {$env(HAS_POWER_SWITCH) == 1} {
            if {$env(POWER_SWITCH_SENSE) == "active_low"} {
                echo "INFO: power switch eco needs to be done as it is active_low in target library."
                set power_switch_eco_en 1
            } else {
                echo "INFO: no power switch eco needs to be done as it is active_low in target library."
                set power_switch_eco_en 0
            }
        } else {
            set power_switch_eco_en 0
        }
    }

    ## pass global defines into dc analyze cmd
    if [info exist env(ANA_DEFINE_OPTS)] {
        set ana_define_opts $env(ANA_DEFINE_OPTS)
    } else {
        set ana_define_opts ""
    }

    ## switch used for synthesis experiment
    if [info exist env(DO_EXP)] {
        set do_exp $env(DO_EXP)
        if {$do_exp == 1} {
            enable_write_lib_mode
        }
    } else {
        set do_exp ""
    }

    ## suppress errors
    if [info exist env(SUPPRESS_ERRORS)] {
        set ignore_errors $env(SUPPRESS_ERRORS)
    } else {
        set ignore_errors {}
    }

    ## check clock pins clock drivers
    if {[info exists env(CHECK_CLOCK_PINS)]} {
        set check_clock_pins $env(CHECK_CLOCK_PINS)
    } else {
        set check_clock_pins 0
    }

    ## user path groups file
    if {[info exists env(USER_PATH_GROUPS_FILE)]} {
        set user_path_groups_file $env(USER_PATH_GROUPS_FILE)
    } else {
        set user_path_groups_file ""
    }

    set open_gui $env(START_GUI)
    set link_only $env(LINK_ONLY)

    if {[info exists env(SAIF_INSTANCE_HIER)]} {
        set saif_instance_hier $env(SAIF_INSTANCE_HIER)
    } else {
        set saif_instance_hier ""
    }

    if {[info exists env(FORCE_UNIQUIFY)]} {
        set force_uniquify $env(FORCE_UNIQUIFY)
    } else {
        set force_uniquify 0
    }

    #async_fifo constraint switch
    if {[info exists env(USE_ASYNC_FIFO_CONSTRAINT)]} {
        set use_async_fifo_cons $env(USE_ASYNC_FIFO_CONSTRAINT)
    } else {
        set use_async_fifo_cons 0
    }


    ## message severity upgrade and downgrade
    set_message_info -id LINK-5 -stop_on

}

if {$synopsys_program_name == "vcst"} {
    ## pass global defines into dc analyze cmd
    if [info exist env(ANA_DEFINE_OPTS)] {
        set ana_define_opts $env(ANA_DEFINE_OPTS)
    } else {
        set ana_define_opts ""
    }
}

puts "RM-Info: Completed script [info script]\n"
