`include "global.svh"

module system_wrap (
   input clk_i,
   inout i2c_scl_io,
   inout i2c_sda_io
);

   logic scl_i, scl_o, scl_t;
   logic sda_i, sda_o, sda_t;

   IOBUF i_scl_iobuf (
      .IO (i2c_scl_io),
      .I  (scl_i),
      .O  (scl_o),
      .T  (scl_t)
   );
   IOBUF i_sda_iobuf (
      .IO (i2c_sda_io),
      .I  (sda_i),
      .O  (sda_o),
      .T  (sda_t)
   );

   // TODO: system

   // TODO: io extender

endmodule
