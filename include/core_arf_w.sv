`include "global.svh"

interface core_arf_w;
   logic en;
   logic [3:0] addr;
   logic [15:0] data;
   modport slave (
      input en,
      input addr,
      input data
   );
endinterface

