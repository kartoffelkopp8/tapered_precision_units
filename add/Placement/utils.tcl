set pdk_root           "$::env(PDK_ROOT)"
set pdk                "$::env(PDK)"
set pdk_path           "${pdk_root}/${pdk}"

set current_corner     "typ_1p20V_25C"
set design_name        "posit_add"
set floorplan "../Floorplan/floorplan.odb"

set constraints "../STA/constraints.sdc"
set tielo_pin          "sg13g2_tielo L_LO"
set tiehi_pin          "sg13g2_tiehi L_HI"
set tielo_pin_path     "[lindex $tielo_pin 0]/[lindex $tielo_pin 1]"
set tiehi_pin_path     "[lindex $tiehi_pin 0]/[lindex $tiehi_pin 1]"
set liberty_files "
	${pdk_path}/libs.ref/sg13g2_stdcell/lib/sg13g2_stdcell_${current_corner}.lib
"
#Techlef, cell lef and macro lef
set lef_files "
	${pdk_path}/libs.ref/sg13g2_stdcell/lef/sg13g2_tech.lef
	${pdk_path}/libs.ref/sg13g2_stdcell/lef/sg13g2_stdcell.lef
"
set dont_use_cells {sg13g2_lgcp_1 sg13g2_sighold sg13g2_slgcp_1 sg13g2_dfrbp_2}

proc read_libs {} {
	define_corner ${::current_corner}
	foreach lib ${::liberty_files} {
		read_liberty -corner ${::current_corner} $lib
	}
}

proc read_lefs {} {
	foreach lef ${::lef_files} {
		read_lef $lef
	}
}

proc set_rc {} {
	set_wire_rc -signal -layers {Metal1 Metal2 Metal3 Metal4 Metal5 TopMetal1 TopMetal2}
	set_wire_rc -clock -layers {Metal1 Metal2 Metal3 Metal4 Metal5 TopMetal1 TopMetal2}
}