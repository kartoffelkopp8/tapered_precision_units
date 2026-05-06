source "../STA/utils.tcl"

# read design 
# 1. Setup & Ecken
define_corners slow fast
read_liberty -corner slow $slow_liberty_files
read_liberty -corner fast $fast_liberty_files

read_verilog posit_mul.v
link_design posit_mul

read_sdc $sdc_file

check_setup

# report_checks -path_delay max -corner slow -to [get_cells r1_*]

puts "--- REPORTING SETUP (SLOW CORNER) ---"
report_checks -path_delay max -corner slow -sort_by_slack 
puts "--- REPORTING HOLD (FAST CORNER) ---"
report_checks -path_delay min -corner fast -sort_by_slack 

write_sdc constraints_sta.sdc
write_sdf -corner slow synth_sdf.sdf
exit
