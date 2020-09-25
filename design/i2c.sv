module i2c #(
   parameter CLKDIV = 30 // 12MHz -> 400kHz
) (
   input logic clk_i,
   input logic rst_ni,
   input logic srst_i,

   input logic in_val_i,
   input logic [6:0] in_daddr_i,
   input logic [7:0] in_addr_i,
   input logic [7:0] in_data_i,
   input logic in_wen_i,
   output logic in_rdy_o,

   output logic out_val_o,
   output logic out_err_o,
   output logic [7:0] out_data_o,
   input logic out_rdy_i,

   input logic scl_i,
   output logic scl_o,
   output logic scl_t,
   input logic sda_i,
   output logic sda_o,
   output logic sda_t
);
   localparam CLKDIV1 = CLKDIV * 1 / 4;
   localparam CLKDIV2 = CLKDIV * 2 / 4;
   localparam CLKDIV3 = CLKDIV * 3 / 4;

   logic sda_t_next;

   logic [5:0] state, state_next;
   logic [$clog2(CLKDIV)-1:0] div, div_next;
   logic out_err_next, shift_rdata;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         state <= 0;
         div <= 0;
         out_err_o <= 0;
         out_data_o <= 0;
         sda_t <= 0;
      end else if (srst_i) begin
         state <= 0;
         div <= 0;
         out_err_o <= 0;
         out_data_o <= 0;
         sda_t <= 0;
      end else begin
         state <= state_next;
         div <= div_next;
         out_err_o <= out_err_next;
         if (shift_rdata) begin
            out_data_o <= {out_data_o[6:0],sda_i};
         end
         sda_t <= sda_t_next;
      end
   end

   logic [6:0] in_daddr;
   logic [7:0] in_addr;
   logic [7:0] in_data;
   logic in_wen;
   logic shift_daddr, shift_addr, shift_data;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         in_daddr <= 0;
         in_addr <= 0;
         in_data <= 0;
         in_wen <= 0;
      end else if (srst_i) begin
         in_daddr <= 0;
         in_addr <= 0;
         in_data <= 0;
         in_wen <= 0;
      end else if (in_val_i && in_rdy_o) begin
         in_daddr <= in_daddr_i;
         in_addr <= in_addr_i;
         in_data <= in_data_i;
         in_wen <= in_wen_i;
      end else begin
         if (shift_daddr) begin
            in_daddr <= in_daddr << 1;
         end
         if (shift_addr) begin
            in_addr <= in_addr << 1;
         end
         if (shift_data) begin
            in_data <= in_data << 1;
         end
      end
   end

   assign scl_o = 0;
   assign sda_o = 0;

   always_comb begin
      state_next = state;
      div_next = div;
      sda_t_next = sda_t;
      in_rdy_o = 0;
      out_val_o = 0;
      out_err_next = out_err_o;
      scl_t = 0;
      sda_t_next = sda_t;
      shift_daddr = 0;
      shift_addr = 0;
      shift_data = 0;
      shift_rdata = 0;
      if (state == 0) begin // idle
         in_rdy_o = 1;
         sda_t_next = 0;
         if (in_val_i) begin
            state_next = 1;
         end
      end else if (state == 1) begin // wait for bus
         sda_t_next = 0;
         if (scl_i && sda_i) begin
            state_next = 2;
            div_next = 0;
         end
      end else if (state == 2) begin // S
         sda_t_next = 1;
         div_next = div + 1;
         if (div == CLKDIV - 1) begin
            state_next = 10;
            div_next = 0;
         end
      end else if (state == 8) begin // P
         if (div == CLKDIV1) begin
            sda_t_next = 1;
         end
         if (div == CLKDIV3) begin
            sda_t_next = 0;
         end
         div_next = div + 1;
         if (div == CLKDIV - 1) begin
            state_next = 9;
         end
      end else if (state == 9) begin // finished
         out_val_o = 1;
         if (out_rdy_i) begin
            state_next = 1;
            out_err_next = 0;
         end
      end else if (state >= 10 && state < 17) begin // DA[6] ~ DA[0]
         if (div == CLKDIV1) begin
            sda_t_next = ~in_daddr[6];
         end
         scl_t = div < CLKDIV2;
         div_next = div + 1;
         if (div == CLKDIV - 1) begin
            state_next = state + 1;
            div_next = 0;
            shift_daddr = 1;
         end
      end else if (state == 17) begin // R/Wb
         if (div == CLKDIV1) begin
            sda_t_next = 1; // TODO: always W here
         end
         scl_t = div < CLKDIV2;
         div_next = div + 1;
         if (div == CLKDIV - 1) begin
            state_next = state + 1;
            div_next = 0;
            sda_t_next = 0;
         end
      end else if (state == 18) begin // ACK
         sda_t_next = 0;
         scl_t = div < CLKDIV2;
         div_next = div + 1;
         if (div == CLKDIV - 1) begin
            if (sda_i) begin // NACK
               state_next = 8;
               div_next = 0;
               out_err_next = 1;
            end else begin // ACK
               state_next = in_wen ? 40 : 19;
               div_next = 0;
            end
         end
      end else if (state == 19) begin // SR
         if (div == CLKDIV1) begin
            sda_t_next = 0;
         end else if (div == CLKDIV3) begin
            sda_t_next = 1;
         end
         scl_t = div < CLKDIV2;
         div_next = div + 1;
         if (div == CLKDIV - 1) begin
            state_next = 20;
            div_next = 0;
         end
      end else if (state >= 20 && state < 28) begin // A[7]~A[0]
         if (div == CLKDIV1) begin
            sda_t_next = ~in_addr[7];
         end
         scl_t = div < CLKDIV2;
         div_next = div + 1;
         if (div == CLKDIV - 1) begin
            state_next = state + 1;
            div_next = 0;
            shift_addr = 1;
         end
      end else if (state == 28) begin // R/Wb
         if (div == CLKDIV1) begin
            sda_t_next = 0; // always R here
         end
         scl_t = div < CLKDIV2;
         div_next = div + 1;
         if (div == CLKDIV - 1) begin
            state_next = state + 1;
            div_next = 0;
            sda_t_next = 0;
         end
      end else if (state == 29) begin // ACK
         sda_t_next = 0;
         scl_t = div < CLKDIV2;
         div_next = div + 1;
         if (div == CLKDIV - 1) begin
            if (sda_i) begin // NACK
               state_next = 8;
               div_next = 0;
            end else begin // ACK
               state_next = 30;
               div_next = 0;
            end
         end
      end else if (state >= 30 && state < 38) begin // D[7]~D[0] read
         sda_t_next = 0;
         scl_t = div < CLKDIV2;
         if (div == CLKDIV3) begin
            shift_rdata = 1;
         end
         div_next = div + 1;
         if (div == CLKDIV - 1) begin
            state_next = state == 37 ? 8 : state + 1;
            div_next = 0;
         end
      end else if (state >= 40 && state < 48) begin // A[7]~A[0]
         if (div == CLKDIV1) begin
            sda_t_next = ~in_addr[7];
         end
         scl_t = div < CLKDIV2;
         div_next = div + 1;
         if (div == CLKDIV - 1) begin
            state_next = state == 47 ? 50 : state + 1;
            div_next = 0;
            shift_addr = 1;
         end
      end else if (state >= 50 && state < 58) begin // D[7]~D[0] write
         if (div == CLKDIV1) begin
            sda_t_next = ~in_data[7];
         end
         scl_t = div < CLKDIV2;
         div_next = div + 1;
         if (div == CLKDIV - 1) begin
            state_next = state == 57 ? 8 : state + 1;
            div_next = 0;
            shift_data = 1;
         end
      end
   end

endmodule
