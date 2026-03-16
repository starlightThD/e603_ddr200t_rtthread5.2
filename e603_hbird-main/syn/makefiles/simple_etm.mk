export

PT_TAG                           := pt_$(SYN_TAG)
PT_ETM                           := 1

.PHONY: pre_setm setm setm_clean

pre_setm:
	@mkdir -p $(PT_TAG)
	@mkdir -p $(PT_TAG)/reports
	@mkdir -p $(PT_TAG)/results

setm: pre_setm
	@pt_shell -f ./run_tcl/simple_etm.tcl -output_log_file ./$(PT_TAG)/simple_etm_run.log
	@mkdir -p dblib
ifeq ($(DFT_EN), 0)
	@rm -rf dblib/$(TOP).lib dblib/$(TOP).db*
	@cp -f $(PT_TAG)/results/$(TOP).lib ./dblib/
	@cp -f $(PT_TAG)/results/$(TOP)_lib.db ./dblib/$(TOP).db
endif
ifeq ($(DFT_EN), 1)
	@rm -rf dblib/$(TOP)_dft.lib dblib/$(TOP)_dft.db*
	@cp -f $(PT_TAG)/results/$(TOP).lib ./dblib/$(TOP)_dft.lib
	@cp -f $(PT_TAG)/results/$(TOP)_lib.db ./dblib/$(TOP)_dft.db
endif


setm_clean:
	@rm -rf $(PT_TAG)*

