`include "global.svh"

module system_wrap (
   input logic clk_i,
   input logic [1:0] btn_i,
   output logic [3:0] led_o,

   inout logic i2c_scl_io,
   inout logic i2c_sda_io // ,

   // output logic uart_tx_o,
   // input logic uart_rx_i,
   // input logic uart_dtr_i
);

   // TODO
   logic uart_tx_o, uart_rx_i, uart_dtr_i;
   assign uart_rx_i = 0;
   assign uart_dtr_i = 0;

   logic btn_load_i, btn_load_o;
   logic btn_look_i, btn_look_o;
   logic btn_step_i, btn_step_o;
   logic btn_run_i, btn_run_o;
   logic btn_enter_i, btn_enter_o;
   logic btn_stop_i, btn_stop_o;
   logic btn_reset_i, btn_debug_i;
   logic led_inwait_o, led_ready_o;
   logic [7:0] sw_addr_i, sw_addr_o;
   logic [15:0] sw_data_i, sw_data_o;

   logic [31:0] gpio_i, gpio_o;

   // GPIO Group 0 input: A7 -> A0
   assign sw_addr_i = gpio_o[7:0];
   // GPIO Group 0 output: B7 -> B0
   assign gpio_i[7:0] = sw_addr_o;
   // GPIO Group 1 input: A7 -> A0
   assign sw_data_i[15:8] = gpio_o[15:8];
   // GPIO Group 1 output: B7 -> B0
   assign gpio_i[15:8] = sw_data_o[15:8];
   // GPIO Group 2 input: A7 -> A0
   assign sw_data_i[7:0] = gpio_o[23:16];
   // GPIO Group 2 output: B7 -> B0
   assign gpio_i[23:16] = sw_data_o[7:0];
   // TODO: debouncing
   // GPIO Group 3 input: A7 -> A0
   assign {btn_load_i,btn_look_i,btn_step_i,btn_run_i,btn_enter_i,btn_stop_i,btn_reset_i,btn_debug_i} = gpio_o[30:24];
   // GPIO Group 3 output: B7 -> B0
   assign gpio_i[31:24] = {btn_load_o,btn_look_o,btn_step_o,btn_run_o,btn_enter_o,btn_stop_o,led_inwait_o,led_ready_o};

   logic stdout_val, stdout_rdy, stdout_flush;
   logic [15:0] stdout_data;

   logic [3:0] lcd_bcd[0:3];

   logic uart_val, uart_rdy, uart_avail;
   logic [7:0] uart_data;

   logic scl_i, scl_o, scl_t;
   logic sda_i, sda_o, sda_t;

   assign scl_i = i2c_scl_io;
   assign sda_i = i2c_sda_io;
   assign i2c_scl_io = scl_t ? scl_o : 1'bz;
   assign i2c_sda_io = sda_t ? sda_o : 1'bz;

   system i_system (
      .clk_i,

      .btn_load_i,
      .btn_load_o,
      .btn_look_i,
      .btn_look_o,
      .btn_step_i,
      .btn_step_o,
      .btn_run_i,
      .btn_run_o,
      .btn_enter_i,
      .btn_enter_o,
      .btn_stop_i,
      .btn_stop_o,

      .btn_reset_i,
      .btn_debug_i,

      .led_inwait_o,
      .led_ready_o,

      .sw_addr_i,
      .sw_addr_o,

      .sw_data_i,
      .sw_data_o,

      .stdout_val_o (stdout_val),
      .stdout_data_o (stdout_data),
      .stdout_rdy_i (stdout_rdy),
      .stdout_flush_o (stdout_flush)
   );

   oci i_oci (
      .clk_i,
      .rst_ni,

      .lcd_bcd_i (lcd_bcd),
      .gpio_i,
      .gpio_o,

      .scl_i,
      .scl_o,
      .scl_t,
      .sda_i,
      .sda_o,
      .sda_t
   );

   uart i_uart (
      .clk_i,
      .rst_ni,
      .srst_i (btn_reset_i),

      .in_val_i (uart_val),
      .in_data_i (uart_data),
      .in_rdy_o (uart_rdy),
      .avail_o (uart_avail),

      .uart_tx_o,
      .uart_rx_i,
      .uart_dtr_i
   );

   stdout i_stdout (
      .clk_i,
      .rst_ni,

      .stdout_val_i (stdout_val),
      .stdout_data_i (stdout_data),
      .stdout_rdy_o (stdout_rdy),
      .stdout_flush_i (stdout_flush),

      .lcd_bcd_o (lcd_bcd),

      .uart_val_o (uart_val),
      .uart_data_o (uart_data),
      .uart_rdy_i (uart_rdy),
      .uart_avail_i (uart_avail)
   );

endmodule
