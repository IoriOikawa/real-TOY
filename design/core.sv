`include "global.svh"

module core (
   input logic clk_i,
   input logic arst_ni, // reset architectural stuff
   input logic rst_ni, // reset microarchitectural stuff

   stdio.in stdin_intf,
   stdio.out stdout_intf,

   mem_rwport.master mem_rw_intf,
   mem_rport.master mem_r_intf[0:`MEM_RPORTS-1],

   input logic [1:0] cpu_exec_i, // 0: disable IF  1: enable IF  2: single step
   input logic pc_wen_i, // manually change PC
   input logic [7:0] pc_i,
   output logic [7:0] pc_o,
   output logic instr_val_o,
   output logic [15:0] instr_data_o,
   output logic cpu_done_o // no more in-flight instr
);

   logic valid_if, valid_dx, valid_wb;
   logic stall_if, stall_dx, stall_wb;

   // =====================
   // if
   // =====================

   logic jump_en_dx;
   logic [7:0] jump_targ_dx;
   logic halt_dx;
   logic [7:0] pc_if;
   always_ff @(posedge clk_i, negedge arst_ni) begin
      if (~arst_ni) begin
         pc_if <= 8'h10;
      end else if (~rst_ni) begin
         if (valid_dx) begin
            pc_if <= virgin_pc_dx;
         end
      end else if (pc_wen_i) begin
         pc_if <= pc_i;
      end else if (halt_dx) begin
         // do nothing
      end else if (jump_en_dx) begin
         pc_if <= jump_targ_dx;
      end else if (cpu_exec_i == 1) begin
         pc_if <= pc_if + `SSC_IF;
      end else if (cpu_exec_i == 2) begin
         pc_if <= pc_if + 1;
      end
   end
   assign pc_o = pc_if;

   logic [`SSC_IF-1:0] ready_if, ready_r_if;
   logic [15:0] mem_buf_if[0:`SSC_IF-1];
   logic [15:0] instr_dx[0:`SSC_IF-1];

   assign stall_if = ~&ready_if || stall_dx;
   always_ff @(posedge clk_i) begin
      if (~rst_ni) begin
         valid_if <= 0;
         ready_r_if <= '0;
      end else if (halt_dx) begin
         valid_if <= 0;
         ready_r_if <= '0;
      end else if (stall_if) begin
         valid_if <= &ready_if;
         ready_r_if <= ready_if;
      end else if (cpu_exec_i == 1) begin
         valid_if <= 1;
         ready_r_if <= '0;
      end else if (cpu_exec_i == 2) begin
         valid_if <= ~(valid_if || valid_dx || valid_wb);
         ready_r_if <= '0;
      end
   end

   logic [7:0] pc_dx[0:`SSC_IF-1];

   generate
   for (genvar gi = 0; gi < `SSC_IF; gi++) begin : g_if
      always_comb begin
         pc_dx[gi] = pc_if + gi;
         mem_r_intf[gi].addr = pc_if + gi;
         mem_r_intf[gi].val = 0;
         ready_if[gi] = 0;
         if (~rst_ni) begin
            // do nothing
         end else if (cpu_exec_i == 1 || cpu_exec_i == 2 && ~|gi) begin
            if (stall_dx && ready_r_if[gi]) begin
               mem_r_intf[gi].val = 0;
               ready_if[gi] = 1;
            end else begin
               mem_r_intf[gi].val = 1;
               ready_if[gi] = mem_r_intf[gi].rdy;
            end
         end else if (cpu_exec_i == 2 && |gi) begin
            ready_if[gi] = 1;
         end
      end
      always_ff @(posedge clk_i) begin
         if (~rst_ni) begin
            mem_buf_if[gi] <= 0;
         end else if (mem_r_intf[gi].val && mem_r_intf[gi].rdy) begin
            mem_buf_if[gi] <= mem_r_intf[gi].rdata;
         end
      end
      always_ff @(posedge clk_i) begin
         if (~rst_ni) begin
            instr_dx[gi] <= 0;
         end else if (~&ready_if) begin
            // do nothing
         end else if (ready_r_if[gi]) begin
            instr_dx[gi] <= mem_buf_if[gi];
         end else begin
            instr_dx[gi] <= mem_r_intf[gi].rdata;
         end
      end
   end
   endgenerate

   // =====================
   // dx
   // =====================

   core_arf_r arf_r_dx[0:2*(`SSC_EX+`SSC_MEM)-1];
   core_arf_w arf_w_wb[0:`SSC_EX+`SSC_MEM-1];
   core_arf i_arf (
      .clk_i,
      .arst_ni,
      .r_intf (arf_r_dx),
      .w_intf (arf_w_wb)
   );

   logic [7:0] virgin_pc_dx;
   logic [3:0] rd_dx[0:`SSC_EX+`SSC_MEM-1], rd_wb[0:`SSC_EX+`SSC_MEM-1];
   logic [7:0] addr_dx[0:`SSC_EX-1];

   logic arf_wen_dx[0:`SSC_EX+`SSC_MEM-1], arf_wen_wb[0:`SSC_EX+`SSC_MEM-1];
   logic [15:0] alu_wb[0:`SSC_EX-1], lsu_wb;
   core_decoder_cascade decoder_cas_dx[0:`SSC_EX];
   core_decoder_preempt decoder_preempt_dx[0:`SSC_EX-1];

   logic [15:0] r1_byp_dx[0:`SSC_EX-1], r2_byp_dx[0:`SSC_EX-1];

   logic lsu_val_dx, lsu_wen_dx, lsu_rdy_dx;
   logic [7:0] lsu_addr_dx;
   logic [15:0] lsu_data_dx;
   logic [`SSC_EX-1:0] tmp_virgin_dx;
   logic [`SSC_EX-1:0] tmp_jump_en_dx, tmp_jump_kind_dx;
   logic [`SSC_EX-1:0] tmp_lsu_en_dx, tmp_lsu_wen_dx, tmp_lsu_kind_dx;
   logic [`SSC_EX-1:0] tmp_halt_dx;
   always_comb begin
      jump_en_dx = 0;
      jump_targ_dx = '0;
      lsu_val_dx = 0;
      lsu_wen_dx = 0;
      lsu_addr_dx = '0;
      lsu_data_dx = '0;
      halt_dx = 0;
      instr_data_o = '0;
      virgin_pc_dx = '0;
      for (integer i = 0; i < `SSC_EX; i++) begin
         if (tmp_virgin_dx[i]) begin
            instr_data_o = instr_dx[i];
            virgin_pc_dx = pc_dx[i];
         end
         if (tmp_jump_en_dx[i]) begin
            jump_en_dx = 1;
            jump_targ_dx = tmp_jump_kind_dx[i] ? addr_dx[i] : r2_byp_dx[i][7:0];
         end
         if (tmp_lsu_en_dx[i]) begin
            lsu_val_dx = 1;
            lsu_wen_dx = tmp_lsu_wen_dx[i];
            lsu_addr_dx = tmp_lsu_kind_dx[i] ? addr_dx[i] : r2_byp_dx[i][7:0];
            lsu_data_dx = r1_byp_dx[i];
         end
         if (tmp_halt_dx[i]) begin
            halt_dx = 1;
         end
      end
   end
   assign instr_val_o = valid_dx && ~stall_dx;

   assign decoder_cas_dx[0].en = valid_dx;
   assign decoder_cas_dx[0].virgin = 1;
   assign decoder_cas_dx[0].dirty = 16'b0;
   assign decoder_cas_dx[0].stall = stall_wb;
   assign stall_dx = decoder_cas_dx[`SSC_EX].stall || lsu_val_dx && ~lsu_rdy_dx;
   always_ff @(posedge clk_i) begin
      if (~rst_ni) begin
         valid_dx <= 0;
      end else if (halt_dx || jump_en_dx) begin
         valid_dx <= 0;
      end else if (valid_if && ~stall_if && ~jump_en_dx) begin
         valid_dx <= 1;
      end else if (~stall_dx) begin
         valid_dx <= 0;
      end
   end

   assign arf_wen_dx[`SSC_EX] = lsu_val_dx && lsu_wen_dx;
   core_lsu i_lsu (
      .clk_i,
      .rst_ni,

      .val_i (lsu_val_dx),
      .wen_i (lsu_wen_dx),
      .addr_i (lsu_addr_dx),
      .data_i (lsu_data_dx),
      .data_ro (lsu_wb),
      .rdy_o (lsu_rdy_dx),

      .stdin_intf,
      .stdout_intf,
      .mem_rw_intf
   );

   generate
      for (genvar gi = 0; gi < `SSC_EX; gi++) begin : g_dx
         always_comb begin
            assign tmp_virgin_dx[gi] = decoder_cas_dx[gi].virgin && ~decoder_cas_dx[gi+1].virgin;
            assign tmp_jump_en_dx[gi] = decoder_preempt_dx[gi].jump_en;
            assign tmp_jump_kind_dx[gi] = decoder_preempt_dx[gi].jump_kind;
            assign tmp_lsu_en_dx[gi] = decoder_preempt_dx[gi].lsu_en;
            assign tmp_lsu_wen_dx[gi] = decoder_preempt_dx[gi].lsu_wen;
            assign tmp_lsu_kind_dx[gi] = decoder_preempt_dx[gi].lsu_kind;
            assign tmp_halt_dx[gi] = decoder_preempt_dx[gi].halt;
         end

         logic [3:0] r1_dx;
         logic [3:0] r2_dx;
         logic en_dx, en_next_dx;
         logic arf_kind_dx;
         logic alu_kind_dx;
         logic [2:0] alu_op_dx;

         always_ff @(posedge clk_i) begin
            if (~rst_ni) begin
               en_dx <= 0;
            end else if (halt_dx || jump_en_dx) begin
               en_dx <= 0;
            end else if (valid_if && ~stall_dx) begin
               en_dx <= cpu_exec_i == 1 || ~|gi;
            end else if (~(decoder_preempt_dx[gi].lsu_en && ~lsu_rdy_dx)) begin
               en_dx <= en_next_dx;
            end
         end

         always_comb begin
            if (arf_kind_dx) begin
               r1_dx = instr_dx[gi][11:8];
            end else begin
               r1_dx = instr_dx[gi][7:4];
            end
            r2_dx = instr_dx[gi][3:0];
            rd_dx[gi] = instr_dx[gi][11:8];
            addr_dx[gi] = instr_dx[gi][7:0];

            arf_r_dx[2*gi].addr = r1_dx;
            arf_r_dx[2*gi+1].addr = r2_dx;
         end

         always_comb begin
            r1_byp_dx[gi] = arf_r_dx[2*gi].data;
            if (valid_wb) begin
               for (integer i = 0; i < `SSC_EX; i++) begin
                  if (rd_wb[i] == r1_dx && arf_wen_wb[i]) begin
                     r1_byp_dx[gi] = alu_wb[i];
                  end
               end
               if (rd_wb[`SSC_EX] == r1_dx && arf_wen_wb[`SSC_EX]) begin
                  r1_byp_dx[gi] = lsu_wb;
               end
            end

            r2_byp_dx[gi] = arf_r_dx[2*gi+1].data;
            if (valid_wb) begin
               for (integer i = 0; i < `SSC_EX; i++) begin
                  if (rd_wb[i] == r2_dx && arf_wen_wb[i]) begin
                     r2_byp_dx[gi] = alu_wb[i];
                  end
               end
               if (rd_wb[`SSC_EX] == r2_dx && arf_wen_wb[`SSC_EX]) begin
                  r2_byp_dx[gi] = lsu_wb;
               end
            end
         end

         core_decoder i_decoder (
            .instr_i (instr_dx[gi]),

            .my_en_i (en_dx),
            .my_en_o (en_next_dx),
            .up_intf (decoder_cas_dx[gi]),
            .down_intf (decoder_cas_dx[gi+1]),

            .arf_kind_o (arf_kind_dx),
            .alu_kind_o (alu_kind_dx),
            .alu_op_o (alu_op_dx),
            .arf_wen_o (arf_wen_dx[gi]),

            .branch_z_i (~|r1_byp_dx[gi]),
            .branch_p_i (~r1_byp_dx[gi][15]),

            .preempt_intf (decoder_preempt_dx[gi])
         );

         core_alu i_alu (
            .clk_i,
            .rst_ni,
            .alu_op_i (alu_op_dx),
            .a_i (alu_kind_dx ? {8'b0,pc_dx[gi]} : r1_byp_dx[gi]),
            .b_i (alu_kind_dx ? {8'b0,addr_dx[gi]} : r2_byp_dx[gi]),
            .c_ro (alu_wb[gi])
         );
      end
   endgenerate

   // =====================
   // wb
   // =====================

   assign stall_wb = 0;

   always_ff @(posedge clk_i) begin
      if (~rst_ni) begin
         valid_wb <= 0;
      end else if (valid_dx) begin
         valid_wb <= ~halt_dx;
      end else if (~stall_wb) begin
         valid_wb <= 0;
      end
   end
   generate
   for (genvar gi = 0; gi < `SSC_EX+`SSC_MEM; gi++) begin : g_wb
      always_ff @(posedge clk_i) begin
         if (~rst_ni) begin
            rd_wb[gi] <= 0;
            arf_wen_wb[gi] <= 0;
         end else if (valid_dx) begin
            rd_wb[gi] <= rd_dx[gi];
            arf_wen_wb[gi] <= arf_wen_dx[gi] && |rd_dx[gi];
         end else if (~stall_wb) begin
            rd_wb[gi] <= 0;
            arf_wen_wb[gi] <= 0;
         end
      end

      assign arf_w_wb[gi].en = arf_wen_wb[gi];
      assign arf_w_wb[gi].addr = rd_wb[gi];
   end
   for (genvar gj = 0; gj < `SSC_EX; gj++) begin : g_wb
      assign arf_w_wb[gj].data = alu_wb[gj];
   end
   endgenerate

   assign arf_w_wb[`SSC_EX].data = lsu_wb;

   assign cpu_done_o = ~(valid_if || valid_dx || valid_wb) || halt_dx;

endmodule
