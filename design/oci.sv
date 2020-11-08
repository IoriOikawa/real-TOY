module oci #(
   parameter logic [6:0] MCP23017_0 = 7'b010_0000,
   parameter logic [6:0] MCP23017_1 = 7'b010_0001,
   parameter logic [6:0] MCP23017_2 = 7'b010_0010,
   parameter logic [6:0] MCP23017_3 = 7'b010_0011,
   parameter logic [6:0] HT16K33    = 7'b111_0000
) (
   input logic clk_i,
   input logic rst_ni,

   input logic [16:0] lcd_i,
   input logic [32:0] gpio_i,
   output logic [30:0] gpio_o,

   input logic scl_i,
   output logic scl_o,
   output logic scl_t,
   input logic sda_i,
   output logic sda_o,
   output logic sda_t
);

   logic in_val, in_wen;
   logic [6:0] in_daddr;
   logic [7:0] in_addr, in_data;
   logic out_val, out_rdy;
   logic [7:0] out_data;

   /* verilator lint_off PINCONNECTEMPTY */
   i2c i_i2c (
      .clk_i,
      .rst_ni,

      .in_val_i (in_val),
      .in_daddr_i (in_daddr),
      .in_addr_i (in_addr),
      .in_data_i (in_data),
      .in_wen_i (in_wen),
      .in_rdy_o (),

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

   logic [4:0] state, state_next;
   logic [30:0] gpio_next;
   always_ff @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         state <= 0;
         gpio_o <= 0;
      end else begin
         state <= state_next;
         gpio_o <= gpio_next;
      end
   end

   function logic [7:0] digit(input logic [3:0] bin);
      unique case (bin)
         4'h0: digit = 8'h3f;
         4'h1: digit = 8'h06;
         4'h2: digit = 8'h5b;
         4'h3: digit = 8'h4f;
         4'h4: digit = 8'h66;
         4'h5: digit = 8'h6d;
         4'h6: digit = 8'h7d;
         4'h7: digit = 8'h07;
         4'h8: digit = 8'h7f;
         4'h9: digit = 8'h6f;
         4'ha: digit = 8'h77;
         4'hb: digit = 8'h7c;
         4'hc: digit = 8'h39;
         4'hd: digit = 8'h5e;
         4'he: digit = 8'h79;
         4'hf: digit = 8'h71;
      endcase
   endfunction

   struct packed {
      bit [6:0] daddr;
      bit wen;
      bit [7:0] addr;
      bit [7:0] data;
   } req;

   assign in_daddr = req.daddr;
   assign in_wen = req.wen;
   assign in_addr = req.addr;
   assign in_data = req.data;

   always_comb begin
      state_next = state;
      gpio_next = gpio_o;
      in_val = 1;
      out_rdy = 1;
      unique case (state)
         5'd01: req = '{MCP23017_0, 1, 8'h00, 8'h00}; // IODIRA
         5'd02: req = '{MCP23017_0, 1, 8'h0d, 8'hff}; // GPPUB
         5'd03: req = '{MCP23017_0, 1, 8'h03, 8'hff}; // IPOLB
         5'd04: req = '{MCP23017_1, 1, 8'h00, 8'h00}; // IODIRA
         5'd05: req = '{MCP23017_1, 1, 8'h01, 8'hbf}; // IODIRB
         5'd06: req = '{MCP23017_1, 1, 8'h0d, 8'hbf}; // GPPUB
         5'd07: req = '{MCP23017_1, 1, 8'h03, 8'hbf}; // IPOLB
         5'd08: req = '{MCP23017_2, 1, 8'h00, 8'h00}; // IODIRA
         5'd09: req = '{MCP23017_2, 1, 8'h0d, 8'hff}; // GPPUB
         5'd10: req = '{MCP23017_2, 1, 8'h03, 8'hff}; // IPOLB
         5'd11: req = '{MCP23017_3, 1, 8'h01, 8'h00}; // IODIRB
         5'd12: req = '{MCP23017_3, 1, 8'h0c, 8'hff}; // GPPUA
         5'd13: req = '{MCP23017_3, 1, 8'h02, 8'hff}; // IPOLA
         5'd14: req = '{HT16K33,    1, 8'h21, 8'h00}; // OSC on
         5'd15: req = '{HT16K33,    1, 8'h81, 8'h00}; // Display on
         5'd16: req = '{HT16K33,    1, 8'he9, 8'h00}; // Dimming 10/16
         5'd17: req = '{HT16K33,    1, 8'h04, 8'h00}; // colon

         5'd18: req = '{MCP23017_0, 1, 8'h14, gpio_i[7:0]}; // OLATA
         5'd19: req = '{MCP23017_0, 0, 8'h13, 8'h00}; // GPIOB
         5'd20: req = '{MCP23017_1, 1, 8'h14, gpio_i[23:16]}; // OLATA
         5'd21: req = '{MCP23017_1, 1, 8'h15, {1'h0,gpio_i[32],6'h00}}; // OLATB
         5'd22: req = '{MCP23017_1, 0, 8'h13, 8'h00}; // GPIOB
         5'd23: req = '{MCP23017_2, 1, 8'h14, gpio_i[15:8]}; // OLATA
         5'd24: req = '{MCP23017_2, 0, 8'h13, 8'h00}; // GPIOB
         5'd25: req = '{MCP23017_3, 1, 8'h15, gpio_i[31:24]}; // OLATB
         5'd26: req = '{MCP23017_3, 0, 8'h12, 8'h00}; // GPIOA
         5'd27: req = '{HT16K33,    1, 8'h00, digit(lcd_i[15:12])}; // MSD
         5'd28: req = '{HT16K33,    1, 8'h02, digit(lcd_i[11:8])}; //
         5'd29: req = '{HT16K33,    1, 8'h06, digit(lcd_i[7:4])}; //
         5'd30: req = '{HT16K33,    1, 8'h08, digit(lcd_i[3:0])}; // LSD

         default: req = '{7'h00, 0, 8'h00, 8'h00};
      endcase
      if (state == 0 || out_val) begin
         state_next = state + 1;
         unique case (state)
            5'd00: begin
               in_val = 0;
               out_rdy = 0;
            end
            5'd19: gpio_next[23:16] = out_data;
            5'd22: begin
               gpio_next[29:24] = out_data[6:0];
               gpio_next[30] = out_data[7];
            end
            5'd24: gpio_next[15:8] = out_data;
            5'd26: gpio_next[7:0] = out_data;
            5'd30: state_next = 18;
            default: begin end
         endcase
      end
   end

endmodule
