export

FM_TAG                           := fm_$(SYN_TAG)
INTF_MODELS                      := None

.PHONY: pre_fm fm_net2rtl fm_open_net2rtl fm_net2net fm_open_net2net fm_clean

pre_fm:
	@mkdir -p $(FM_TAG)
	@mkdir -p $(FM_TAG)/reports
	@mkdir -p $(FM_TAG)/results

fm_net2rtl: pre_fm
	@fm_shell -file ./run_tcl/fm_net_vs_rtl.tcl -work_path ./$(FM_TAG) |& tee ./$(FM_TAG)/fm_run.log

fm_open_net2rtl:
	@fm_shell -gui -session ./$(FM_TAG)/$(TOP).net_vs_rtl.session.fss &

fm_net2net: pre_fm
	@fm_shell -file ./run_tcl/fm_net_vs_net.tcl -work_path ./$(FM_TAG) |& tee ./$(FM_TAG)/fm_run.log

fm_open_net2net:
	@fm_shell -gui -session ./$(FM_TAG)/$(TOP).net_vs_net.session.fss &

fm_clean:
	@rm -rf $(FM_TAG)*

