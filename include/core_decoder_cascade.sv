`include "global.svh"

interface core_decoder_cascade;
   logic en;
   logic virgin;
   logic [15:0] dirty;
   logic stall;
endinterface
