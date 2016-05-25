`include "iverilog-compat.inc.sv"
`include "k12a.inc.sv"

module k12a_alu(
    input   logic               alu_load,
    input   alu_operand_sel_t   alu_operand_sel,
    
    input   logic [7:0]         a,
    input   logic [7:0]         b,
    input   logic [15:0]        inst,
    
    inout   wire [7:0]          data_bus,
    
    output  logic               alu_condition
);

    logic [7:0] alu_input1, alu_input2, alu_output;

    assign alu_input1 = a;

    assign data_bus = alu_load ? alu_output : 8'hzz;
    
    // Adder
    logic [7:0] adder_input1, adder_input2, adder_output;
    logic subtract, adder_carry_in, adder_carry_out;
    assign subtract = inst[8];
    assign adder_input1 = alu_input1;
    assign adder_input2 = subtract ? ~alu_input2 : alu_input2;
    assign adder_carry_in = subtract;
    assign {adder_carry_out, adder_output} = {1'h0, adder_input1} + {1'h0, adder_input2} + {8'h0, adder_carry_in};
    
    // Flags
    logic zero, negative, borrow, overflow, ult, ule, slt, sle;
    assign zero = alu_output == 8'h00;
    assign negative = alu_output[7];
    assign borrow = ~adder_carry_out;
    assign overflow = (adder_input1[7] ^ adder_output[7]) & (adder_input2[7] ^ adder_output[7]);
    assign ult = borrow;
    assign ule = ult | zero;
    assign slt = negative ^ overflow;
    assign sle = slt | zero;
    
    `ALWAYS_COMB begin
        alu_input2 = 8'hxx;
        case (alu_operand_sel)
            ALU_OPERAND_SEL_B:    alu_input2 = b;
            ALU_OPERAND_SEL_INST: alu_input2 = inst[7:0];
        endcase
    end
    
    `ALWAYS_COMB begin
        alu_output = 8'hxx;
        case (inst[10:8])
            3'h0: alu_output = alu_input1;
            3'h1: alu_output = alu_input1 & alu_input2;
            3'h2: alu_output = alu_input1 | alu_input2;
            3'h3: alu_output = alu_input1 ^ alu_input2;
            3'h4: alu_output = adder_output;
            3'h5: alu_output = adder_output;
            3'h6: alu_output = {alu_input1[7], alu_input1[7:1]};
            3'h7: alu_output = alu_input2;
        endcase
    end
    
    `ALWAYS_COMB begin
        alu_condition = 1'hx;
        case (inst[10:8])
            3'h0: alu_condition = zero;
            3'h1: alu_condition = negative;
            3'h2: alu_condition = borrow;
            3'h3: alu_condition = overflow;
            3'h4: alu_condition = ult;
            3'h5: alu_condition = ule;
            3'h6: alu_condition = slt;
            3'h7: alu_condition = sle;
        endcase
    end

endmodule
