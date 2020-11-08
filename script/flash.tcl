source ../script/common.tcl

open_hw_manager
connect_hw_server -url 192.168.1.67:3121
current_hw_target [get_hw_targets */xilinx_tcf/Digilent/002019A9C494A]
open_hw_target

set dev [get_hw_devices xc7s25_0]

current_hw_device $dev
refresh_hw_device $dev

write_cfgmem -force -format MCS -size 32 -interface SPIx4 \
   -loadbit "up 0x0 output.bit" output.mcs

set part [get_cfgmem_parts -of_objects [current_hw_device] mx25l3233f-spi-x1_x2_x4]
create_hw_cfgmem -hw_device $dev $part
set_property PROGRAM.ADDRESS_RANGE {use_file} [current_hw_cfgmem]
set_property PROGRAM.FILES {output.mcs} [current_hw_cfgmem]
set_property PROGRAM.PRM_FILE {} [current_hw_cfgmem]
set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} [current_hw_cfgmem]
set_property PROGRAM.BLANK_CHECK 1 [current_hw_cfgmem]
set_property PROGRAM.ERASE 1 [current_hw_cfgmem]
set_property PROGRAM.CFG_PROGRAM 1 [current_hw_cfgmem]
set_property PROGRAM.VERIFY 1 [current_hw_cfgmem]
set_property PROGRAM.CHECKSUM 0 [current_hw_cfgmem]

create_hw_bitstream -hw_device $dev [get_property PROGRAM.HW_CFGMEM_BITFILE $dev ]
program_hw_devices $dev
refresh_hw_device $dev

program_hw_cfgmem -hw_cfgmem [current_hw_cfgmem]
