`include "iverilog-compat.inc.sv"

module k12a_tb;

    parameter ROM_INIT_FILE = "/home/kier/k12a/programs/systest/systest.rmh.dat";

    logic clock;
    logic reset_n;
    logic async_write;

    logic halted;
    logic [7:0] gpio_out0;
    logic [7:0] gpio_out1;
    logic [7:0] gpio_out2;
    logic [7:0] gpio_in0 = 8'h0;
    logic [7:0] gpio_in1 = 8'h0;
    logic [7:0] gpio_in2 = 8'h0;
    logic [7:0] sevenseg0;
    logic [7:0] sevenseg1;
    logic lcd_rs;
    logic lcd_rw;
    logic lcd_en;
    logic [7:0] lcd_data;
    logic spi_sck;
    logic spi_mosi;
    logic spi_miso = 1'h0;
    logic [7:0] wake_sources = 8'h00;

    k12a #(
        .ROM_INIT_FILE(ROM_INIT_FILE)
    ) k12a(
        .cpu_clock(clock),
        .reset_n(reset_n),
        .async_write(async_write),
        .halted(halted),
        .gpio_out0(gpio_out0),
        .gpio_out1(gpio_out1),
        .gpio_out2(gpio_out2),
        .gpio_in0(gpio_in0),
        .gpio_in1(gpio_in1),
        .gpio_in2(gpio_in2),
        .sevenseg0(sevenseg0),
        .sevenseg1(sevenseg1),
        .lcd_rs(lcd_rs),
        .lcd_rw(lcd_rw),
        .lcd_en(lcd_en),
        .lcd_data(lcd_data),
        .spi_sck(spi_sck),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .wake_sources(wake_sources)
    );

    // Clock and reset control
    initial begin
        clock = 1'h0;
        async_write = 1'h0;
        reset_n = 1'h1;
        #2 reset_n = 1'h0;
        #10 reset_n = 1'h1;
    end
    always begin
        #2 async_write = 1'h1;
        #1 async_write = 1'h0;
        #2 clock = 1'h1;
        #5 clock = 1'h0;
    end

    // VCD dump and overall control
    initial begin
        $dumpfile("k12a_tb.vcd");
        $dumpvars;
        #40000
        $finish;
    end

endmodule
