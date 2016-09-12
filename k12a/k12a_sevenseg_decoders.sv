`include "iverilog-compat.inc.sv"
`include "k12a.inc.sv"

module k12a_sevenseg_decoders(
    input   logic [3:0]         digit0,
    output  logic [6:0]         segments0, // abcdefg
    input   logic [3:0]         digit1,
    output  logic [6:0]         segments1 // abcdefg
);

    k12a_sevenseg_decoder decoder0(
        .digit(digit0),
        .segments(segments0)
    );
    
    k12a_sevenseg_decoder decoder1(
        .digit(digit1),
        .segments(segments1)
    );

endmodule
