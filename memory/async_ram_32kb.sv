`include "iverilog-compat.inc.sv"

// Models a 62256 (a 32 KiB asynchronous SRAM).
module async_ram_32kb(
    input logic [14:0] addr,
    inout wire [7:0] data,
    input logic ce_n, // chip enable, active low
    input logic oe_n, // output enable, active low
    input logic we_n  // write enable, active low
);

    logic [7:0] memory [0:32767];
    
    logic ce, oe, we;
    assign ce = ~ce_n;
    assign oe = ~oe_n;
    assign we = ~we_n;
    
    assign data = (ce & oe) ? memory[addr] : 8'hzz;
    
    always @* begin
        if (ce & we) begin
            memory[addr] = data;
        end
    end
endmodule
