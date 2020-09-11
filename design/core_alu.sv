`include "global.svh"

module core_alu (
   input clk_i,
   input rst_ni,
   input [2:0] alu_op_i,
   input [15:0] a_i,
   input [15:0] b_i,
   output [15:0] c_ro
);

   logic alu_op_r;
   logic [15:0] a_r, b_r;
   always_ff @(posedge clk_i) begin
      if (~rst_ni) begin
         alu_op_r <= 0;
         a_r <= 16'b0;
         b_r <= 16'b0;
      end else begin
         alu_op_r <= alu_op_i;
         a_r <= a_i;
         b_r <= b_i;
      end
   end

   always_comb begin
      unique case (alu_op_r)
         3'd0: c_ro = a_r + b_r;
         3'd1: c_ro = a_r - b_r;
         3'd2: c_ro = a_r & b_r;
         3'd3: c_ro = a_r ^ b_r;
         3'd4: c_ro = a_r << b_r;
         3'd5: c_ro = a_r >> b_r;
         3'd6: c_ro = a_r;
         3'd7: c_ro = b_r;
      endcase
   end

endmodule
