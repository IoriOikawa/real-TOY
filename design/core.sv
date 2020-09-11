interface stdio
   logic val,
   logic [15:0] data,
   logic rdy,
   modport in (
      input val,
      input data,
      output rdy
   );
   modport out (
      output val,
      output data,
      input rdy
   );
endinterface

module core (
   input clk_i,
   input rst_ni,

   stdio.in stdin_intf,
   stdio.out stdout_intf,

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
