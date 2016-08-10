`include "iverilog-compat.inc.sv"

// Models a 28256 (a 32 KiB asynchronous EEPROM).
module ic28256(
    input logic [14:0] addr,
    inout wire [7:0] data,
    input logic ce_n, // chip enable, active low
    input logic oe_n  // output enable, active low
);

    parameter INIT_FILE = "";

    logic [7:0] memory [0:32767];
    
    logic ce, oe;
    assign ce = ~ce_n;
    assign oe = ~oe_n;
    
    assign data = (ce & oe) ? memory[addr] : 8'hzz;
    
    initial begin
        $readmemh(INIT_FILE, memory);
    end
endmodule
