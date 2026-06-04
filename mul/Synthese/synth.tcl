# 8 bt posit_add -> "area":7573.078800,"sequential_area":  3086.294400, 32 bit "area": 36814.629600,"sequential_area": 9454.838400,
source "utils.tcl"
set toplevel takum_mul

yosys ghdl -gG_N=32 --std=08 $toplevel
yosys prep -top $toplevel;;
yosys clean

yosys flatten
yosys peepopt
yosys uniquify

yosys clean_zerowidth
 
yosys synth -top $toplevel
yosys dfflegalize -cell {$_DFF_PN0_} 0
yosys opt 
yosys opt_clean

# high effort cleaner
# yosys freduce
yosys clean
yosys share -aggressive
# yosys rename -wire 

# if using 32 bit: use no -dff or moire agressive repair_timing &nf -R 50 for excellent area, but setup time bad
yosys dfflibmap -liberty $liberty_files

#  rule for over 32 bits
# yosys abc -liberty $liberty_files -D 9000 -constr $constraint_file -script "+strash; &get -n; &fraig -x; &put; scorr; fraig; dc2; dretime; strash;
#                &get -n; &dch -f; &nf {D} -a; &put;  buffer; upsize {D};
#                dnsize {D};upsize {D};dnsize {D}; upsize {D};dnsize {D}; stime -p" -dff

# rule for 32 bits and below
yosys abc -liberty $liberty_files -D 9000 -constr $constraint_file -script "+strash; &get -n; &fraig -x; &put; scorr; fraig; dc2; dretime; strash;
               &get -n; &dch -f; &nf -A 10 -F 20 {D} -a; &put; topo; buffer; upsize -R 20 -W 10 -v {D};
               dnsize {D};upsize {D};dnsize {D}; upsize {D};dnsize {D}; stime -p" 

yosys opt_clean -purge
# best results without all of the specil scripts even with pretty hard constraints
yosys clean -purge
yosys opt -full -purge

yosys write_verilog $toplevel.v
yosys tee -o takum_mul_flattened.txt stat -liberty $liberty_files
yosys tee -o takum_mul_flattened.json stat -json -liberty $liberty_files
