`ifndef __IVERILOG_COMPAT_INC_SV
`define __IVERILOG_COMPAT_INC_SV

`ifdef __ICARUS__
`define ALWAYS_COMB always @*
`define ALWAYS_FF always
`else
`define ALWAYS_COMB always_comb
`define ALWAYS_FF always_ff
`endif

`endif
