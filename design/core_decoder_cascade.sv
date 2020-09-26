`include "global.svh"

interface core_decoder_cascade;
   logic en;
   logic virgin;
   logic [15:0] dirty;
   logic stall;
   modport master (
      output en,
      output virgin,
      output dirty,
      output stall
   );
   modport slave (
      input en,
      input virgin,
      input dirty,
      input stall
   );
endinterface
