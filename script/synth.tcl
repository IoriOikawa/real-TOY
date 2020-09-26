source ../script/common.tcl

set_part $::env(PART)

read_verilog -sv [glob ../design/*.sv]

set names [split $::env(IP_NAMES)]
if {[llength $names] > 0} {
   read_ip $names
   generate_target all [get_ips *]
   synth_ip [get_ips *]
}

read_xdc [glob ../constr/timing.xdc]
synth_design -top system_wrap \
   -include_dirs ../include/
write_checkpoint -force post_synth.dcp
report_timing_summary -file report/timing_syn.rpt
report_utilization -file report/util_syn.rpt
