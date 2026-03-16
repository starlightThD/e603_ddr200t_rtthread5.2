VIVADO ?= vivado
VIVADOFLAGS := \
	-nojournal -mode batch \
	-source script/board.tcl \
	-source script/prologue.tcl

VIVADOFLAGS_SETUP := \
	-nojournal -mode gui \
	-source script/board.tcl \
	-source script/prologue_setup.tcl

# Path to a program in raw binary format to be flashed into the address that the
# bootrom jumps to.
FLASHED_PROGRAM ?=

bit := obj/${BITFILE_NAME}
$(bit): script/impl.tcl  script/init.tcl
	VSRCS="$(VSRCS)" EXTRA_VSRCS="$(EXTRA_VSRCS)" $(VIVADO) $(VIVADOFLAGS) -source script/init.tcl -source script/impl.tcl
	#vivado -mode tcl

.PHONY: ela
ela: script/elaborate.tcl  script/init.tcl
	VSRCS="$(VSRCS)" EXTRA_VSRCS="$(EXTRA_VSRCS)" $(VIVADO) $(VIVADOFLAGS) -source script/init.tcl -source script/elaborate.tcl

.PHONY: syn
syn: script/syn.tcl  script/init.tcl
	VSRCS="$(VSRCS)" EXTRA_VSRCS="$(EXTRA_VSRCS)" $(VIVADO) $(VIVADOFLAGS) -source script/init.tcl -source script/syn.tcl

.PHONY: bit
bit: $(bit)

mcs := obj/${MCSFILE_NAME}
$(mcs): $(bit)
	$(VIVADO) $(VIVADOFLAGS) script/cfgmem.tcl -tclargs $@ $^ $(FLASHED_PROGRAM)

.PHONY: mcs
mcs: $(mcs)

bit_name = $(firstword $(wildcard obj/*.bit))
mcs_name = $(patsubst %.bit,%.mcs,$(bit_name))

only_mcs:
	$(VIVADO) $(VIVADOFLAGS) script/cfgmem.tcl -tclargs $(mcs_name) $(bit_name) $(FLASHED_PROGRAM)


.PHONY: setup
setup:
	VSRCS="$(VSRCS)" EXTRA_VSRCS="$(EXTRA_VSRCS)" $(VIVADO) $(VIVADOFLAGS_SETUP) -source script/init_setup.tcl


.PHONY: clean
clean::
	rm -rf -- .Xil .ip_user_files *.os obj src/generated usage_statistics_webtalk.xml usage_statistics_webtalk.html *.log
