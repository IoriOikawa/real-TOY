module oci #(
   parameter logic [6:0] MCP23017_0 = 3'b010_0000,
   parameter logic [6:0] MCP23017_1 = 3'b010_0001,
   parameter logic [6:0] MCP23017_2 = 3'b010_0010,
   parameter logic [6:0] MCP23017_3 = 3'b010_0011,
   parameter logic [6:0] HT16K33    = 3'b111_0000
) (
   input logic clk_i,
   input logic rst_ni,
   input logic srst_i,

   input logic [15:0] lcd_i,
   input logic [31:0] gpio_i,
   output logic [31:0] gpio_o,

   input logic scl_i,
   output logic scl_o,
   output logic scl_t,
   input logic sda_i,
   output logic sda_o,
   output logic sda_t
);

   logic in_val, in_wen, in_rdy;
   logic [6:0] in_daddr;
   logic [7:0] in_addr, in_data;
   logic out_val, out_rdy;
   logic [7:0] out_data;

   i2c i_i2c (
      .clk_i,
      .rst_ni,
      .srst_i,

      .in_val_i (in_val),
      .in_daddr_i (in_daddr),
      .in_addr_i (in_addr),
      .in_data_i (in_data),
      .in_wen_i (in_wen),
      .in_rdy_o (in_rdy),

      .out_val_o (out_val),
      .out_err_o (),
      .out_data_o (out_data),
      .out_rdy_i (out_rdy),

      .scl_i,
      .scl_o,
      .scl_t,
      .sda_i,
      .sda_o,
      .sda_t
   );

   logic [5:0] state, state_next;
   logic [31:0] gpio_next;
   logic [15:0] partial, partial_next;
   always_ff @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         state <= 0;
         gpio_o <= 0;
         partial <= 0;
      end else if (srst_i) begin
         state <= 0;
         gpio_o <= 0;
         partial <= 0;
      end else begin
         state <= state_next;
         gpio_o <= gpio_next;
         partial <= partial_next;
      end
   end

   always_comb begin
      state_next = state;
      gpio_next = gpio;
      partial_next = partial;
      in_val = 0;
      in_wen = 0;
      in_daddr = 0;
      in_addr = 0;
      in_data = 0;
      out_rdy = 0;
      out_data = 0;
      if (state == 0) begin // init
         state_next = state + 1;
      end else if (state < 5) begin // init MCP23017
         in_val = 1;
         out_rdy_i = 1;
         unique case (state)
            1: in_daddr = MCP23017_0;
            2: in_daddr = MCP23017_1;
            3: in_daddr = MCP23017_2;
            4: in_daddr = MCP23017_3;
         endcase
         in_addr = 8'h00;
         in_data = 8'h00;
         in_wen = 1;
         if (out_val) begin
            state_next = state + 1;
         end
      end else if (state < 9) begin // init MCP23017
         in_val = 1;
         out_rdy_i = 1;
         unique case (state)
            1: in_daddr = MCP23017_0;
            2: in_daddr = MCP23017_1;
            3: in_daddr = MCP23017_2;
            4: in_daddr = MCP23017_3;
         endcase
         in_addr = 8'h0d;
         in_data = 8'h11;
         in_wen = 1;
         if (out_val) begin
            state_next = state + 1;
         end
      end else if (state == 9) begin // init HT16K33
         in_val = 1;
         out_rdy_i = 1;
         in_daddr = HT16K33;
         in_addr = 8'h20;
         in_data = 8'h21;
         in_wen = 1;
         if (out_val) begin
            state_next = state + 1;
         end
      end
      end
   end

endmodule
