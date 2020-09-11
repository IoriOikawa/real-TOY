`include "global.svh"

module core_arf (
   input logic clk_i,
   input logic arst_ni,
   core_arf_r r_intf[0:R_PORTS-1],
   core_arf_w w_intf[0:W_PORTS-1]
);
   localparam R_PORTS = 2 * (`SSC_EX + `SSC_MEM);
   localparam W_PORTS = `SSC_EX + `SSC_MEM;

   logic [15:0] mem[0:15];

   generate
   for (genvar gi = 0; gi < R_PORTS; gi++) begin : g_r
      assign r_intf[gi].data = mem[r_intf[gi].addr];
   end
   endgenerate

   generate
   for (genvar gj = 0; gj < 16; gj++) begin : g_f
      logic [W_PORTS-1:0] tmp_en;
      logic [W_PORTS-1:0] tmp_nxt[0:15];
      logic [15:0] tmp_mem_nxt;
      always @(posedge clk_i, negedge arst_ni) begin
         if (~arst_ni) begin
            mem[gj] <= 16'b0;
         end else if (|tmp_en) begin
            mem[gj] <= tmp_mem_nxt;
         end
      end
      for (genvar gi = 0; gi < W_PORTS; gi++) begin : g_w
         assign tmp_en[gi] = w_intf[gi].en && w_intf[gi].addr == gj;
         for (genvar gk = 0; gk < 16; gk++) begin : g_b
            assign tmp_nxt[gk][gi] = tmp_en[gi] && w_intf[gi].data[gk];
         end
      end
      for (genvar gk = 0; gk < 16; gk++) begin : g_s
         assign tmp_mem_nxt[gk] = |tmp_nxt[gk];
      end
   end
   endgenerate

endmodule
