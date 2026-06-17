
SOURCE := \
 ../utility_pkg.vhd \
 ../takum_shift_left.vhd \
 ../takum_shift_right.vhd \
 ../takum_shift_right_sticky.vhd \
 ../takum_predecoder.vhd \
 ../LOD.vhd \
 ../takum_linear_decoder.vhd \
 ../takum_logarithmic_encoder.vhd \
 ../takum_linear_encoder.vhd \
 ../takum_add.vhd 

GHDL     = ghdl
GHDLFLAGS = --std=08 

TBFILE := ../sim/tb_takum_add.vhd
TB := tb_takum_add

analyze_stolen: 
	$(GHDL) -a $(GHDLFLAGS) $(STOLENSOURCE)

synth_stolen: analyze_stolen
	yosys synth.tcl

synth: analyze 
	yosys synth.tcl

analyze: 
	$(GHDL) -a $(GHDLFLAGS) $(SOURCE)

sta: 
	sta ../STA/sta.tcl

test: analyze
	$(GHDL) -a $(GHDLFLAGS) $(TBFILE)
	$(GHDL) -e $(GHDLFLAGS) $(TB)
	$(GHDL) -r $(GHDLFLAGS) $(TB) --vcd=test.vcd 2>&1 | tee simulation_log.txt