module fifo #(
   parameter DEPTH = 2
) (
   input clk_i,
   input rst_ni,
   stdio.in stdin,
   stdio.out stdout
);

   logic [15:0] mem[0:DEPTH];
   logic [$clog2(DEPTH)-1:0] rptr, wptr;
   always_ff @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         rptr <= '0;
         wptr <= '0;
      end else begin
         if (stdin.val && stdin.rdy) begin
            mem[wptr] <= stdin.data;
            wptr <= (wptr + 1) % DEPTH;
         end
         if (stdout.val && stdout.rdy) begin
            rptr <= (rptr + 1) % DEPTH;
         end
      end
   end

   assign stdin.rdy = wptr - rptr != 1;
   assign stdout.val = wptr != rptr;
   assign stdout.data <= mem[rptr];

endmodule
