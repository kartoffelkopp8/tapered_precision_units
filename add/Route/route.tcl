source "utils.tcl"

read_db $placement

read_lefs 
read_libs 
read_sdc $constraints

set_rc

read_sdc $constraints

# cts
estimate_parasitics -placement
repair_clock_inverters

clock_tree_synthesis -buf_list $clk_buf_cells -repair_clock_nets

report_cts -out_file cts.report

set_propagated_clock [get_clocks i_clk]
estimate_parasitics -placement 
repair_clock_nets 

detailed_placement

repair_timing -match_cell_footprint

detailed_placement
improve_placement -max_displacement {5 1}

global_connect

set_routing_layers -signal Metal2-Metal4 
set_global_routing_layer_adjustment * 0.05
# route
global_route

estimate_parasitics -global_routing 

check_placement
global_route -start_incremental
report_checks -path_delay min_max 

detailed_route -output_maze maze.log -output_drc detailed_routing.rpt

set iters 1

while {[check_antennas] && $iters < 5} {
	repair_antennas
	detailed_route -output_maze maze.log -output_drc detailed_routing.rpt
	incr repair_antennas_iters
}


filler_placement $filler_cells
global_connect
check_placement 

write_db route.odb