`include "global.svh"

interface core_decoder_preempt;
   logic jump_en;
   logic jump_kind; // 0: R[t]  1: addr
   logic lsu_en;
   logic lsu_wen;
   logic lsu_kind; // 0: R[t]  1: addr
   logic halt;
endinterface
