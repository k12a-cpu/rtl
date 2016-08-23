`include "iverilog-compat.inc.sv"
`include "k12a.inc.sv"

module k12a_alu_logic(
    input   logic           adder_carry_out,
    input   logic [7:0]     adder_output,
    input   logic           adder_input1_msb,
    input   logic           adder_input2_msb,
    
    output  logic           zero,
    output  logic           negative,
    output  logic           lsb,
    output  logic           overflow,
    output  logic           ult,
    output  logic           ule,
    output  logic           slt,
    output  logic           sle
);

    logic borrow;
    assign borrow = ~adder_carry_out;

    assign zero = adder_output == 8'h00;
    assign negative = adder_output[7];
    assign lsb = adder_output[0];
    assign overflow = (adder_input1_msb ^ adder_output[7]) & (adder_input2_msb ^ adder_output[7]);
    assign ult = borrow;
    assign ule = ult | zero;
    assign slt = negative ^ overflow;
    assign sle = slt | zero;

endmodule
