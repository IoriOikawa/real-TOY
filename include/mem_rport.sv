`include "global.svh"

interface mem_rport;

   logic val;
   logic [7:0] addr;
   logic [15:0] rdata;
   logic rdy;

   modport master (
      output val,
      output addr,
      input rdata,
      input rdy
   );
   modport slave (
      input val,
      input addr,
      output rdata,
      output rdy
   );

endinterface
