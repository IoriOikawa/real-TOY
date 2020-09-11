`include "global.svh"

module system_wrap (
   input clk_i,
   inout i2c_scl_io,
   inout i2c_sda_io
);

   logic i2c_scl_i, i2c_scl_o, i2c_scl_t;
   logic i2c_sda_i, i2c_sda_o, i2c_sda_t;
   /*
   IOBUF i_i2c_scl_iobuf (
      .IO (i2c_scl_io),
      .I  (i2c_scl_i),
      .O  (i2c_scl_o),
      .T  (i2c_scl_t)
   );
   IOBUF i_i2c_sda_iobuf (
      .IO (i2c_sda_io),
      .I  (i2c_sda_i),
      .O  (i2c_sda_o),
      .T  (i2c_sda_t)
   );
   */

   // TODO: system

   // TODO: io extender

endmodule
