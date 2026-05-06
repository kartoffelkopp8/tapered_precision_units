.PHONY: cpp test analyze clean help analyze_tb

UNIVERSAL_PATH = ~/Projects/VLSI/praktikum/tools/universal/include/sw/ 
GHDL_SRC_PATH := $(shell pwd)/..

CC := g++
GHDL = ghdl
GHDLFLAGS = --std=08
CXXFLAGS = -std=c++20 -O3 -I$(UNIVERSAL_PATH)
LDFLAGS  = -lpthread

# SRCS     = $(wildcard *.cpp)
# TARGETS  = $(SRCS:.cpp=)

CPP_PROG = gen_testvectors

TESTBENCH_FILE = tb_posit_add.vhd
TESTBENCH_TOP_ENTITY = tb_posit_add

# sources of vhdl project
GHDL_SRC = \
	$(GHDL_SRC_PATH)/utility_pkg.vhd \
	$(GHDL_SRC_PATH)/LOD_T.vhd \
	$(GHDL_SRC_PATH)/posit_decode.vhd \
	$(GHDL_SRC_PATH)/sticky_shift_det.vhd \
	$(GHDL_SRC_PATH)/sticky_shifter.vhd \
	$(GHDL_SRC_PATH)/better_adder.vhd \
	$(GHDL_SRC_PATH)/posit_add.vhd

help: 
	@echo "available targets:"
	@echo "test -> simulates the posit_adder with the given testbench"
	@echo "analyze -> analyzes all sources for synthesys"
	@echo "cpp -> compile cpp sources"
	@echo "clean -> removes buildfiles"


test: analyze analyze_tb
	$(GHDL) -e $(GHDLFLAGS) $(TESTBENCH_TOP_ENTITY)
	$(GHDL) -r $(GHDLFLAGS) $(TESTBENCH_TOP_ENTITY)

analyze: 
	$(GHDL) -a $(GHDLFLAGS) $(GHDL_SRC)

analyze_tb:
	$(GHDL) -a $(GHDLFLAGS) $(TESTBENCH_FILE)


cpp: $(CPP_PROG)
	@echo "✅ $(CPP_PROG) kompiliert"

$(CPP_PROG): $(CPP_PROG).cpp
	$(CXX) $(CXXFLAGS) $< -o $@ $(LDFLAGS)

clean:
	rm -f *.o *.cf work-obj*.cf