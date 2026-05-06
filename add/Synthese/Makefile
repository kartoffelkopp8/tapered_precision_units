.PHONY: analyze clean help post_sim sta synth
GHDL     = ghdl
GHDLFLAGS = --std=08 
SYNTH_TOOL = yosys 

SYNTH_TCL = synth.tcl

GHDL_SRC_PATH = $(shell pwd)/..

PDK_FILES = ~/Projects/VLSI/PDK/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_stdcell/verilog/sg13g2_stdcell.v \
            ~/Projects/VLSI/PDK/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_stdcell/verilog/sg13g2_udp.v
NETLIST   = posit_add.v
TB        = tb_posit_add.v

VHDL_SRC = \
	$(GHDL_SRC_PATH)/utility_pkg.vhd \
	$(GHDL_SRC_PATH)/LOD_T.vhd \
	$(GHDL_SRC_PATH)/posit_decode.vhd \
	$(GHDL_SRC_PATH)/sticky_shifter.vhd \
	$(GHDL_SRC_PATH)/sticky_shift_det.vhd \
	$(GHDL_SRC_PATH)/better_adder.vhd \
	$(GHDL_SRC_PATH)/posit_add.vhd

help:
	@echo "Verfügbare Ziele:"
	@echo "  make analyze   - VHDL-Dateien analysieren"
	@echo "  make clean     - Zwischendateien löschen"
analyze: 
	$(GHDL) -a $(GHDLFLAGS) $(VHDL_SRC)
synth: analyze
	$(SYNTH_TOOL) $(SYNTH_TCL)
sta: 
	sta ../STA/sta.tcl

post_sim: 

clean:
	rm -f *.o *.cf work-obj*.cf setup_report.txt hold_report.txt synth_sdf.sdf constraints_sta.sdf optimisedTopLevel.txt optimisedTopLevel.json