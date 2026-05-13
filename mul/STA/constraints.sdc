set clock_port "i_clk"
set clock_period 10
# Values for uncertainty, transition and derating are set equally to the values from the skywater pdk
# This seems reasonable, as booth are manufactured on a 130 nm node
set clock_uncertainty 0.05
set clock_transition 0.02
set timing_derate 5

set delay_constraint 5
set max_fanout 10
set clk_pins [get_ports $clock_port]

puts "\[INFO] Using clock $clock_port…"
create_clock {*}$clk_pins -name $clock_port -period ${clock_period}

set input_delay_value [expr ${clock_period} * ${delay_constraint} / 100]
set output_delay_value [expr ${clock_period} * ${delay_constraint} / 100]
puts "\[INFO] Setting output delay to: $output_delay_value"
puts "\[INFO] Setting input delay to: $input_delay_value"

set_max_fanout ${max_fanout} [current_design]
#set_max_transition $::env(MAX_TRANSITION_CONSTRAINT) [current_design]
#set_max_capacitance $::env(MAX_CAPACITANCE_CONSTRAINT) [current_design]

set clk_input [get_port $clock_port]
set clk_indx [lsearch [all_inputs] $clk_input]
set all_inputs_wo_clk [lreplace [all_inputs] $clk_indx $clk_indx ""]

#set rst_input [get_port rst_n]
#set rst_indx [lsearch [all_inputs] $rst_input]
#set all_inputs_wo_clk_rst [lreplace $all_inputs_wo_clk $rst_indx $rst_indx ""]
# Design does not have a reset
set all_inputs_wo_clk_rst $all_inputs_wo_clk

# correct resetn
set clocks [get_clocks $clock_port]

set_input_delay $input_delay_value -clock $clocks $all_inputs_wo_clk_rst
set_output_delay $output_delay_value -clock $clocks [all_outputs]

set_driving_cell -lib_cell sg13g2_inv_2 -pin Y $all_inputs_wo_clk_rst
set_driving_cell -lib_cell sg13g2_inv_16 -pin Y $clk_input

# Input Capacity of largest inverter according to constraints for synth
set cap_load 0.0461309
set_load $cap_load [all_outputs]

set_clock_uncertainty ${clock_uncertainty} $clocks

set_clock_transition ${clock_transition} $clocks

set_timing_derate -early [expr 1-[expr ${timing_derate} / 100]]
set_timing_derate -late [expr 1+[expr ${timing_derate} / 100]]
