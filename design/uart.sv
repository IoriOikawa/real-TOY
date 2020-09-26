`include "global.svh"

module uart (
   input logic clk_i,
   input logic rst_ni,
   input logic srst_i,

   input logic in_val_i,
   input logic [7:0] in_data_i,
   output logic in_rdy_o,
   output logic avail_o,

   output logic uart_tx_o,
   input logic uart_rx_i,
   input logic uart_dtr_i
);
   localparam CLKDIV = `UART_DIV;

   logic [4:0] state, state_next;
   logic [$clog2(CLKDIV)-1:0] div, div_next;
   logic [7:0] in_data;
   logic shift_data;
   always_ff @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         state <= 0;
         div <= 0;
         in_data <= 0;
      end else if (srst_i) begin
         state <= 0;
         div <= 0;
         in_data <= 0;
      end else begin
         state <= state_next;
         div <= div_next;
         if (in_val_i && in_rdy_o) begin
            in_data <= in_data_i;
         end else if (shift_data) begin
            in_data <= in_data >> 1;
         end
      end
   end

   always_comb begin
      state_next = state;
      div_next = div;
      in_rdy_o = 0;
      uart_tx_o = 1;
      shift_data = 0;
      avail_o = 1;
      if (srst_i) begin
         in_rdy_o = 1;
      end else if (state == 0) begin // init
         if (~uart_rx_i) begin
            avail_o = 0;
            in_rdy_o = 1;
         end else if (uart_dtr_i) begin
            in_rdy_o = 1;
            if (in_val_i) begin
               state_next = state + 1;
               div_next = 0;
            end
         end
      end else if (state == 1) begin // start
         uart_tx_o = 1;
         div_next = div + 1;
         if (div == CLKDIV - 1) begin
            state_next = state + 1;
            div_next = 0;
         end
      end else if (state < 9) begin // msb -> lsb
         uart_tx_o = in_data[0];
         div_next = div + 1;
         if (div == CLKDIV - 1) begin
            state_next = state + 1;
            div_next = 0;
            shift_data = 1;
         end
      end else if (state == 9) begin // stop
         uart_tx_o = 1;
         div_next = div + 1;
         if (div == CLKDIV - 1) begin
            state_next = 0;
         end
      end
   end

endmodule
