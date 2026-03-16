`timescale 1ns/1ps

`include "global.v"

module system
(
  input wire CLK100MHZ,//GCLK-W19
  input wire CLK32768HZ,//RTC_CLK-Y18
  input wire fpga_rst,//FPGA_RESET-T6, low active
  input wire mcu_rst,//MCU_RESET-P20, low active
  
 `ifdef DDR3_CONTROLLER //{
  // Inouts
  inout wire [31:0]     ddr3_dq ,
  inout wire [3:0]      ddr3_dqs_n,
  inout wire [3:0]      ddr3_dqs_p,
  // Outputs
  output wire [13:0]    ddr3_addr,
  output wire [2:0]     ddr3_ba,
  output wire           ddr3_ras_n,
  output wire           ddr3_cas_n,
  output wire           ddr3_we_n,
  output wire           ddr3_reset_n,
  output wire [0:0]     ddr3_ck_p,
  output wire [0:0]     ddr3_ck_n,
  output wire [0:0]     ddr3_cke,
  output wire [0:0]     ddr3_cs_n,
  output wire [3:0]     ddr3_dm,
  output wire [0:0]     ddr3_odt,
  output wire           init_calib_complete,
`endif //}

`ifdef DDR4_CONTROLLER //{
  inout  wire [3:0]  c0_ddr4_dm_dbi_n,
  inout  wire [31:0] c0_ddr4_dq,
  inout  wire [3:0]  c0_ddr4_dqs_c,
  inout  wire [3:0]  c0_ddr4_dqs_t,
  output wire [16:0] c0_ddr4_adr,
  output wire [1:0]  c0_ddr4_ba,
  output wire [0:0]  c0_ddr4_bg,
  output wire [0:0]  c0_ddr4_cke,
  output wire [0:0]  c0_ddr4_odt,
  output wire [0:0]  c0_ddr4_cs_n,
  output wire [0:0]  c0_ddr4_ck_t,
  output wire [0:0]  c0_ddr4_ck_c,
  output wire        c0_ddr4_reset_n,
  output wire        init_calib_complete,
`endif //}

`ifdef TEMAC_CONTROLLER
   //phy interface
   input  wire       temac_axi_aclk,
   input  wire       temac_axi_aresetn,
   input  wire       phy_tx_clk, 
   input  wire       phy_rx_clk,
   input  wire       phy_crs, 
   input  wire       phy_dv,  
   input  wire [3:0] phy_rx_data,
   input  wire       phy_col,   
   input  wire       phy_rx_er,  
   output wire       phy_rst_n, 
   output wire       phy_tx_en,
   output wire [3:0] phy_tx_data,

   inout        phy_mdio,
   
   output       phy_mdc,
`endif

  // Dedicated QSPI0 interface
  output wire qspi0_cs ,//FPGAIO04-T16
  output wire qspi0_sck,//FPGAIO01-N14
  inout wire [3:0] qspi0_dq,//qspi_dq[3]-FPGA_IO02-P16
                           //qspi_dq[2]-FPGA_IO05-U16
                           //qspi_dq[1]-FPGA_IO03-R17 //DO
                           //qspi_dq[0]-FPGA_IO00-Y17 //DI

  // Dedicated QSPI1 interface
  output wire qspi1_cs0 ,//FPGAIO04-T16
  output wire qspi1_cs1 ,//FPGAIO04-T16
  output wire qspi1_cs2 ,//FPGAIO04-T16
  output wire qspi1_cs3 ,//FPGAIO04-T16
  output wire qspi1_sck,//FPGAIO01-N14
  inout wire [3:0] qspi1_dq,//qspi_dq[3]-FPGA_IO02-P16
                           //qspi_dq[2]-FPGA_IO05-U16
                           //qspi_dq[1]-FPGA_IO03-R17 //DO
                           //qspi_dq[0]-FPGA_IO00-Y17 //DI
  // Dedicated QSPI0 interface
  output wire qspi2_cs ,//FPGAIO04-T16
  output wire qspi2_sck,//FPGAIO01-N14
  inout wire [3:0] qspi2_dq,//qspi_dq[3]-FPGA_IO02-P16
                           //qspi_dq[2]-FPGA_IO05-U16
                           //qspi_dq[1]-FPGA_IO03-R17 //DO
                           //qspi_dq[0]-FPGA_IO00-Y17 //DI


  inout wire uart0_txd,//GPIO00~GPIO031
  inout wire uart0_rxd,//GPIO00~GPIO031
  
 


  // JD (used for JTAG connection)
  inout wire mcu_TDO,//MCU_TDO-N17
  inout wire mcu_TCK,//MCU_TCK-P15 
  inout wire mcu_TDI,//MCU_TDI-R13
  inout wire mcu_TMS,//MCU_TMS-T13

  inout wire evt_bar,
  inout wire nmi_bar,

  output wire core_wfi_mode,
  output wire core_sleep_value
 
  //output wire       nex_o_clk,
  //output wire [7:0] nex_o_data  
);

  wire clk_out1;
  wire mmcm_locked;

  wire reset_periph;

  // All wires connected to the chip top
  wire dut_clock;
  wire dut_reset;
  wire dut_io_pads_jtag_TCK_i_ival;
  wire dut_io_pads_jtag_TMS_i_ival;
  wire dut_io_pads_jtag_TMS_o_oval;
  wire dut_io_pads_jtag_TMS_o_oe;
  wire dut_io_pads_jtag_TMS_o_ie;
  wire dut_io_pads_jtag_TMS_o_pue;
  wire dut_io_pads_jtag_TMS_o_ds;
  wire dut_io_pads_jtag_TDI_i_ival;
  wire dut_io_pads_jtag_TDO_o_oval;
  wire dut_io_pads_jtag_tdo_drv_o_oval;
  wire dut_io_pads_jtag_TDO_o_oe = dut_io_pads_jtag_tdo_drv_o_oval;
wire dut_io_pads_qspi0_sck_o_oval;
  wire dut_io_pads_qspi0_dq_0_i_ival;
  wire dut_io_pads_qspi0_dq_0_o_oval;
  wire dut_io_pads_qspi0_dq_0_o_oe;
  wire dut_io_pads_qspi0_dq_0_o_ie;
  wire dut_io_pads_qspi0_dq_0_o_pue;
  wire dut_io_pads_qspi0_dq_0_o_ds;
  wire dut_io_pads_qspi0_dq_1_i_ival;
  wire dut_io_pads_qspi0_dq_1_o_oval;
  wire dut_io_pads_qspi0_dq_1_o_oe;
  wire dut_io_pads_qspi0_dq_1_o_ie;
  wire dut_io_pads_qspi0_dq_1_o_pue;
  wire dut_io_pads_qspi0_dq_1_o_ds;
  wire dut_io_pads_qspi0_dq_2_i_ival;
  wire dut_io_pads_qspi0_dq_2_o_oval;
  wire dut_io_pads_qspi0_dq_2_o_oe;
  wire dut_io_pads_qspi0_dq_2_o_ie;
  wire dut_io_pads_qspi0_dq_2_o_pue;
  wire dut_io_pads_qspi0_dq_2_o_ds;
  wire dut_io_pads_qspi0_dq_3_i_ival;
  wire dut_io_pads_qspi0_dq_3_o_oval;
  wire dut_io_pads_qspi0_dq_3_o_oe;
  wire dut_io_pads_qspi0_dq_3_o_ie;
  wire dut_io_pads_qspi0_dq_3_o_pue;
  wire dut_io_pads_qspi0_dq_3_o_ds;
  wire dut_io_pads_qspi0_cs_0_o_oval;
 wire dut_io_pads_qspi1_sck_o_oval;
  wire dut_io_pads_qspi1_dq_0_i_ival;
  wire dut_io_pads_qspi1_dq_0_o_oval;
  wire dut_io_pads_qspi1_dq_0_o_oe;
  wire dut_io_pads_qspi1_dq_0_o_ie;
  wire dut_io_pads_qspi1_dq_0_o_pue;
  wire dut_io_pads_qspi1_dq_0_o_ds;
  wire dut_io_pads_qspi1_dq_1_i_ival;
  wire dut_io_pads_qspi1_dq_1_o_oval;
  wire dut_io_pads_qspi1_dq_1_o_oe;
  wire dut_io_pads_qspi1_dq_1_o_ie;
  wire dut_io_pads_qspi1_dq_1_o_pue;
  wire dut_io_pads_qspi1_dq_1_o_ds;
  wire dut_io_pads_qspi1_dq_2_i_ival;
  wire dut_io_pads_qspi1_dq_2_o_oval;
  wire dut_io_pads_qspi1_dq_2_o_oe;
  wire dut_io_pads_qspi1_dq_2_o_ie;
  wire dut_io_pads_qspi1_dq_2_o_pue;
  wire dut_io_pads_qspi1_dq_2_o_ds;
  wire dut_io_pads_qspi1_dq_3_i_ival;
  wire dut_io_pads_qspi1_dq_3_o_oval;
  wire dut_io_pads_qspi1_dq_3_o_oe;
  wire dut_io_pads_qspi1_dq_3_o_ie;
  wire dut_io_pads_qspi1_dq_3_o_pue;
  wire dut_io_pads_qspi1_dq_3_o_ds;
  wire dut_io_pads_qspi1_cs_0_o_oval;
  wire dut_io_pads_qspi1_cs_1_o_oval;
  wire dut_io_pads_qspi1_cs_2_o_oval;
  wire dut_io_pads_qspi1_cs_3_o_oval;

  wire dut_io_pads_qspi2_sck_o_oval;
  wire dut_io_pads_qspi2_dq_0_i_ival;
  wire dut_io_pads_qspi2_dq_0_o_oval;
  wire dut_io_pads_qspi2_dq_0_o_oe;
  wire dut_io_pads_qspi2_dq_0_o_ie;
  wire dut_io_pads_qspi2_dq_0_o_pue;
  wire dut_io_pads_qspi2_dq_0_o_ds;
  wire dut_io_pads_qspi2_dq_1_i_ival;
  wire dut_io_pads_qspi2_dq_1_o_oval;
  wire dut_io_pads_qspi2_dq_1_o_oe;
  wire dut_io_pads_qspi2_dq_1_o_ie;
  wire dut_io_pads_qspi2_dq_1_o_pue;
  wire dut_io_pads_qspi2_dq_1_o_ds;
  wire dut_io_pads_qspi2_dq_2_i_ival;
  wire dut_io_pads_qspi2_dq_2_o_oval;
  wire dut_io_pads_qspi2_dq_2_o_oe;
  wire dut_io_pads_qspi2_dq_2_o_ie;
  wire dut_io_pads_qspi2_dq_2_o_pue;
  wire dut_io_pads_qspi2_dq_2_o_ds;
  wire dut_io_pads_qspi2_dq_3_i_ival;
  wire dut_io_pads_qspi2_dq_3_o_oval;
  wire dut_io_pads_qspi2_dq_3_o_oe;
  wire dut_io_pads_qspi2_dq_3_o_ie;
  wire dut_io_pads_qspi2_dq_3_o_pue;
  wire dut_io_pads_qspi2_dq_3_o_ds;
  wire dut_io_pads_qspi2_cs_0_o_oval;

  wire dut_io_pads_uart0_rxd_i_ival ;
  wire dut_io_pads_uart0_rxd_o_oval ;
  wire dut_io_pads_uart0_rxd_o_oe   ;
  wire dut_io_pads_uart0_rxd_o_ie   ;
  wire dut_io_pads_uart0_rxd_o_pue  ;
  wire dut_io_pads_uart0_rxd_o_ds   ;
  wire dut_io_pads_uart0_txd_i_ival ;
  wire dut_io_pads_uart0_txd_o_oval ;
  wire dut_io_pads_uart0_txd_o_oe   ;
  wire dut_io_pads_uart0_txd_o_ie   ;
  wire dut_io_pads_uart0_txd_o_pue  ;
  wire dut_io_pads_uart0_txd_o_ds   ;
  //=================================================
  // Clock & Reset
  wire clk_8388;
  wire clk_16M;
 
  
  wire ddr3_sys_clk_i;
  


  mmcm ip_mmcm
  (
    .resetn(fpga_rst),
    .clk_in1(CLK100MHZ),
    .clk_out1(ddr3_sys_clk_i), // 200 MHz, this clock we set to DDR CLK
    .clk_out2(clk_16M), // 16 MHz, this clock we set to 8/16/24/32MHz on board
    .locked(mmcm_locked)
  );



  reset_sys ip_reset_sys
  (
    .slowest_sync_clk(clk_16M),
    .ext_reset_in(fpga_rst), // Active-low
    .aux_reset_in(1'b1),
    .mb_debug_sys_rst(1'b0),
    .dcm_locked(mmcm_locked),
    .mb_reset(),
    .bus_struct_reset(),
    .peripheral_reset(reset_periph),
    .interconnect_aresetn(),
    .peripheral_aresetn()
  );

// SPI0 Interface

  wire [3:0] qspi0_ui_dq_o, qspi0_ui_dq_oe;
  wire [3:0] qspi0_ui_dq_i;

  PULLUP qspi0_pullup[3:0]
  (
    .O(qspi0_dq)
  );

  IOBUF qspi0_iobuf[3:0]
  (
    .IO(qspi0_dq),
    .O(qspi0_ui_dq_i),
    .I(qspi0_ui_dq_o),
    .T(~qspi0_ui_dq_oe)
  );


  //=================================================
// SPI1 Interface

  wire [3:0] qspi1_ui_dq_o, qspi1_ui_dq_oe;
  wire [3:0] qspi1_ui_dq_i;

  PULLUP qspi1_pullup[3:0]
  (
    .O(qspi1_dq)
  );

  IOBUF qspi1_iobuf[3:0]
  (
    .IO(qspi1_dq),
    .O(qspi1_ui_dq_i),
    .I(qspi1_ui_dq_o),
    .T(~qspi1_ui_dq_oe)
  );

  //=================================================
  // SPI2 Interface

  wire [3:0] qspi2_ui_dq_o, qspi2_ui_dq_oe;
  wire [3:0] qspi2_ui_dq_i;

  PULLUP qspi2_pullup[3:0]
  (
    .O(qspi2_dq)
  );

  IOBUF qspi2_iobuf[3:0]
  (
    .IO(qspi2_dq),
    .O(qspi2_ui_dq_i),
    .I(qspi2_ui_dq_o),
    .T(~qspi2_ui_dq_oe)
  );

   //=================================================
  // UART0 Interface

  wire iobuf_uart0_rxd_o;
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  IOBUF_uart0_rxd
  (
    .O(iobuf_uart0_rxd_o),
    .IO(uart0_rxd),
    .I(dut_io_pads_uart0_rxd_o_oval),
    .T(~dut_io_pads_uart0_rxd_o_oe)
  );
  assign dut_io_pads_uart0_rxd_i_ival = iobuf_uart0_rxd_o & dut_io_pads_uart0_rxd_o_ie;

  wire iobuf_uart0_txd_o;
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  IOBUF_uart0_txd
  (
    .O(iobuf_uart0_txd_o),
    .IO(uart0_txd),
    .I(dut_io_pads_uart0_txd_o_oval),
    .T(~dut_io_pads_uart0_txd_o_oe)
  );
  assign dut_io_pads_uart0_txd_i_ival = iobuf_uart0_txd_o & dut_io_pads_uart0_txd_o_ie;
  

  //=================================================
  // EVT/NMI IOBUFs

  wire iobuf_nmi_bar_o;
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  IOBUF_nmi_bar
  (
    .O(iobuf_nmi_bar_o),
    .IO(nmi_bar),
    .I(1'b0),
    .T(1'b1)
  );
  wire dut_io_pads_nmi_bar_i_ival = iobuf_nmi_bar_o ;
  PULLUP pullup_nmi_bar (.O(nmi_bar));

  wire iobuf_evt_bar_o;
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  IOBUF_evt_bar
  (
    .O(iobuf_evt_bar_o),
    .IO(evt_bar),
    .I(1'b0),
    .T(1'b1)
  );
  wire dut_io_pads_evt_bar_i_ival = iobuf_evt_bar_o ;
  PULLUP pullup_evt_bar (.O(evt_bar));

  //=================================================
  // JTAG IOBUFs

  wire iobuf_jtag_TCK_o;
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  IOBUF_jtag_TCK
  (
    .O(iobuf_jtag_TCK_o),
    .IO(mcu_TCK),
    .I(1'b0),
    .T(1'b1)
  );
  assign dut_io_pads_jtag_TCK_i_ival = iobuf_jtag_TCK_o ;
  PULLUP pullup_TCK (.O(mcu_TCK));

  wire iobuf_jtag_TMS_o;
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  IOBUF_jtag_TMS
  (
    .O(iobuf_jtag_TMS_o),
    .IO(mcu_TMS),
    .I(dut_io_pads_jtag_TMS_out_o_oval),
    .T(~dut_io_pads_jtag_DRV_TMS_o_oval)
  );
  assign dut_io_pads_jtag_TMS_i_ival = iobuf_jtag_TMS_o & ~dut_io_pads_jtag_DRV_TMS_o_oval;
  PULLUP pullup_TMS (.O(mcu_TMS));

  wire iobuf_jtag_TDI_o;
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  IOBUF_jtag_TDI
  (
    .O(iobuf_jtag_TDI_o),
    .IO(mcu_TDI),
    .I(1'b0),
    .T(1'b1)
  );
  assign dut_io_pads_jtag_TDI_i_ival = iobuf_jtag_TDI_o;
  PULLUP pullup_TDI (.O(mcu_TDI));

  wire iobuf_jtag_TDO_o;
  IOBUF
  #(
    .DRIVE(12),
    .IBUF_LOW_PWR("TRUE"),
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
  )
  IOBUF_jtag_TDO
  (
    .O(iobuf_jtag_TDO_o),
    .IO(mcu_TDO),
    .I(dut_io_pads_jtag_TDO_o_oval),
    .T(~dut_io_pads_jtag_TDO_o_oe)
  );

  //wire iobuf_jtag_TRST_n_o;
  //IOBUF
  //#(
  //  .DRIVE(12),
  //  .IBUF_LOW_PWR("TRUE"),
  //  .IOSTANDARD("DEFAULT"),
  //  .SLEW("SLOW")
  //)

  wire evt_i = ~dut_io_pads_evt_bar_i_ival;
  wire nmi_i = ~dut_io_pads_nmi_bar_i_ival;

  // model select
  //

  soc_top dut
  (
 
 `ifdef DDR3_CONTROLLER 
    //////////////////////////////
   // Inouts
   .ddr3_dq(ddr3_dq),
   .ddr3_dqs_n(ddr3_dqs_n),
   .ddr3_dqs_p(ddr3_dqs_p),
   // Outputs
   .ddr3_addr(ddr3_addr),
   .ddr3_ba(ddr3_ba),
   .ddr3_ras_n(ddr3_ras_n),
   .ddr3_cas_n(ddr3_cas_n),
   .ddr3_we_n(ddr3_we_n),
   .ddr3_reset_n(ddr3_reset_n),
   .ddr3_ck_p(ddr3_ck_p),
   .ddr3_ck_n(ddr3_ck_n),
   .ddr3_cke(ddr3_cke),
   .ddr3_cs_n(ddr3_cs_n),
   .ddr3_dm(ddr3_dm),
   .ddr3_odt(ddr3_odt),
   .init_calib_complete(init_calib_complete),
   
   .ddr3_sys_clk_i(ddr3_sys_clk_i),
   .ddr3_sys_rst_i(fpga_rst),

`endif

`ifdef DDR4_CONTROLLER
  .c0_ddr4_dm_dbi_n    (c0_ddr4_dm_dbi_n   ),
  .c0_ddr4_dq          (c0_ddr4_dq         ),
  .c0_ddr4_dqs_c       (c0_ddr4_dqs_c      ),
  .c0_ddr4_dqs_t       (c0_ddr4_dqs_t      ),
  .c0_ddr4_adr         (c0_ddr4_adr        ),
  .c0_ddr4_ba          (c0_ddr4_ba         ),
  .c0_ddr4_bg          (c0_ddr4_bg         ),
  .c0_ddr4_cke         (c0_ddr4_cke        ),
  .c0_ddr4_odt         (c0_ddr4_odt        ),
  .c0_ddr4_cs_n        (c0_ddr4_cs_n       ),
  .c0_ddr4_ck_t        (c0_ddr4_ck_t       ),
  .c0_ddr4_ck_c        (c0_ddr4_ck_c       ),
  .c0_ddr4_reset_n     (c0_ddr4_reset_n    ),
  .init_calib_complete (init_calib_complete),
  .c0_ddr4_clk_p       (ddr3_sys_clk_i      ),
  .c0_ddr4_clk_n       (~ddr3_sys_clk_i     ),
  .ddr3_sys_rst_i      (fpga_rst            ),
`endif
    
    /////////////////////////////
    .por_rst_n(fpga_rst),
    .sys_rst_n(mcu_rst),
    .sys_clk  (clk_16M),
    .aon_clk  (CLK32768HZ),
      
    .evt_i    (evt_i),
    .nmi_i    (nmi_i),
    .core_sleep_value(core_sleep_value),
    .core_wfi_mode   (core_wfi_mode),

    .nex_clk (clk_16M),
    .nex_rst_n(mcu_rst),
    .nex_o_clk       (),
    .nex_o_data      (),    
    .stop_on_reset (1'b0),

//////////////////////////////////////////////////////////////////
     // Note: this is the real SoC top AON domain slow clock
    .io_pads_jtag_TCK_i_ival(dut_io_pads_jtag_TCK_i_ival),
    .io_pads_jtag_TMS_i_ival(dut_io_pads_jtag_TMS_i_ival),
    .io_pads_jtag_TDI_i_ival(dut_io_pads_jtag_TDI_i_ival),
    .io_pads_jtag_TDO_o_oval(dut_io_pads_jtag_TDO_o_oval),
    .io_pads_jtag_tdo_drv_o_oval(dut_io_pads_jtag_tdo_drv_o_oval),
    .io_pads_jtag_bk_o_oval(),
    .io_pads_jtag_TMS_out_o_oval(dut_io_pads_jtag_TMS_out_o_oval),
    .io_pads_jtag_DRV_TMS_o_oval(dut_io_pads_jtag_DRV_TMS_o_oval),
    .io_pads_qspi0_sck_o_oval (dut_io_pads_qspi0_sck_o_oval),
    .io_pads_qspi0_dq_0_i_ival(dut_io_pads_qspi0_dq_0_i_ival),
    .io_pads_qspi0_dq_0_o_oval(dut_io_pads_qspi0_dq_0_o_oval),
    .io_pads_qspi0_dq_0_o_oe  (dut_io_pads_qspi0_dq_0_o_oe),
    .io_pads_qspi0_dq_0_o_ie  (dut_io_pads_qspi0_dq_0_o_ie),
    .io_pads_qspi0_dq_0_o_pue (dut_io_pads_qspi0_dq_0_o_pue),
    .io_pads_qspi0_dq_0_o_ds  (dut_io_pads_qspi0_dq_0_o_ds),
    .io_pads_qspi0_dq_1_i_ival(dut_io_pads_qspi0_dq_1_i_ival),
    .io_pads_qspi0_dq_1_o_oval(dut_io_pads_qspi0_dq_1_o_oval),
    .io_pads_qspi0_dq_1_o_oe  (dut_io_pads_qspi0_dq_1_o_oe),
    .io_pads_qspi0_dq_1_o_ie  (dut_io_pads_qspi0_dq_1_o_ie),
    .io_pads_qspi0_dq_1_o_pue (dut_io_pads_qspi0_dq_1_o_pue),
    .io_pads_qspi0_dq_1_o_ds  (dut_io_pads_qspi0_dq_1_o_ds),
    .io_pads_qspi0_dq_2_i_ival(dut_io_pads_qspi0_dq_2_i_ival),
    .io_pads_qspi0_dq_2_o_oval(dut_io_pads_qspi0_dq_2_o_oval),
    .io_pads_qspi0_dq_2_o_oe  (dut_io_pads_qspi0_dq_2_o_oe),
    .io_pads_qspi0_dq_2_o_ie  (dut_io_pads_qspi0_dq_2_o_ie),
    .io_pads_qspi0_dq_2_o_pue (dut_io_pads_qspi0_dq_2_o_pue),
    .io_pads_qspi0_dq_2_o_ds  (dut_io_pads_qspi0_dq_2_o_ds),
    .io_pads_qspi0_dq_3_i_ival(dut_io_pads_qspi0_dq_3_i_ival),
    .io_pads_qspi0_dq_3_o_oval(dut_io_pads_qspi0_dq_3_o_oval),
    .io_pads_qspi0_dq_3_o_oe  (dut_io_pads_qspi0_dq_3_o_oe),
    .io_pads_qspi0_dq_3_o_ie  (dut_io_pads_qspi0_dq_3_o_ie),
    .io_pads_qspi0_dq_3_o_pue (dut_io_pads_qspi0_dq_3_o_pue),
    .io_pads_qspi0_dq_3_o_ds  (dut_io_pads_qspi0_dq_3_o_ds),
    .io_pads_qspi0_cs_0_o_oval(dut_io_pads_qspi0_cs_0_o_oval),

    .io_pads_qspi1_sck_o_oval (dut_io_pads_qspi1_sck_o_oval),
    .io_pads_qspi1_dq_0_i_ival(dut_io_pads_qspi1_dq_0_i_ival),
    .io_pads_qspi1_dq_0_o_oval(dut_io_pads_qspi1_dq_0_o_oval),
    .io_pads_qspi1_dq_0_o_oe  (dut_io_pads_qspi1_dq_0_o_oe),
    .io_pads_qspi1_dq_0_o_ie  (dut_io_pads_qspi1_dq_0_o_ie),
    .io_pads_qspi1_dq_0_o_pue (dut_io_pads_qspi1_dq_0_o_pue),
    .io_pads_qspi1_dq_0_o_ds  (dut_io_pads_qspi1_dq_0_o_ds),
    .io_pads_qspi1_dq_1_i_ival(dut_io_pads_qspi1_dq_1_i_ival),
    .io_pads_qspi1_dq_1_o_oval(dut_io_pads_qspi1_dq_1_o_oval),
    .io_pads_qspi1_dq_1_o_oe  (dut_io_pads_qspi1_dq_1_o_oe),
    .io_pads_qspi1_dq_1_o_ie  (dut_io_pads_qspi1_dq_1_o_ie),
    .io_pads_qspi1_dq_1_o_pue (dut_io_pads_qspi1_dq_1_o_pue),
    .io_pads_qspi1_dq_1_o_ds  (dut_io_pads_qspi1_dq_1_o_ds),
    .io_pads_qspi1_dq_2_i_ival(dut_io_pads_qspi1_dq_2_i_ival),
    .io_pads_qspi1_dq_2_o_oval(dut_io_pads_qspi1_dq_2_o_oval),
    .io_pads_qspi1_dq_2_o_oe  (dut_io_pads_qspi1_dq_2_o_oe),
    .io_pads_qspi1_dq_2_o_ie  (dut_io_pads_qspi1_dq_2_o_ie),
    .io_pads_qspi1_dq_2_o_pue (dut_io_pads_qspi1_dq_2_o_pue),
    .io_pads_qspi1_dq_2_o_ds  (dut_io_pads_qspi1_dq_2_o_ds),
    .io_pads_qspi1_dq_3_i_ival(dut_io_pads_qspi1_dq_3_i_ival),
    .io_pads_qspi1_dq_3_o_oval(dut_io_pads_qspi1_dq_3_o_oval),
    .io_pads_qspi1_dq_3_o_oe  (dut_io_pads_qspi1_dq_3_o_oe),
    .io_pads_qspi1_dq_3_o_ie  (dut_io_pads_qspi1_dq_3_o_ie),
    .io_pads_qspi1_dq_3_o_pue (dut_io_pads_qspi1_dq_3_o_pue),
    .io_pads_qspi1_dq_3_o_ds  (dut_io_pads_qspi1_dq_3_o_ds),
    .io_pads_qspi1_cs_0_o_oval(dut_io_pads_qspi1_cs_0_o_oval), 
    .io_pads_qspi1_cs_1_o_oval(dut_io_pads_qspi1_cs_1_o_oval), 
    .io_pads_qspi1_cs_2_o_oval(dut_io_pads_qspi1_cs_2_o_oval), 
    .io_pads_qspi1_cs_3_o_oval(dut_io_pads_qspi1_cs_3_o_oval),

    .io_pads_qspi2_sck_o_oval (dut_io_pads_qspi2_sck_o_oval),
    .io_pads_qspi2_dq_0_i_ival(dut_io_pads_qspi2_dq_0_i_ival),
    .io_pads_qspi2_dq_0_o_oval(dut_io_pads_qspi2_dq_0_o_oval),
    .io_pads_qspi2_dq_0_o_oe  (dut_io_pads_qspi2_dq_0_o_oe),
    .io_pads_qspi2_dq_0_o_ie  (dut_io_pads_qspi2_dq_0_o_ie),
    .io_pads_qspi2_dq_0_o_pue (dut_io_pads_qspi2_dq_0_o_pue),
    .io_pads_qspi2_dq_0_o_ds  (dut_io_pads_qspi2_dq_0_o_ds),
    .io_pads_qspi2_dq_1_i_ival(dut_io_pads_qspi2_dq_1_i_ival),
    .io_pads_qspi2_dq_1_o_oval(dut_io_pads_qspi2_dq_1_o_oval),
    .io_pads_qspi2_dq_1_o_oe  (dut_io_pads_qspi2_dq_1_o_oe),
    .io_pads_qspi2_dq_1_o_ie  (dut_io_pads_qspi2_dq_1_o_ie),
    .io_pads_qspi2_dq_1_o_pue (dut_io_pads_qspi2_dq_1_o_pue),
    .io_pads_qspi2_dq_1_o_ds  (dut_io_pads_qspi2_dq_1_o_ds),
    .io_pads_qspi2_dq_2_i_ival(dut_io_pads_qspi2_dq_2_i_ival),
    .io_pads_qspi2_dq_2_o_oval(dut_io_pads_qspi2_dq_2_o_oval),
    .io_pads_qspi2_dq_2_o_oe  (dut_io_pads_qspi2_dq_2_o_oe),
    .io_pads_qspi2_dq_2_o_ie  (dut_io_pads_qspi2_dq_2_o_ie),
    .io_pads_qspi2_dq_2_o_pue (dut_io_pads_qspi2_dq_2_o_pue),
    .io_pads_qspi2_dq_2_o_ds  (dut_io_pads_qspi2_dq_2_o_ds),
    .io_pads_qspi2_dq_3_i_ival(dut_io_pads_qspi2_dq_3_i_ival),
    .io_pads_qspi2_dq_3_o_oval(dut_io_pads_qspi2_dq_3_o_oval),
    .io_pads_qspi2_dq_3_o_oe  (dut_io_pads_qspi2_dq_3_o_oe),
    .io_pads_qspi2_dq_3_o_ie  (dut_io_pads_qspi2_dq_3_o_ie),
    .io_pads_qspi2_dq_3_o_pue (dut_io_pads_qspi2_dq_3_o_pue),
    .io_pads_qspi2_dq_3_o_ds  (dut_io_pads_qspi2_dq_3_o_ds),
    .io_pads_qspi2_cs_0_o_oval(dut_io_pads_qspi2_cs_0_o_oval),

    .io_pads_uart0_rxd_i_ival (dut_io_pads_uart0_rxd_i_ival),
    .io_pads_uart0_rxd_o_oval (dut_io_pads_uart0_rxd_o_oval),
    .io_pads_uart0_rxd_o_oe   (dut_io_pads_uart0_rxd_o_oe),
    .io_pads_uart0_rxd_o_ie   (dut_io_pads_uart0_rxd_o_ie),
    .io_pads_uart0_rxd_o_pue  (dut_io_pads_uart0_rxd_o_pue),
    .io_pads_uart0_rxd_o_ds   (dut_io_pads_uart0_rxd_o_ds),
    .io_pads_uart0_txd_i_ival (dut_io_pads_uart0_txd_i_ival),
    .io_pads_uart0_txd_o_oval (dut_io_pads_uart0_txd_o_oval),
    .io_pads_uart0_txd_o_oe   (dut_io_pads_uart0_txd_o_oe),
    .io_pads_uart0_txd_o_ie   (dut_io_pads_uart0_txd_o_ie),
    .io_pads_uart0_txd_o_pue  (dut_io_pads_uart0_txd_o_pue),
    .io_pads_uart0_txd_o_ds   (dut_io_pads_uart0_txd_o_ds)
  );

 assign qspi0_cs = dut_io_pads_qspi0_cs_0_o_oval;
  assign qspi0_ui_dq_o = {
    dut_io_pads_qspi0_dq_3_o_oval,
    dut_io_pads_qspi0_dq_2_o_oval,
    dut_io_pads_qspi0_dq_1_o_oval,
    dut_io_pads_qspi0_dq_0_o_oval
  };
  assign qspi0_ui_dq_oe = {
    dut_io_pads_qspi0_dq_3_o_oe,
    dut_io_pads_qspi0_dq_2_o_oe,
    dut_io_pads_qspi0_dq_1_o_oe,
    dut_io_pads_qspi0_dq_0_o_oe
  };
  assign dut_io_pads_qspi0_dq_0_i_ival = qspi0_ui_dq_i[0];
  assign dut_io_pads_qspi0_dq_1_i_ival = qspi0_ui_dq_i[1];
  assign dut_io_pads_qspi0_dq_2_i_ival = qspi0_ui_dq_i[2];
  assign dut_io_pads_qspi0_dq_3_i_ival = qspi0_ui_dq_i[3];
  assign qspi0_sck = dut_io_pads_qspi0_sck_o_oval;


  assign qspi1_cs0 = dut_io_pads_qspi1_cs_0_o_oval;
  assign qspi1_cs1 = dut_io_pads_qspi1_cs_1_o_oval;
  assign qspi1_cs2 = dut_io_pads_qspi1_cs_2_o_oval;
  assign qspi1_cs3 = dut_io_pads_qspi1_cs_3_o_oval;
  assign qspi1_ui_dq_o = {
    dut_io_pads_qspi1_dq_3_o_oval,
    dut_io_pads_qspi1_dq_2_o_oval,
    dut_io_pads_qspi1_dq_1_o_oval,
    dut_io_pads_qspi1_dq_0_o_oval
  };
  assign qspi1_ui_dq_oe = {
    dut_io_pads_qspi1_dq_3_o_oe,
    dut_io_pads_qspi1_dq_2_o_oe,
    dut_io_pads_qspi1_dq_1_o_oe,
    dut_io_pads_qspi1_dq_0_o_oe
  };
  assign dut_io_pads_qspi1_dq_0_i_ival = qspi1_ui_dq_i[0];
  assign dut_io_pads_qspi1_dq_1_i_ival = qspi1_ui_dq_i[1];
  assign dut_io_pads_qspi1_dq_2_i_ival = qspi1_ui_dq_i[2];
  assign dut_io_pads_qspi1_dq_3_i_ival = qspi1_ui_dq_i[3];
  assign qspi1_sck = dut_io_pads_qspi1_sck_o_oval;

  assign qspi2_cs = dut_io_pads_qspi2_cs_0_o_oval;
  assign qspi2_ui_dq_o = {
    dut_io_pads_qspi2_dq_3_o_oval,
    dut_io_pads_qspi2_dq_2_o_oval,
    dut_io_pads_qspi2_dq_1_o_oval,
    dut_io_pads_qspi2_dq_0_o_oval
  };
  assign qspi2_ui_dq_oe = {
    dut_io_pads_qspi2_dq_3_o_oe,
    dut_io_pads_qspi2_dq_2_o_oe,
    dut_io_pads_qspi2_dq_1_o_oe,
    dut_io_pads_qspi2_dq_0_o_oe
  };
  assign dut_io_pads_qspi2_dq_0_i_ival = qspi2_ui_dq_i[0];
  assign dut_io_pads_qspi2_dq_1_i_ival = qspi2_ui_dq_i[1];
  assign dut_io_pads_qspi2_dq_2_i_ival = qspi2_ui_dq_i[2];
  assign dut_io_pads_qspi2_dq_3_i_ival = qspi2_ui_dq_i[3];
  assign qspi2_sck = dut_io_pads_qspi2_sck_o_oval;

  
endmodule

