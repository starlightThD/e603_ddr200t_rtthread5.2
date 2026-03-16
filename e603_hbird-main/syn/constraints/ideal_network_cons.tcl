set_ideal_network [get_ports core_clk_aon]
set_ideal_network [get_ports jtag_TCK]

# set ideal_network to all clkgate output as ideal_network cannot propagate through sequential cell
set xl_all_cg_cells [get_cells -hierarchical -filter "ref_name =~ *gnrl_tech_clkgate*"]
if { [sizeof_collection $xl_all_cg_cells] > 0 } {
    foreach_in_collection xl_cg_inst_path $xl_all_cg_cells {
        set xl_cg_leaf_output [get_object_name [get_cells $xl_cg_inst_path]]/*/GCK
        set_ideal_network [get_pins $xl_cg_leaf_output]
    }
}

# set ideal_network to all reset_sync output to prevent dc from inserting buffers at synthesis
set xl_all_reset_sync_cells [get_cells -hierarchical -filter "ref_name =~ *_reset_sync*"]
if { [sizeof_collection $xl_all_reset_sync_cells] > 0 } {
    foreach_in_collection xl_rst_sync_cell_inst_path $xl_all_reset_sync_cells {
        set xl_sync_mux_dff_output [get_object_name [get_cells $xl_rst_sync_cell_inst_path]]/u_sync_rst_sel*/u_std_mux2/Z
        puts "INFO: set ideal_network to reset_sync output $xl_sync_mux_dff_output"
        set_ideal_network [get_pins $xl_sync_mux_dff_output]
    }
}

