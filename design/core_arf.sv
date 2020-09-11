interface core_arf_r_intf;
   logic [3:0] addr,
   logic [15:0] data,
endinterface

interface core_arf_w_intf;
   logic en,
   logic [3:0] addr,
   logic [15:0] data,
endinterface

module core_arf (
   input clk_i,
   input rst_ni,
   core_arf_r_intf r_intf[0:R_PORTS-1],
   core_arf_w_intf w_intf[0:W_PORTS-1]
);
   localparam R_PORTS = 2 + `SSC_IF;
   localparam W_PORTS = `SSC_EX + `SSC_MEM;

   logic [15:0] mem[0:15];

   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
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
