source "utils.tcl"

read_db $floorplan

read_lefs 
read_libs 
read_sdc $constraints

repair_tie_fanout $tielo_pin_path
repair_tie_fanout $tiehi_pin_path

repair_design -pre_placement

global_placement -routability_driven

set_rc
estimate_parasitics -placement

remove_buffer 
repair_design 
repair_timing

global_placement -timing_driven -density 0.6 -pad_left 1 -pad_right 1

set_placement_padding -global -left 1 -right 1

report_checks

detailed_placement -report_file_name report_plc.json

optimize_mirroring

improve_placement -max_displacement 5
estimate_parasitics -placement 
repair_design
repair_timing -setup
global_route


report_checks -path_delay max

write_db placement.odb

exit