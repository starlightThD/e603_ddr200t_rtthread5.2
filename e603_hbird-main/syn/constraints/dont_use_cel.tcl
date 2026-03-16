if {[sizeof_collection [get_lib_cells -quiet */*TBUF*]] > 0} {
    set_dont_use [get_lib_cells -quiet */*TBUF*]
}

if {[sizeof_collection [get_lib_cells -quiet */*CLK*]] > 0} {
    set_dont_use [get_lib_cells -quiet */*CLK*]
}

if {[sizeof_collection [get_lib_cells -quiet */*X24*]] > 0} {
    set_dont_use -power [get_lib_cells -quiet */*X24*]
}

if {[sizeof_collection [get_lib_cells -quiet */RVT_LOGIC1_X1]] > 0} {
    set_dont_use [get_lib_cells -quiet */RVT_LOGIC1_X1]
}

if {[sizeof_collection [get_lib_cells -quiet */RVT_LOGIC0_X1]] > 0} {
    set_dont_use [get_lib_cells -quiet */RVT_LOGIC0_X1]
}

