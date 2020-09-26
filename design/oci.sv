module oci #(
   parameter logic [6:0] MCP23017_0 = 7'b010_0000,
   parameter logic [6:0] MCP23017_1 = 7'b010_0001,
   parameter logic [6:0] MCP23017_2 = 7'b010_0010,
   parameter logic [6:0] MCP23017_3 = 7'b010_0011,
   parameter logic [6:0] HT16K33    = 7'b111_0000
) (
   input logic clk_i,
   input logic rst_ni,

   input logic [3:0] lcd_bcd_i[0:3],
   input logic [31:0] gpio_i,
   output logic [31:0] gpio_o,

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
   logic [31:0] gpio_next;
   always_ff @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         state <= 0;
         gpio_o <= 0;
      end else begin
         state <= state_next;
         gpio_o <= gpio_next;
      end
   end

   logic [3:0] tmp;
   always_comb begin
      state_next = state;
      gpio_next = gpio_o;
      in_val = 1;
      in_wen = 0;
      in_daddr = 0;
      in_addr = 0;
      in_data = 0;
      out_rdy = 1;
      if (state == 0) begin // init
         state_next = state + 1;
         in_val = 0;
         out_rdy = 0;
      end else if (state < 5) begin // init MCP23017
         unique case (state)
            1: in_daddr = MCP23017_0;
            2: in_daddr = MCP23017_1;
            3: in_daddr = MCP23017_2;
            4: in_daddr = MCP23017_3;
         endcase
         in_addr = 8'h00; // IODIRA = 0x00
         in_data = 8'h00;
         in_wen = 1;
         if (out_val) begin
            state_next = state + 1;
         end
      end else if (state < 9) begin // init MCP23017
         unique case (state)
            5: in_daddr = MCP23017_0;
            6: in_daddr = MCP23017_1;
            7: in_daddr = MCP23017_2;
            8: in_daddr = MCP23017_3;
         endcase
         in_addr = 8'h0d; // GPPUB = 0xff
         in_data = 8'hff;
         in_wen = 1;
         if (out_val) begin
            state_next = state + 1;
         end
      end else if (state == 9) begin // init HT16K33
         in_daddr = HT16K33;
         in_addr = 8'h21; // OSC on
         in_data = 8'h81; // Display on
         in_wen = 1;
         if (out_val) begin
            state_next = state + 1;
         end
      end else if (state < 14) begin // write gpio
         unique case (state)
            10: in_daddr = MCP23017_0;
            11: in_daddr = MCP23017_1;
            12: in_daddr = MCP23017_2;
            13: in_daddr = MCP23017_3;
         endcase
         in_addr = 8'h14; // OLATA = <gpio_i>
         unique case (state)
            10: in_data = gpio_i[7:0];
            11: in_data = gpio_i[15:8];
            12: in_data = gpio_i[23:16];
            13: in_data = gpio_i[31:24];
         endcase
         in_wen = 1;
         if (out_val) begin
            state_next = state + 1;
         end
      end else if (state < 18) begin // write lcd
         in_daddr = HT16K33;
         unique case (state)
            14: in_addr = 8'h00;
            15: in_addr = 8'h02;
            16: in_addr = 8'h04;
            17: in_addr = 8'h06;
         endcase
         unique case (state)
            14: tmp = lcd_bcd_i[0];
            15: tmp = lcd_bcd_i[1];
            16: tmp = lcd_bcd_i[2];
            17: tmp = lcd_bcd_i[3];
         endcase
         unique case (tmp)
            4'h0: in_data = 8'h3f;
            4'h1: in_data = 8'h06;
            4'h2: in_data = 8'h5b;
            4'h3: in_data = 8'h4f;
            4'h4: in_data = 8'h66;
            4'h5: in_data = 8'h6d;
            4'h6: in_data = 8'h7d;
            4'h7: in_data = 8'h07;
            4'h8: in_data = 8'h7f;
            4'h9: in_data = 8'h6f;
            4'ha: in_data = 8'h77;
            4'hb: in_data = 8'h7c;
            4'hc: in_data = 8'h39;
            4'hd: in_data = 8'h5e;
            4'he: in_data = 8'h79;
            4'hf: in_data = 8'h71;
         endcase
         in_wen = 1;
         if (out_val) begin
            state_next = state + 1;
         end
      end else if (state < 22) begin // read gpio
         unique case (state)
            18: in_daddr = MCP23017_0;
            19: in_daddr = MCP23017_1;
            20: in_daddr = MCP23017_2;
            21: in_daddr = MCP23017_3;
         endcase
         in_addr = 8'h13; // <gpio_i> = GPIOB
         in_wen = 0;
         if (out_val) begin
            state_next = state == 21 ? 10 : state + 1;
            gpio_next = {
               (state == 18 ? out_data : gpio_o[7:0]),
               (state == 19 ? out_data : gpio_o[15:8]),
               (state == 20 ? out_data : gpio_o[23:16]),
               (state == 21 ? out_data : gpio_o[31:24])
            };
         end
      end
   end

endmodule
