set corner "typ_1p20V_25C"
set pdk_path "$::env(PDK_ROOT)/$::env(PDK)"
set synth_path "$::env(HOME)/Projects/VLSI/praktikum/tapered_precision_units/mul/Synthese"  

set liberty_files "$pdk_path/libs.ref/sg13g2_stdcell/lib/sg13g2_stdcell_${corner}.lib"

set lef_files "
	${pdk_path}/libs.ref/sg13g2_stdcell/lef/sg13g2_tech.lef
	${pdk_path}/libs.ref/sg13g2_stdcell/lef/sg13g2_stdcell.lef
    "

# Script-Verzeichnis (wo utils.tcl liegt)
set constraint_file "$synth_path/constraints.txt"

puts $liberty_files
puts $constraint_file

set std_cell_verilog "~/Projects/VLSI/PDK/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_stdcell/verilog/sg13g2_stdcell.v"

