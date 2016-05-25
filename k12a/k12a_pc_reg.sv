`include "iverilog-compat.inc.sv"
`include "k12a.inc.sv"

module k12a_pc_reg(
    input   logic               cpu_clock,
    input   logic               reset_n,
    
    input   logic               pc_load,
    input   logic               pc_store,
    
    inout   wire [15:0]         addr_bus,
    
    output  logic [15:0]        pc
);

    assign addr_bus = pc_load ? pc : 16'hzzzz;

    `ALWAYS_FF @(posedge cpu_clock or negedge reset_n) begin
        if (~reset_n) begin
            pc <= 16'h0000;
        end
        else begin
            pc <= pc_store ? addr_bus : pc;
        end
    end

endmodule
