`include "global.svh"

module system_wrap (
   input clk_i,
   inout i2c_scl_io,
   inout i2c_sda_io
);

   logic scl_i, scl_o, scl_t;
   logic sda_i, sda_o, sda_t;

   assign scl_i = i2c_scl_io;
   assign sda_i = i2c_sda_io;
   assign i2c_scl_io = scl_t ? scl_o : 1'bz;
   assign i2c_sda_io = sda_t ? sda_o : 1'bz;

   // TODO: system

   // TODO: io extender

endmodule
