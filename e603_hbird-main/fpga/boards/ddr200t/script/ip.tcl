create_ip -vendor xilinx.com -library ip -name clk_wiz -module_name mmcm -dir $ipdir -force
set_property -dict [list \
  CONFIG.PRIMITIVE {MMCM} \
  CONFIG.RESET_TYPE {ACTIVE_LOW} \
  CONFIG.CLKOUT1_USED {true} \
  CONFIG.CLKOUT2_USED {true} \
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $env(DDR_FREQ) \
  CONFIG.CLKOUT2_REQUESTED_OUT_FREQ $env(CORE_FREQ) \
  ] [get_ips mmcm]

create_ip -vendor xilinx.com -library ip -name proc_sys_reset -module_name reset_sys -dir $ipdir -force
set_property -dict [list \
  CONFIG.C_EXT_RESET_HIGH {false} \
  CONFIG.C_AUX_RESET_HIGH {false} \
  CONFIG.C_NUM_BUS_RST {1} \
  CONFIG.C_NUM_PERP_RST {1} \
  CONFIG.C_NUM_INTERCONNECT_ARESETN {1} \
  CONFIG.C_NUM_PERP_ARESETN {1} \
  ] [get_ips reset_sys]

if ($env(DDR3_EN)) {
create_ip -vendor xilinx.com -library ip -name mig_7series -version 4.2 -module_name ddr3 -dir $ipdir -force
set_property CONFIG.XML_INPUT_FILE [file normalize $scriptdir/mig_a.prj
  ] [get_ips ddr3]
}

if ($env(ETH_EN)) {
create_ip -name axi_ethernetlite -vendor xilinx.com -library ip -version 3.0 -module_name axi_ethernetlite_0
set_property -dict [list CONFIG.C_S_AXI_PROTOCOL {AXI4} CONFIG.AXI_ACLK_FREQ_MHZ {16}] [get_ips axi_ethernetlite_0]
}
