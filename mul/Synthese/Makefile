STOLENSOURCE := \
 ../stolen/predecoder.vhd \
 ../stolen/decoder_logarithmic.vhd

SOURCE := \
 ../utility_pkg.vhd \
 ../takum_shift_right.vhd \
 ../takum_shift_left.vhd \
 ../takum_logarithmic_decoder.vhd \
 ../LOD.vhd \
 ../takum_logarithmic_encoder.vhd \
 ../takum_mul.vhd 

GHDL     = ghdl
GHDLFLAGS = --std=08 

TBFILE := ../sim/tb_takum_mul.vhd
TB := tb_takum_mul

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
	$(GHDL) -r $(GHDLFLAGS) $(TB) --vcd=test.vcd