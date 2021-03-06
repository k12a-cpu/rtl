`include "iverilog-compat.inc.sv"
`include "k12a.inc.sv"

module k12a_pc_reg(
    input   logic               clock,
    input   logic               reset_n,

    input   logic               pc_load_n,
    input   logic               pc_store,

    inout   wire [15:0]         addr_bus,

    output  logic [15:0]        pc
);

    logic pc_load;
    assign pc_load = ~pc_load_n;

    assign addr_bus = pc_load ? pc : 16'hzzzz;

    `ALWAYS_FF @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            pc <= 16'h0000;
        end
        else begin
            pc <= pc_store ? addr_bus : pc;
        end
    end

endmodule
