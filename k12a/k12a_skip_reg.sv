`include "iverilog-compat.inc.sv"
`include "k12a.inc.sv"

module k12a_skip_reg(
    input   logic               cpu_clock,
    input   logic               reset_n,

    input   logic               alu_condition,
    input   skip_sel_t          skip_sel,

    output  logic               skip
);

    logic skip_next;

    `ALWAYS_FF @(posedge cpu_clock or negedge reset_n) begin
        if (~reset_n) begin
            skip <= 1'h0;
        end
        else begin
            skip <= skip_next;
        end
    end

    `ALWAYS_COMB begin
        skip_next = 1'hx;
        case (skip_sel)
            SKIP_SEL_HOLD:               skip_next = skip;
            SKIP_SEL_0:                  skip_next = 1'h0;
            SKIP_SEL_CONDITION:          skip_next = alu_condition;
            SKIP_SEL_CONDITION_INVERTED: skip_next = ~alu_condition;
        endcase
    end

endmodule
