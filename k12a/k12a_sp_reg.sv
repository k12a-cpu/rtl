`include "iverilog-compat.inc.sv"
`include "k12a.inc.sv"

module k12a_sp_reg(
    input   logic               cpu_clock,
    input   logic               reset_n,
    
    input   logic               sp_load,
    input   logic               sp_store,
    
    inout   wire [15:0]         addr_bus,
    
    output  logic [15:0]        sp
);

    assign addr_bus = sp_load ? sp : 16'hzzzz;

    `ALWAYS_FF @(posedge cpu_clock or negedge reset_n) begin
        if (~reset_n) begin
            sp <= 16'h0000;
        end
        else begin
            sp <= sp_store ? addr_bus : sp;
        end
    end

endmodule
