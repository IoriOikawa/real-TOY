`include "global.svh"

interface mem_rwport;

   logic val;
   logic wen;
   logic [7:0] addr;
   logic [15:0] rdata;
   logic [15:0] wdata;
   logic rdy;

   modport master (
      output val,
      output wen,
      output addr,
      input rdata,
      output wdata,
      input rdy
   );
   modport slave (
      input val,
      input wen,
      input addr,
      output rdata,
      input wdata,
      output rdy
   );

endinterface
