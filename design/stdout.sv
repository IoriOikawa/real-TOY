`include "global.svh"

module stdout (
   input logic clk_i,
   input logic rst_ni,

   input logic stdout_val_i,
   input logic [15:0] stdout_data_i,
   output logic stdout_rdy_o,
   input logic stdout_flush_i,

   // TODO: use hex
   output logic [3:0] lcd_bcd_o[0:3],

   output logic uart_val_o,
   output logic [7:0] uart_data_o,
   input logic uart_rdy_i,
   input logic uart_avail_i
);

   logic [3:0] state, state_next;
   logic [15:0] partial, partial_next;
   logic [15:0] cnt, cnt_next;
   always_ff @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         state <= 0;
         partial <= 0;
         cnt <= 0;
         lcd_bcd_o[0] <= 0;
         lcd_bcd_o[1] <= 0;
         lcd_bcd_o[2] <= 0;
         lcd_bcd_o[3] <= 0;
      end else begin
         state <= state_next;
         partial <= partial_next;
         cnt <= cnt_next;
         unique case (state)
            1: lcd_bcd_o[0] <= partial % 10;
            2: lcd_bcd_o[1] <= partial % 10;
            3: lcd_bcd_o[2] <= partial % 10;
            4: lcd_bcd_o[3] <= partial % 10;
         endcase
      end
   end

   logic [3:0] tmp;
   always_comb begin
      state_next = state;
      partial_next = partial;
      cnt_next = cnt;
      stdout_rdy_o = 0;
      uart_val_o = 0;
      uart_data_o = 0;
      tmp = 0;
      if (state == 0) begin // idle
         stdout_rdy_o = 1;
         if (stdout_val_i) begin
            state_next = 1;
            partial_next = stdout_data_i;
         end else if (|cnt && stdout_flush_i) begin
            state_next = 10;
         end
      end else if (state < 5) begin // digit 0~3
         state_next = state + 1;
         partial_next = partial / 10;
      end else if (state == 5) begin // space
         if (~uart_avail_i) begin
            state_next = 0;
         end else if (~|cnt) begin
            state_next = state + 1;
         end else begin
            uart_val_o = 1;
            uart_data_o = " ";
            if (uart_rdy_i) begin
               state_next = state + 1;
            end
         end
      end else if (state < 9) begin // digit 3~0
         uart_val_o = 1;
         uart_data_o = "0" + tmp;
         unique case (state)
            6: tmp = lcd_bcd_o[3];
            7: tmp = lcd_bcd_o[2];
            8: tmp = lcd_bcd_o[1];
            9: tmp = lcd_bcd_o[0];
         endcase
         if (uart_rdy_i) begin
            state_next = state + 1;
         end
      end else if (state == 9) begin // lf
         if (cnt < 3) begin
            state_next = 0;
            cnt_next = cnt + 1;
         end else begin
            uart_val_o = 1;
            uart_data_o = "\n";
            if (uart_rdy_i) begin
               state_next = 0;
               cnt_next = 0;
            end
         end
      end else if (state < 12) begin // flush
         uart_val_o = 1;
         uart_data_o = "\n";
         if (uart_rdy_i) begin
            state_next = state == 11 ? 0 : state + 1;
            cnt_next = 0;
         end
      end
   end

endmodule
