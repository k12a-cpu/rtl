`include "iverilog-compat.inc.sv"
`include "k12a.inc.sv"

module k12a_state_reg(
    input   logic               clock,
    input   logic               reset_n,

    input   state_t             state_next,

    output  state_t             state
);

    `ALWAYS_FF @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            state <= STATE_FETCH1;
        end
        else begin
            state <= state_next;
        end
    end

endmodule
