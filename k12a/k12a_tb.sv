`include "iverilog-compat.inc.sv"

module k12a_tb;

    parameter ROM_INIT_FILE = "programs/basic_spi.rmh.dat";

    logic clock;
    logic reset_n;

    logic [7:0] switches;
    logic [7:0] buttons;
    logic [7:0] leds;
    logic [7:0] sevenseg0;
    logic [7:0] sevenseg1;
    logic       lcd_rs;
    logic       lcd_rw;
    logic       lcd_en;
    logic [7:0] lcd_data;
    logic       spi0_sck;
    logic       spi0_mosi;
    logic       spi0_miso;
    logic       spi1_sck;
    logic       spi1_mosi;
    logic       spi1_miso;

    k12a #(
        .ROM_INIT_FILE(ROM_INIT_FILE)
    ) k12a(
        .sys_clock(clock),
        .reset_n(reset_n),
        .switches(switches),
        .buttons(buttons),
        .leds(leds),
        .sevenseg0(sevenseg0),
        .sevenseg1(sevenseg1),
        .lcd_rs(lcd_rs),
        .lcd_rw(lcd_rw),
        .lcd_en(lcd_en),
        .lcd_data(lcd_data),
        .spi0_sck(spi0_sck),
        .spi0_mosi(spi0_mosi),
        .spi0_miso(spi0_miso),
        .spi1_sck(spi1_sck),
        .spi1_mosi(spi1_mosi),
        .spi1_miso(spi1_miso)
    );

    // Clock and reset control
    always #5 clock = ~clock;
    initial begin
        clock = 1'h0;
        reset_n = 1'h1;
        #2 reset_n = 1'h0;
        #10 reset_n = 1'h1;
    end
    
    // IO
    assign spi0_miso = 1'h0;
    logic [7:0] shiftreg;
    logic [7:0] data;
    logic [2:0] count;
    always @(posedge spi0_sck or negedge reset_n) begin
        if (~reset_n) begin
            shiftreg <= 8'h00;
            data <= 8'h00;
            count <= 3'h0;
        end
        else begin
            shiftreg <= {spi0_mosi, shiftreg[7:1]};
            data <= (count == 3'h7) ? {spi0_mosi, shiftreg[7:1]} : data;
            count <= count + 3'h1;
        end
    end
    initial $monitor("[%t] %b / %h / '%c'", $time, data, data, data);
    
    // VCD dump and overall control
    initial begin
        $dumpfile("k12a_tb.vcd");
        $dumpvars;
        #40000
        $finish;
    end

endmodule
