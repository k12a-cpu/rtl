`include "iverilog-compat.inc.sv"
`include "k12a.inc.sv"

module k12a_memory(
    input   logic               mem_enable,
    input   mem_mode_t          mem_mode,
    input   logic               async_write,
    
    inout   wire [15:0]         addr_bus,
    inout   wire [7:0]          data_bus
);

    parameter ROM_INIT_FILE = "";

    logic rom_ce, ram_ce, oe, we;
    
    assign rom_ce = mem_enable & (addr_bus[15] == 1'h0);
    assign ram_ce = mem_enable & (addr_bus[15] == 1'h1);
    assign oe = mem_mode == MEM_MODE_READ;
    assign we = (mem_mode == MEM_MODE_WRITE) & async_write;

    ic28256 #(
        .INIT_FILE(ROM_INIT_FILE)
    ) rom(
        .addr(addr_bus[14:0]),
        .data(data_bus),
        .ce_n(~rom_ce),
        .oe_n(~oe)
    );
    
    ic62256 ram(
        .addr(addr_bus[14:0]),
        .data(data_bus),
        .ce_n(~ram_ce),
        .oe_n(~oe),
        .we_n(~we)
    );

endmodule
