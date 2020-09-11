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
