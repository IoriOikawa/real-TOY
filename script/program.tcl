source ../script/common.tcl

open_hw_manager
connect_hw_server -url 192.168.1.67:3121
current_hw_target [get_hw_targets */xilinx_tcf/Digilent/002019A9C494A]
open_hw_target

current_hw_device [get_hw_devices xc7s25_0]
refresh_hw_device -update_hw_probes false [get_hw_devices xc7s25_0]
set_property PROGRAM.FILE {output.bit} [get_hw_devices xc7s25_0]
if {[file exists output.ltx]} {
    set_property PROBES.FILE {output.ltx} [get_hw_devices xc7s25_0]
}

program_hw_devices [get_hw_devices xc7s25_0]
refresh_hw_device [get_hw_devices xc7s25_0]
