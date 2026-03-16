#############################################################
## This file is used for grouping below path groups:
## - reg2reg
## - in2reg
## - reg2out
## - reg2cg_en
## - ram2reg
## - reg2ram
#############################################################

set ports_clock_root [filter_collection [get_attribute [get_clocks] sources] object_class==port]

# remove existing timing groups
set all_default_path_groups [get_path_groups -quiet {reg2ram ram2reg reg2cg_en reg2reg in2reg reg2out in2out reg2latch in2latch latch2reg}]
if {[sizeof_collection $all_default_path_groups] > 0} {
    remove_path_group [get_object_name $all_default_path_groups]
}

# create timing group to memory data pins
set xl_cg_en_pins [get_pins -hierarchical -filter "clock_gate_enable_pin==true"]
if { $syn_with_sram == 1 } {
    set ram_macros  [get_cells -hierarchical -filter "cell_is_ram == true"]
    if { [sizeof_collection $ram_macros] == 0 } {
        puts "FATAL: syn_with_sram is set, but no sram macros found in design, please double check"
        set ram_macro_data_pins {}
        set ram_macro_clock_pins {}
    } else {
        set ram_macro_data_pins  [get_pins -of_objects [get_cells -hierarchical -filter "cell_is_ram == true"] -filter "is_data_pin==true"]
        set ram_macro_clock_pins [get_pins -of_objects [get_cells -hierarchical -filter "cell_is_ram == true"] -filter "is_clock_pin==true"]
        group_path -name reg2ram -from [remove_from_collection [all_registers -clock_pins] $ram_macro_clock_pins] -to $ram_macro_data_pins
        group_path -name ram2reg -from $ram_macro_clock_pins -to [remove_from_collection [all_registers -data_pins] [add_to_collection $ram_macro_data_pins $xl_cg_en_pins]]
    }
} else {
    set ram_macro_data_pins {}
    set ram_macro_clock_pins {}
}

# create timing group to clock gate enable pin
if {[sizeof_collection $xl_cg_en_pins] > 0} {
    set has_cg_cell 1
    group_path -name reg2cg_en -from [all_registers -clock_pins] -to $xl_cg_en_pins
    group_path -name in2cg_en  -from [all_inputs] -to $xl_cg_en_pins
} else {
    set has_cg_cell 0
}

group_path -name reg2reg -from [remove_from_collection [all_registers -clock_pins] $ram_macro_clock_pins] \
                         -to   [remove_from_collection [all_registers -data_pins] [add_to_collection $ram_macro_data_pins $xl_cg_en_pins]]
group_path -name in2reg  -from [remove_from_collection [all_inputs] ${ports_clock_root}] \
                         -to   [remove_from_collection [all_registers -data_pins] [add_to_collection $ram_macro_data_pins $xl_cg_en_pins]]
group_path -name reg2out -from [remove_from_collection [all_registers -clock_pins] $ram_macro_clock_pins] \
                         -to   [all_outputs]
group_path -name in2out  -from [remove_from_collection [all_inputs] ${ports_clock_root}] -to [all_outputs]

if { [sizeof_collection [all_registers -level_sensitive]] > 0 } {
    group_path -name reg2latch -from [all_registers -clock_pins] -to [all_registers -level_sensitive -data_pins]
    group_path -name in2latch  -from [all_inputs ] -to [all_registers -level_sensitive -data_pins]
    group_path -name latch2reg -from [all_registers -level_sensitive -clock_pins] -to [all_registers -data_pins]
}
