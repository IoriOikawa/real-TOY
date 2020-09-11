module core_lsu (
   input clk_i,
   input rst_ni,

   input val_i,
   input wen_i,
   input [7:0] addr_i,
   input [15:0] data_i,
   output [15:0] data_ro,
   output rdy_o,

   stdio.in stdin_intf,
   stdio.out stdout_intf,

   mem_rwport.master mem_rw_intf
);

   logic state, state_next;
   always_ff @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         state <= 0;
      end else if (val_i && rdy_o) begin
         state <= state_next;
      end
   end

   assign data_ro = state ? stdin_intf.data : mem_rw_intf.rdata;

   always_comb begin
      state_next = 0;
      rdy_o = 0;
      stdin_intf.rdy = 0;
      stdout_intf.val = 0;
      stdout_intf.data = '0;
      mem_rw_intf.val = 0;
      mem_rw_intf.wen = 0;
      mem_rw_intf.addr = '0;
      mem_rw_intf.wdata = '0;
      if (val_i) begin
         if (addr_i == 8'hff) begin
            if (wen_i) begin
               rdy_o = stdout_intf.rdy;
               stdout_intf.val = 1;
               stdout_intf.data = data_ro;
            end else begin
               state_next = 1;
               rdy_o = stdin_intf.val;
               stdin_intf.rdy = 1;
            end
         end else begin
            mem_rw_intf.val = 1;
            mem_rw_intf.wen = wen_i;
            mem_rw_intf.addr = addr_i;
            mem_rw_intf.wdata = data_i;
         end
      end
   end

endmodule
