set netlist "../Synthese/posit_add.v"

source "utils.tcl"

set deviation 5

read_design

set_rc 

# buffer_ports

initialize_floorplan -site $site -utilization 65 -core_space 30
make_tracks

insert_tiecells $tielo_pin_path
insert_tiecells $tiehi_pin_path

add_global_connection -net $power_net -pin_pattern $power_regex -power
add_global_connection -net $gnd_net -pin_pattern $gnd_regex -ground 
global_connect

set_voltage_domain -power $power_net -ground $gnd_net

define_pdn_grid -name "Core" -pins {Metal4}

# define the rails 
add_pdn_stripe -layer "Metal1" -followpins -grid "Core" -width 0.44 -nets "VDD VSS"
add_pdn_stripe -layer "Metal4" -grid "Core" -width 2.84 -spacing 2.84 -pitch 12 -nets "VDD VSS"

add_pdn_connect -layers {Metal1 Metal4} -grid "Core"


pdngen

check_power_grid -net $power_net -floorplanning -dont_require_terminals
check_power_grid -net $gnd_net -floorplanning -dont_require_terminals


# place pins 
puts "placing pins\n\n"


set coords [ord::get_die_area]
set middle [expr ([lindex $coords 2] - [lindex $coords 0]) / 2]
set start [expr {$middle - $deviation}]
set end   [expr {$middle + $deviation}]
set_io_pin_constraint -pin_names [get_ports i_clk] -region top:$start-$end

set op0 [get_ports i_operand_0]
set op1 [get_ports i_operand_1]
set res [get_ports o_*]
 
set_io_pin_constraint -pin_names $op0 -region left:[lindex $coords 0]-$middle -group
set_io_pin_constraint -pin_names $op1 -region left:$middle-[lindex $coords 2] -group
set_io_pin_constraint -pin_names [get_ports i_enable] -region bottom:*

set_io_pin_constraint -pin_names $res -region right:* -group

place_pins -hor_layers {Metal3} -ver_layers {Metal2}

check_power_grid -net $power_net -floorplanning 
check_power_grid -net $gnd_net -floorplanning 

write_db floorplan.odb
exit