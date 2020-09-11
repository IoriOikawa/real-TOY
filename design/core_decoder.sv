`include "global.svh"

module core_decoder (
   input logic [15:0] instr_i,

   input logic my_en_i,
   output logic my_en_o,

   output logic arf_kind_o, // 0: R[s],R[t]  1: R[d],R[t]
   output logic alu_kind_o, // 0: R[s],R[t]  1: pc,addr
   output logic [2:0] alu_op_o,
   output logic arf_wen_o,

   input logic branch_z_i,
   input logic branch_p_i,

   core_decoder_cascade up_intf,
   core_decoder_cascade down_intf,
   core_decoder_preempt preempt_intf
);

   logic [3:0] op = instr_i[15:12];
   logic [3:0] rd = instr_i[11:8];
   logic [3:0] rs = instr_i[7:4];
   logic [3:0] rt = instr_i[3:0];

   always_comb begin
      unique case (op)
         4'h0: // halt
            arf_kind_o = 0;
         4'h1: // add
            arf_kind_o = 0;
         4'h2: // subtract
            arf_kind_o = 0;
         4'h3: // and
            arf_kind_o = 0;
         4'h4: // xor
            arf_kind_o = 0;
         4'h5: // left shift
            arf_kind_o = 0;
         4'h6: // right shift
            arf_kind_o = 0;
         4'h7: // load address
            arf_kind_o = 0;
         4'h8: // load
            arf_kind_o = 0;
         4'h9: // store
            arf_kind_o = 1;
         4'ha: // load indirect
            arf_kind_o = 0;
         4'hb: // store indirect
            arf_kind_o = 1;
         4'hc: // branch zero
            arf_kind_o = 1;
         4'hd: // branch zero
            arf_kind_o = 1;
         4'he: // jump register
            arf_kind_o = 1;
         4'hf: // jump and link
            arf_kind_o = 0;
      endcase
   end

   always_comb begin
      my_en_o = my_en_i && up_intf.en;
      down_intf.en = up_intf.en;
      down_intf.virgin = ~my_en_i && up_intf.virgin;
      down_intf.dirty = up_intf.dirty;
      down_intf.stall = up_intf.stall;
      alu_kind_o = 0;
      alu_op_o = 0;
      arf_wen_o = 0;
      preempt_intf.jump_en = 0;
      preempt_intf.jump_kind = 0;
      preempt_intf.lsu_en = 0;
      preempt_intf.lsu_wen = 0;
      preempt_intf.lsu_kind = 0;
      preempt_intf.halt = 0;
      if (my_en_i && up_intf.en && ~up_intf.stall) begin
         unique case (op)
            4'h0: // halt
               if (up_intf.virgin) begin
                  my_en_o = 0;
                  down_intf.en = 0;
                  preempt_intf.halt = 1;
               end else begin
                  down_intf.stall = 1;
               end
            4'h1: // add
               if (up_intf.dirty[rs] || up_intf.dirty[rt]) begin
                  down_intf.stall = 1;
               end else begin
                  my_en_o = 0;
                  down_intf.dirty[rd] = |rd;
                  alu_op_o = 0;
                  arf_wen_o = 1;
               end
            4'h2: // subtract
               if (up_intf.dirty[rs] || up_intf.dirty[rt]) begin
                  down_intf.stall = 1;
               end else begin
                  my_en_o = 0;
                  down_intf.dirty[rd] = |rd;
                  alu_op_o = 1;
                  arf_wen_o = 1;
               end
            4'h3: // and
               if (up_intf.dirty[rs] || up_intf.dirty[rt]) begin
                  down_intf.stall = 1;
               end else begin
                  my_en_o = 0;
                  down_intf.dirty[rd] = |rd;
                  alu_op_o = 2;
                  arf_wen_o = 1;
               end
            4'h4: // xor
               if (up_intf.dirty[rs] || up_intf.dirty[rt]) begin
                  down_intf.stall = 1;
               end else begin
                  my_en_o = 0;
                  down_intf.dirty[rd] = |rd;
                  alu_op_o = 3;
                  arf_wen_o = 1;
               end
            4'h5: // left shift
               if (up_intf.dirty[rs] || up_intf.dirty[rt]) begin
                  down_intf.stall = 1;
               end else begin
                  my_en_o = 0;
                  down_intf.dirty[rd] = |rd;
                  alu_op_o = 4;
                  arf_wen_o = 1;
               end
            4'h6: // right shift
               if (up_intf.dirty[rs] || up_intf.dirty[rt]) begin
                  down_intf.stall = 1;
               end else begin
                  my_en_o = 0;
                  down_intf.dirty[rd] = |rd;
                  alu_op_o = 5;
                  arf_wen_o = 1;
               end
            4'h7: // load address
               begin
                  my_en_o = 0;
                  down_intf.dirty[rd] = |rd;
                  alu_kind_o = 1;
                  alu_op_o = 7;
                  arf_wen_o = 1;
               end
            4'h8: // load
               begin
                  my_en_o = 0;
                  down_intf.stall = 1;
                  down_intf.dirty[rd] = |rd;
                  preempt_intf.lsu_en = 1;
                  preempt_intf.lsu_kind = 1;
               end
            4'h9: // store
               if (up_intf.dirty[rd]) begin
                  down_intf.stall = 1;
               end else begin
                  my_en_o = 0;
                  down_intf.stall = 1;
                  preempt_intf.lsu_en = 1;
                  preempt_intf.lsu_wen = 1;
                  preempt_intf.lsu_kind = 1;
               end
            4'ha: // load indirect
               if (up_intf.dirty[rt]) begin
                  down_intf.stall = 1;
               end else begin
                  my_en_o = 0;
                  down_intf.stall = 1;
                  down_intf.dirty[rd] = |rd;
                  preempt_intf.lsu_en = 1;
               end
            4'hb: // store indirect
               if (up_intf.dirty[rd] || up_intf.dirty[rt]) begin
                  down_intf.stall = 1;
               end else begin
                  my_en_o = 0;
                  down_intf.stall = 1;
                  preempt_intf.lsu_en = 1;
                  preempt_intf.lsu_wen = 1;
               end
            4'hc: // branch zero
               if (up_intf.dirty[rd]) begin
                  down_intf.stall = 1;
               end else if (branch_z_i) begin
                  my_en_o = 0;
                  down_intf.en = 0;
                  preempt_intf.jump_en = 1;
                  preempt_intf.jump_kind = 1;
               end else begin
                  my_en_o = 0;
               end
            4'hd: // branch zero
               if (up_intf.dirty[rd]) begin
                  down_intf.stall = 1;
               end else if (branch_p_i) begin
                  my_en_o = 0;
                  down_intf.en = 0;
                  preempt_intf.jump_en = 1;
                  preempt_intf.jump_kind = 1;
               end else begin
                  my_en_o = 0;
               end
            4'he: // jump register
               if (up_intf.dirty[rd]) begin
                  down_intf.stall = 1;
               end else begin
                  my_en_o = 0;
                  down_intf.en = 0;
                  preempt_intf.jump_en = 1;
               end
            4'hf: // jump and link
               begin
                  my_en_o = 0;
                  down_intf.en = 0;
                  alu_kind_o = 1;
                  alu_op_o = 6;
                  arf_wen_o = 1;
                  preempt_intf.jump_en = 1;
                  preempt_intf.jump_kind =1;
               end
         endcase
      end
   end

endmodule
