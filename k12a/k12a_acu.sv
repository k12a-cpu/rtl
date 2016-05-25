`include "iverilog-compat.inc.sv"
`include "k12a.inc.sv"

module k12a_acu(
    input   acu_input1_sel_t    acu_input1_sel,
    input   acu_input2_sel_t    acu_input2_sel,
    input   logic               acu_load,
    
    input   logic [7:0]         c,
    input   logic [7:0]         d,
    input   logic [15:0]        inst,
    input   logic [15:0]        pc,
    input   logic [15:0]        sp,
    
    inout   wire [15:0]         addr_bus
);

    logic [15:0] acu_input1, acu_input2, acu_output;
    
    assign acu_output = acu_input1 + acu_input2;
    
    assign addr_bus = acu_load ? acu_output : 16'hzzzz;
    
    `ALWAYS_COMB begin
        acu_input1 = 16'hxxxx;
        case (acu_input1_sel)
            ACU_INPUT1_SEL_PC: acu_input1 = pc;
            ACU_INPUT1_SEL_CD: acu_input1 = {c, d};
            ACU_INPUT1_SEL_SP: acu_input1 = sp;
        endcase
    end
    
    `ALWAYS_COMB begin
        acu_input2 = 16'hxxxx;
        case (acu_input2_sel)
            ACU_INPUT2_SEL_0001:       acu_input2 = 16'h0001;
            ACU_INPUT2_SEL_0002:       acu_input2 = 16'h0002;
            ACU_INPUT2_SEL_FFFF:       acu_input2 = 16'hFFFF;
            ACU_INPUT2_SEL_REL_OFFSET: acu_input2 = {{4{inst[10]}}, inst[10:0], 1'h0};
        endcase
    end

endmodule
