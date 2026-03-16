puts "RM-Info: Running script [info script]\n"

##########################################################################################
# Variables common to all reference methodology scripts
# Script: common_setup.tcl
# Version: K-2015.06 (July 13, 2015)
# Copyright (C) 2007-2015 Synopsys, Inc. All rights reserved.
##########################################################################################

if {[info exist env(PROJ_SRC_ROOT)]} {
    set PROJ_SRC_ROOT                 $env(PROJ_SRC_ROOT)  ;
} else {
    set PROJ_SRC_ROOT             "" ;
}
if {[info exist env(PROJ_NAME)]} {
    set PROJ_NAME                 $env(PROJ_NAME)  ;
} else {
    set PROJ_NAME                 "" ;
}

set DESIGN_NAME                   $env(TOP)  ;   #  The name of the top-level design

if {[info exist env(TECH)]} {
    set TECH                        $env(TECH)
    set CORNER                      $env(CORNER)
    set LIB_RVT                     $env(LIB_RVT)
    set LIB_LVT                     $env(LIB_LVT)
    set LIB_ULVT                    $env(LIB_ULVT)
    set LIB_HAS_RVT                 $env(LIB_HAS_RVT)
    set LIB_HAS_LVT                 $env(LIB_HAS_LVT)
    set LIB_HAS_ULVT                $env(LIB_HAS_ULVT)
    set LIB_RVT_PERC                $env(LIB_RVT_PERC)
    set LIB_LVT_PERC                $env(LIB_LVT_PERC)
    set LIB_ULVT_PERC               $env(LIB_ULVT_PERC)
} else {
    set TECH                        ""
    set CORNER                      ""
    set LIB_RVT                     ""
    set LIB_LVT                     ""
    set LIB_ULVT                    ""
    set LIB_HAS_RVT                 0
    set LIB_HAS_LVT                 0
    set LIB_HAS_ULVT                0
    set LIB_RVT_PERC                0
    set LIB_LVT_PERC                0
    set LIB_ULVT_PERC               0
}

if {${TECH} == 28} {
    set lib_rvt  ${LIB_RVT}${CORNER}_ccs
    set lib_lvt  ${LIB_LVT}${CORNER}_ccs 
    set lib_ulvt ${LIB_ULVT}${CORNER}_ccs
} elseif {${TECH} == 12} {
    set lib_rvt  ${LIB_RVT}${CORNER}_ccs
    set lib_lvt  ${LIB_LVT}${CORNER}_ccs
    set lib_ulvt ${LIB_ULVT}${CORNER}_ccs
} elseif {${TECH} == 14} {
    set lib_rvt  ${LIB_RVT}_${CORNER}_ccs
    set lib_lvt  ${LIB_LVT}_${CORNER}_ccs
    set lib_ulvt ${LIB_ULVT}_${CORNER}_ccs
} elseif {${TECH} == 40} {
    set lib_rvt  ${LIB_RVT}_${CORNER}_ccs
    set lib_lvt  ${LIB_LVT}_${CORNER}_ccs
    set lib_ulvt ${LIB_ULVT}_${CORNER}_ccs
} elseif {${TECH} == 22} {
    set lib_rvt  ${LIB_RVT}${CORNER}_ccs
    set lib_lvt  ${LIB_LVT}${CORNER}_ccs 
    set lib_ulvt ${LIB_ULVT}${CORNER}_ccs
}

set DESIGN_REF_DATA_PATH          ""  ;#  Absolute path prefix variable for library/design data.
                                       #  Use this variable to prefix the common absolute path
                                       #  to the common variables defined below.
                                       #  Absolute paths are mandatory for hierarchical
                                       #  reference methodology flow.

##########################################################################################
# Hierarchical Flow Design Variables
##########################################################################################

set HIERARCHICAL_DESIGNS           "" ;# List of hierarchical block design names "DesignA DesignB" ...
set HIERARCHICAL_CELLS             "" ;# List of hierarchical block cell instance names "u_DesignA u_DesignB" ...

##########################################################################################
# Library Setup Variables
##########################################################################################

# check if synthesis has sram macros
set has_sram [info exist env(SYN_WITH_SRAM)]
if { $has_sram == 1 } {
    if { $env(SYN_WITH_SRAM) == 1 } {
        set sram_dblib $env(SRAM_MACRO_DBLIB)
        if {[info exist env(MW_SRAM_LIBS)]} {
            set sram_mw_libs $env(MW_SRAM_LIBS)
        } else {
            set sram_mw_libs ""
        }
        set syn_with_sram 1
    } else {
        set sram_dblib ""
        set sram_mw_libs ""
        set syn_with_sram 0
    }
} else {
    set syn_with_sram 0
    set sram_dblib ""
    set sram_mw_libs ""
}

set has_extra_db [info exist env(HAS_EXTRA_DB)]
if { $has_extra_db == 1} {
    set extra_db_files $env(EXTRA_DB_FILES)
    if {[info exist env(EXTRA_MW_DIRS)]} {
        set extra_mw_dirs $env(EXTRA_MW_DIRS)
    } else {
        set extra_mw_dirs ""
    }
} else {
    set extra_db_files ""
    set extra_mw_dirs ""
}

# check if library compiler is loaded
set has_lc [info exist env(LC_HOME)]

# Tcl file with library modifications for dont_use
set LIBRARY_DONT_USE_FILE     ./constraints/dont_use_cel.tcl

# Set library files, all env variables are controlled from topgun
set libdir                    $env(LIB_ROOT)

set libs                      $env(LIB_NAMES)
#  Target technology logical libraries
set TARGET_LIBRARY_FILES      {}
foreach lib $libs {
    lappend TARGET_LIBRARY_FILES ${lib}
}

#  Additional search path to be added to the default search path
set ADDITIONAL_SEARCH_PATH    $env(LIB_PATHS)
#  Milkyway reference libraries (include IC Compiler ILMs here)
if [info exist env(MW_PATHS)] {
set MW_REFERENCE_LIB_DIRS     $env(MW_PATHS)
} else {
set MW_REFERENCE_LIB_DIRS     ""
}
#  Reference Control file to define the Milkyway reference libs
set MW_REFERENCE_CONTROL_FILE ""
#  List of max min library pairs "max1 min1 max2 min2 max3 min3"...
set MIN_LIBRARY_FILES         ""
#  Extra link logical libraries not included in TARGET_LIBRARY_FILES
set ADDITIONAL_LINK_LIB_FILES "$sram_dblib $extra_db_files"
#  Milkyway technology file
if [info exist env(TECH_FILE)] {
set TECH_FILE                 $env(TECH_FILE)
} else {
set TECH_FILE                 ""
}
#  Mapping file for TLUplus
if [info exist env(MAP_FILE)] {
set MAP_FILE                  $env(MAP_FILE)
} else {
set MAP_FILE                  ""
}
#  Max TLUplus file
if [info exist env(TLUPLUS_MAX_FILE)] {
set TLUPLUS_MAX_FILE          $env(TLUPLUS_MAX_FILE)
} else {
set TLUPLUS_MAX_FILE          ""
}
#  Min TLUplus file
if [info exist env(TLUPLUS_MIN_FILE)] {
set TLUPLUS_MIN_FILE          $env(TLUPLUS_MIN_FILE)
} else {
set TLUPLUS_MIN_FILE          ""
}
# Min routing layer
set MIN_ROUTING_LAYER         ""
# Max routing layer
set MAX_ROUTING_LAYER         ""
# below two cells are used for set_drive and set_load
set NAND_CELL                 $env(NAND_CELL)
set BUF_CELL                  $env(BUF_CELL)
# dft inserted rtl filelist from dft tool
if [info exist env(DFT_FILELIST)] { 
set DFT_FILELIST              $env(DFT_FILELIST)
} else {
set DFT_FILELIST              ""
}

## upf low-power flow or not
if [info exist env(UPF_EN)] {
    set use_upf_flow  $env(UPF_EN)
    set upf_file      $env(UPF_FILE)
} else {
    set use_upf_flow 0
}

puts "RM-Info: Completed script [info script]\n"
