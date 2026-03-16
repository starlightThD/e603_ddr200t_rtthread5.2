############# ETH RTL8211EG define ###################################


set_property IOSTANDARD LVCMOS33 [get_ports phy_rx_clk]
set_property PACKAGE_PIN K18 [get_ports phy_rx_clk]

set_property IOSTANDARD LVCMOS33 [get_ports phy_crs]
set_property PACKAGE_PIN L18 [get_ports phy_crs]

set_property IOSTANDARD LVCMOS33 [get_ports phy_dv]
set_property PACKAGE_PIN M22 [get_ports phy_dv]

set_property IOSTANDARD LVCMOS33 [get_ports phy_col]
set_property PACKAGE_PIN M18 [get_ports phy_col]

set_property IOSTANDARD LVCMOS33 [get_ports phy_rx_er]
set_property PACKAGE_PIN N18 [get_ports phy_rx_er]

set_property PACKAGE_PIN J17 [get_ports phy_mdc]
set_property IOSTANDARD LVCMOS33 [get_ports phy_mdc]

set_property PACKAGE_PIN L16 [get_ports phy_mdio]
set_property IOSTANDARD LVCMOS33 [get_ports phy_mdio]

set_property IOSTANDARD LVCMOS33 [get_ports {phy_rx_data[0]}]
set_property PACKAGE_PIN N22 [get_ports {phy_rx_data[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {phy_rx_data[1]}]
set_property PACKAGE_PIN H18 [get_ports {phy_rx_data[1]}]

set_property IOSTANDARD LVCMOS33 [get_ports {phy_rx_data[2]}]
set_property PACKAGE_PIN H17 [get_ports {phy_rx_data[2]}]

set_property IOSTANDARD LVCMOS33 [get_ports {phy_rx_data[3]}]
set_property PACKAGE_PIN M21 [get_ports {phy_rx_data[3]}]

#set_property IOSTANDARD LVCMOS33 [get_ports {phy_rx_data[4]}]
#set_property PACKAGE_PIN L21 [get_ports {phy_rx_data[4]}]

#set_property IOSTANDARD LVCMOS33 [get_ports {phy_rx_data[5]}]
#set_property PACKAGE_PIN N20 [get_ports {phy_rx_data[5]}]

#set_property IOSTANDARD LVCMOS33 [get_ports {phy_rx_data[6]}]
#set_property PACKAGE_PIN M20 [get_ports {phy_rx_data[6]}]

#set_property IOSTANDARD LVCMOS33 [get_ports {phy_rx_data[7]}]
#set_property PACKAGE_PIN N19 [get_ports {phy_rx_data[7]}]

set_property IOSTANDARD LVCMOS33 [get_ports phy_tx_clk]
set_property PACKAGE_PIN K21 [get_ports phy_tx_clk]

set_property IOSTANDARD LVCMOS33 [get_ports phy_tx_en]
set_property PACKAGE_PIN G22 [get_ports phy_tx_en]

set_property IOSTANDARD LVCMOS33 [get_ports {phy_tx_data[0]}]
set_property PACKAGE_PIN D22 [get_ports {phy_tx_data[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {phy_tx_data[1]}]
set_property PACKAGE_PIN H20 [get_ports {phy_tx_data[1]}]

set_property IOSTANDARD LVCMOS33 [get_ports {phy_tx_data[2]}]
set_property PACKAGE_PIN H22 [get_ports {phy_tx_data[2]}]

set_property IOSTANDARD LVCMOS33 [get_ports {phy_tx_data[3]}]
set_property PACKAGE_PIN J22 [get_ports {phy_tx_data[3]}]

#set_property IOSTANDARD LVCMOS33 [get_ports {phy_tx_data[4]}]
#set_property PACKAGE_PIN K22 [get_ports {phy_tx_data[4]}]

#set_property IOSTANDARD LVCMOS33 [get_ports {phy_tx_data[5]}]
#set_property PACKAGE_PIN L19 [get_ports {phy_tx_data[5]}]

#set_property IOSTANDARD LVCMOS33 [get_ports {phy_tx_data[6]}]
#set_property PACKAGE_PIN K19 [get_ports {phy_tx_data[6]}]

#set_property IOSTANDARD LVCMOS33 [get_ports {phy_tx_data[7]}]
#set_property PACKAGE_PIN L20 [get_ports {phy_tx_data[7]}]

set_property IOSTANDARD LVCMOS33 [get_ports phy_rst_n]
set_property PACKAGE_PIN G20 [get_ports phy_rst_n]
