`include "iverilog-compat.inc.sv"
`include "k12a.inc.sv"

module k12a_memory(
    input   logic               mem_rom_ce_n,
    input   logic               mem_ram_ce_n,
    input   logic               mem_oe_n,
    input   logic               mem_we_n,

    inout   wire [15:0]         addr_bus,
    inout   wire [7:0]          data_bus
);

    parameter ROM_INIT_FILE = "";

    k12a_rom #(
        .INIT_FILE(ROM_INIT_FILE)
    ) rom(
        .addr(addr_bus[14:0]),
        .data(data_bus),
        .ce_n(mem_rom_ce_n),
        .oe_n(mem_oe_n)
    );

    k12a_ram ram(
        .addr(addr_bus[14:0]),
        .data(data_bus),
        .ce_n(mem_ram_ce_n),
        .oe_n(mem_oe_n),
        .we_n(mem_we_n)
    );

endmodule
