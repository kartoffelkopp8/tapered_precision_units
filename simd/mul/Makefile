GHDL = ghdl 
GHDL_FLAGS = --std=08

GHDL_SRC = \
utility_pkg.vhd \
posit_adder_simd.vhd \
posit_left_shift_simd.vhd \
posit_right_shift_simd.vhd \
LOD.vhd \
LOD_simd.vhd \
posit_decode_simd.vhd \

TESTBENCH = tb_posit_decode_simd
TEST_FILE = ./sim/tb_posit_decode_simd.vhd

analyze:
	$(GHDL) -a $(GHDL_FLAGS) $(GHDL_SRC)

test: analyze 
	$(GHDL) -a $(GHDL_FLAGS) $(TEST_FILE)
	$(GHDL) -e $(GHDL_FLAGS) $(TESTBENCH)
	$(GHDL) -r $(GHDL_FLAGS) $(TESTBENCH) --vcd=test.vcd
