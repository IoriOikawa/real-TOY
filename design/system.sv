module system (
   input clk_i,

   input btn_load_i,
   output btn_load_o,
   input btn_look_i,
   output btn_look_o,
   input btn_step_i,
   output btn_step_o,
   input btn_run_i,
   output btn_run_o,
   input btn_enter_i,
   output btn_enter_o,
   input btn_stop_i,
   output btn_stop_o,
   input btn_reset_i,
   output btn_reset_o,

   output led_power_o,
   output led_inwait_o,
   output led_ready_o,

   input [7:0] sw_addr_i,
   output [7:0] sw_addr_o,

   input [15:0] sw_data_i,
   output [15:0] sw_data_o,

   output [15:0] number_o
);

   logic rst_n = ~btn_reset_i;
   assign led_power_o = 1;
   assign btn_reset_o = 1;

   mem_rwport mem_rw, mem_rw_core;
   mem_rport mem_r[0:`MEM_RPORTS-1];

   main_mem i_mem (
      .clk_i (clk),
      .rst_ni (rst_n),

      .rw_intf (mem_rw),
      .r_intf (mem_r)
   );

   logic cpu_exec, cpu_running;
   logic instr_val;
   logic [15:0] instr_data;

   core i_core (
      .clk_i (clk),
      .rst_ni (rst_n),

      .in_val_i,
      .in_data_i,
      .in_rdy_o,

      .out_val_o,
      .out_data_o,
      .out_rdy_i,

      .mem_rw_intf (mem_rw_core),
      .mem_r_intf (mem_r),

      .cpu_exec_i (cpu_exec),
      .pc_wen_i (~cpu_running && (btn_load_i || btn_look_i)),
      .pc_i (sw_addr_i),
      .pc_o (sw_addr_o),
      .instr_val_o (instr_val),
      .instr_data_o (instr_data),
      .cpu_running_o (cpu_running)
   );

   assign mem_rw.val = cpu_running
      ? mem_rw_core.val
      : (btn_load_i || btn_look_i);
   assign mem_rw.wen = cpu_running
      ? mem_rw_core.wen
      : btn_load_i;
   assign mem_rw.addr = cpu_running
      ? mem_rw_core.addr
      : sw_addr_i;
   assign mem_rw.wdata = cpu_running
      ? mem_rw_core.wdata
      : sw_data_i;
   assign mem_rw_core.rdata = mem_rw.rdata;
   assign mem_rw_core.rdy = mem_rw.rdy;

   always_ff @(posedge clk, negedge rst_n) begin
      if (~rst_n) begin
         sw_data_o <= 16'b0;
      end else if (instr_val) begin
         sw_data_o <= instr_data;
      end else if (~cpu_running && btn_load_i && mem_rw.rdy) begin
         sw_data_o <= sw_data_i;
      end else if (~cpu_running && btn_look_i && mem_rw.rdy) begin
         sw_data_o <= mem_rw.rdata;
      end
   end

endmodule
