set script_path /home/felix/Projects/VLSI/praktikum/posit-arithmetic/add/STA/

set fast_corner "fast_1p65V_m40C"
set slow_corner "slow_1p35V_125C"
set pdk_path "$::env(PDK_ROOT)/$::env(PDK)"

set fast_liberty_files "$pdk_path/libs.ref/sg13g2_stdcell/lib/sg13g2_stdcell_${fast_corner}.lib"
set slow_liberty_files "$pdk_path/libs.ref/sg13g2_stdcell/lib/sg13g2_stdcell_${slow_corner}.lib"

set design_src "$script_path/../Synthese/posit_add.v"
set sdc_file "$script_path/constraints.sdc"
