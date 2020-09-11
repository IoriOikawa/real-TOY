module core (
   input clk_i,
   input rst_ni,

   input in_val_i,
   input [15:0] in_data_i,
   output in_rdy_o,

   output out_val_o,
   output [15:0] out_data_o,
   input out_rdy_i,

   mem_rwport.master mem_rw_intf,
   mem_rport.master mem_r_intf[0:`MEM_RPORTS-1],

   input cpu_exec_i, // enable IF
   input pc_wen_i, // manually change PC
   output [7:0] pc_i,
   output [7:0] pc_o,
   output instr_val_o,
   output [15:0] instr_data_o,
   output cpu_running_o // any instr ongoing
);

endmodule
