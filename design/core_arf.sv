`include "global.svh"

module core_arf (
   input clk_i,
   input arst_ni,
   core_arf_r r_intf[0:R_PORTS-1],
   core_arf_w w_intf[0:W_PORTS-1]
);
   localparam R_PORTS = 2 + `SSC_IF;
   localparam W_PORTS = `SSC_EX + `SSC_MEM;

   logic [15:0] mem[0:15];

   always @(posedge clk_i, negedge arst_ni) begin
      if (~arst_ni) begin
         for (integer i = 0; i < 16; i = i + 1) begin
            mem[i] <= 16'b0;
         end
      end else begin
         for (integer j = 0; j < W_PORTS; j = j + 1) begin
            if (w_intf[j].en) begin
               mem[w_intf[j].addr] <= w_intf[j].data;
            end
         end
      end
   end

   always_comb begin
      for (integer i = 0; i < R_PORTS; i++) begin
         r_intf[i].data = mem[r_intf[i].addr];
      end
   end

endmodule
