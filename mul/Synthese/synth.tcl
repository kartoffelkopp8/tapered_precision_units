source "utils.tcl"
yosys ghdl --std=08 posit_mul
yosys prep -top posit_mul;;
yosys clean
 
yosys flatten
yosys peepopt
yosys uniquify
 
yosys booth

yosys synth -top posit_mul
yosys dfflegalize -cell {$_DFF_PN0_} 0
yosys opt 
yosys opt_clean

yosys share -aggressive
# yosys rename -wire 

# if using 32 bit: use no -dff or moire agressive repair_timing
yosys dfflibmap -liberty $liberty_files
yosys abc -liberty $liberty_files -D 9000 -constr $constraint_file -script "+strash; &get -n; &fraig -x; &put; scorr; fraig; dc2; dretime; strash;
               &get -n; &dch -f; &nf {D}; &put; buffer; upsize {D};
               dnsize {D}; stime -p" -dff 

yosys opt_clean -purge
# best results without all of the specil scripts even with pretty hard constraints
yosys clean -purge
yosys opt -full -purge

yosys write_verilog posit_mul.v
yosys tee -o optimisedTopLevel.txt stat -liberty $liberty_files
yosys tee -o optimisedTopLevel.json stat -json -liberty $liberty_files