source ../script/common.tcl

open_checkpoint post_opt.dcp

read_xdc [glob ../constr/pltw-s7.xdc]

place_design -directive AltSpreadLogic_medium
write_checkpoint -force post_place.dcp
report_timing -file report/timing_place.rpt
