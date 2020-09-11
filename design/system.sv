`include "global.svh"

module system (
   input logic clk_i,

   input logic btn_load_i,
   output logic btn_load_o,
   input logic btn_look_i,
   output logic btn_look_o,
   input logic btn_step_i,
   output logic btn_step_o,
   input logic btn_run_i,
   output logic btn_run_o,
   input logic btn_enter_i,
   output logic btn_enter_o,
   input logic btn_stop_i,
   output logic btn_stop_o,
   input logic btn_reset_i,
   output logic btn_reset_o,

   output logic led_power_o,
   output logic led_inwait_o,
   output logic led_ready_o,

   input logic [7:0] sw_addr_i,
   output logic [7:0] sw_addr_o,

   input logic [15:0] sw_data_i,
   output logic [15:0] sw_data_o,

   output logic stdout_val_o,
   output logic [15:0] stdout_data_o,
   input logic stdout_rdy_i
);

   logic rst_n;
   assign rst_n = ~btn_reset_i;
   assign led_power_o = rst_n;

   mem_rwport mem_rw, mem_rw_core;
   mem_rport mem_r[0:`MEM_RPORTS-1];

   main_mem i_mem (
      .clk_i,
      .rst_ni (rst_n),

      .rw_intf (mem_rw),
      .r_intf (mem_r)
   );

   logic core_rst_n, cpu_exec, pc_wen, cpu_done;
   logic instr_val;
   logic [15:0] instr_data;

   stdio raw_stdin, pipe_stdin, stdout;

   fifo i_stdin_fifo (
      .clk_i,
      .rst_ni (rst_n),
      .stdin (raw_stdin),
      .stdout (pipe_stdin)
   );

   core i_core (
      .clk_i,
      .arst_ni (rst_n),
      .rst_ni (core_rst_n),

      .stdin_intf (pipe_stdin),
      .stdout_intf (stdout),

      .mem_rw_intf (mem_rw_core),
      .mem_r_intf (mem_r),

      .cpu_exec_i (cpu_exec),
      .pc_wen_i (pc_wen),
      .pc_i (sw_addr_i),
      .pc_o (sw_addr_o),
      .instr_val_o (instr_val),
      .instr_data_o (instr_data),
      .cpu_done_o (cpu_done)
   );

   logic inwait;
   assign inwait = ~pipe_stdin.val && pipe_stdin.rdy;
   assign raw_stdin.val = btn_enter_i;
   assign raw_stdin.data = sw_data_i;
   assign stdout_val_o = stdout.val;
   assign stdout_data_o = stdout.data;
   assign stdout.rdy = stdout_rdy_i;

   logic [2:0] state, state_next;
   always_ff @(posedge clk_i, negedge rst_n) begin
      if (~rst_n) begin
         state <= 0;
      end else begin
         state <= state_next;
      end
   end
   always_comb begin
      state_next = state;
      btn_load_o = 0;
      btn_look_o = 0;
      btn_step_o = 0;
      btn_run_o = 0;
      btn_enter_o = 0;
      btn_stop_o = 0;
      btn_reset_o = 0;
      led_inwait_o = 0;
      led_ready_o = 0;
      core_rst_n = 0;
      cpu_exec = 0;
      instr_val = 0;
      unique case (state)
         0: // ready
            begin
               btn_load_o = 1;
               btn_look_o = 1;
               btn_step_o = 1;
               btn_run_o = 1;
               btn_enter_o = raw_stdin.rdy;
               btn_reset_o = 1;
               led_ready_o = 1;
               if (btn_run_i) begin
                  state_next = 2;
               end else if (btn_step_i) begin
                  state_next = 1;
               end
            end
         1: // step
            begin
               core_rst_n = 1;
               cpu_exec = 1;
               state_next = 4;
            end
         2: // run
            begin
               btn_stop_o = 1;
               core_rst_n = 1;
               cpu_exec = 1;
               if (cpu_done) begin // due to halt
                  state_next = 0;
               end else if (inwait) begin
                  state_next = 3;
               end else if (btn_stop_i) begin
                  state_next = 4;
               end
            end
         3: // inwait
            begin
               btn_load_o = 1;
               btn_look_o = 1;
               btn_enter_o = 1;
               btn_reset_o = 1;
               if (btn_enter_i) begin
                  state_next = 0;
               end
            end
         4: // post-run
            begin
               core_rst_n = 1;
               if (cpu_done) begin
                  state_next = 0;
               end else if (inwait) begin
                  state_next = 3;
               end
            end
      endcase
   end

   assign pc_wen = cpu_done && (btn_load_i || btn_look_i);
   assign mem_rw.val = ~cpu_done
      ? mem_rw_core.val
      : (btn_load_i || btn_look_i);
   assign mem_rw.wen = ~cpu_done
      ? mem_rw_core.wen
      : btn_load_i;
   assign mem_rw.addr = ~cpu_done
      ? mem_rw_core.addr
      : sw_addr_i;
   assign mem_rw.wdata = ~cpu_done
      ? mem_rw_core.wdata
      : sw_data_i;
   assign mem_rw_core.rdata = mem_rw.rdata;
   assign mem_rw_core.rdy = mem_rw.rdy;

   logic tmp_look_r;
   always_ff @(posedge clk_i, negedge rst_n) begin
      if (~rst_n) begin
         tmp_look_r <= 0;
      end else begin
         tmp_look_r <= cpu_done && btn_look_i && mem_rw.rdy;
      end
   end
   always_ff @(posedge clk_i, negedge rst_n) begin
      if (~rst_n) begin
         sw_data_o <= 16'b0;
      end else if (instr_val) begin
         sw_data_o <= instr_data;
      end else if (cpu_done && btn_load_i && mem_rw.rdy) begin
         sw_data_o <= sw_data_i;
      end else if (tmp_look_r) begin
         sw_data_o <= mem_rw.rdata;
      end
   end

endmodule
