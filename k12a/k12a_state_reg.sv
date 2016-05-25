`include "iverilog-compat.inc.sv"
`include "k12a.inc.sv"

module k12a_state_reg(
    input   logic               cpu_clock,
    input   logic               reset_n,
    
    input   state_t             next_state,
    
    output  state_t             state
);

    `ALWAYS_FF @(posedge cpu_clock or negedge reset_n) begin
        if (~reset_n) begin
            state <= STATE_FETCH1;
        end
        else begin
            state <= next_state;
        end
    end

endmodule
