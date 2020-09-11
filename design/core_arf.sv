`include "global.svh"

module core_arf (
   input logic clk_i,
   input logic arst_ni,
   core_arf_r r_intf[0:R_PORTS-1],
   core_arf_w w_intf[0:W_PORTS-1]
);
   localparam R_PORTS = 2 * (`SSC_EX + `SSC_MEM);
   localparam W_PORTS = `SSC_EX + `SSC_MEM;

   logic [15:0] mem[0:15], mem_nexts[0:15][0:W_PORTS-1];

   generate
   for (genvar gi = 0; gi < R_PORTS; gi++) begin : g_r
      assign r_intf[gi].data = mem[r_intf[gi].addr];
   end
   endgenerate

   generate
   for (genvar gj = 0; gj < 16; gj++) begin : g_f
      always @(posedge clk_i, negedge arst_ni) begin
         if (~arst_ni) begin
            mem[gj] <= 16'b0;
         end else begin
            mem[gj] <= mem_nexts[gj][W_PORTS-1];
         end
      end
      for (genvar gi = 0; gi < W_PORTS; gi++) begin : g_w
         always_comb begin
            if (gi == 0) begin
               mem_nexts[gj][gi] = mem[gj];
            end else if (w_intf[gi].en && w_intf[gi].addr == gj) begin
               mem_nexts[gj][gi] = w_intf[gi].data;
            end else begin
               mem_nexts[gj][gi] = mem_nexts[gj][gi-1];
            end
         end
      end
   end
   endgenerate

   endmodule
