`include "global.svh"

interface stdio;
   logic val;
   logic [15:0] data;
   logic rdy;
   modport in (
      input val,
      input data,
      output rdy
   );
   modport out (
      output val,
      output data,
      input rdy
   );
endinterface
