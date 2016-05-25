`include "iverilog-compat.inc.sv"
`include "k12a.inc.sv"

module k12a_io(
    input   logic               cpu_clock,
    input   logic               reset_n,
    input   logic               async_write,
    
    input   logic               io_load,
    input   logic               io_store,
    input   logic [2:0]         io_addr,
    
    inout   wire [7:0]          data_bus,
    
    input   logic [7:0]         switches_phy,
    input   logic [7:0]         switches_ext,
    input   logic               sel_switches,
    input   logic [7:0]         buttons_phy,
    input   logic [7:0]         buttons_ext,
    output  logic [7:0]         leds,
    output  logic [7:0]         sevenseg0, // dot, a, b, c, d, e, f, g
    output  logic [7:0]         sevenseg1,
    output  logic               lcd_rs, // 0: instruction, 1: data
    output  logic               lcd_rw, // 0: write, 1: read
    output  logic               lcd_en,
    output  logic [7:0]         lcd_data,
    output  logic               spi0_sck,
    output  logic               spi0_mosi,
    input   logic               spi0_miso,
    output  logic               spi1_sck,
    output  logic               spi1_mosi,
    input   logic               spi1_miso
);

    logic [7:0] switches;
    logic [7:0] buttons;
    logic [7:0] sevenseg0_buffer;
    logic [7:0] sevenseg1_buffer;
    logic [6:0] sevenseg0_decoded;
    logic [6:0] sevenseg1_decoded;
    logic [4:0] control;
    
    logic sevenseg0_mode;
    logic sevenseg1_mode;
    logic lcd_xfer;
    
    logic spi0_data_io_load;
    logic spi0_data_io_store;
    logic spi0_begin;
    logic spi0_busy;
    logic spi1_data_io_load;
    logic spi1_data_io_store;
    logic spi1_begin;
    logic spi1_busy;
    
    assign switches = sel_switches ? switches_ext : switches_phy;
    assign buttons = buttons_phy | buttons_ext;
    
    assign sevenseg0 = sevenseg0_mode ? {1'h0, sevenseg0_decoded} : sevenseg0_buffer;
    assign sevenseg1 = sevenseg1_mode ? {1'h0, sevenseg1_decoded} : sevenseg1_buffer;
    
    assign lcd_rw = 1'h0;
    assign lcd_en = lcd_xfer & async_write;
    
    assign sevenseg0_mode = control[0];
    assign sevenseg1_mode = control[1];
    assign lcd_rs = control[4];
    assign lcd_xfer = io_store & (io_addr == 3'h4) & data_bus[5];
    assign spi0_begin = io_store & (io_addr == 3'h4) & data_bus[6];
    assign spi1_begin = io_store & (io_addr == 3'h4) & data_bus[7];
    
    assign data_bus = (io_load & (io_addr == 3'h0)) ? switches : 8'hzz;
    assign data_bus = (io_load & (io_addr == 3'h1)) ? buttons : 8'hzz;
    assign data_bus = (io_load & (io_addr == 3'h2)) ? leds : 8'hzz;
    assign data_bus = (io_load & (io_addr == 3'h4)) ? {spi1_busy, spi0_busy, 1'h0, control} : 8'hzz;
    
    assign spi0_data_io_load  = io_load  & (io_addr == 3'h6);
    assign spi0_data_io_store = io_store & (io_addr == 3'h6);
    assign spi1_data_io_load  = io_load  & (io_addr == 3'h7);
    assign spi1_data_io_store = io_store & (io_addr == 3'h7);
    
    `ALWAYS_FF @(posedge cpu_clock or negedge reset_n) begin
        if (~reset_n) begin
            sevenseg0_buffer <= 8'h00;
            sevenseg1_buffer <= 8'h00;
            leds <= 8'h00;
            control <= 5'h00;
            lcd_data <= 8'h00;
        end
        else begin
            sevenseg0_buffer <= (io_store & (io_addr == 3'h0)) ? data_bus : sevenseg0_buffer;
            sevenseg1_buffer <= (io_store & (io_addr == 3'h1)) ? data_bus : sevenseg1_buffer;
            leds             <= (io_store & (io_addr == 3'h2)) ? data_bus : leds;
            control          <= (io_store & (io_addr == 3'h4)) ? data_bus[4:0] : control;
            lcd_data         <= (io_store & (io_addr == 3'h5)) ? data_bus : lcd_data;
        end
    end
    
    k12a_sevenseg_decoder sevenseg0_decoder(
        .digit(sevenseg0_buffer[3:0]),
        .segments(sevenseg0_decoded)
    );
    
    k12a_sevenseg_decoder sevenseg1_decoder(
        .digit(sevenseg1_buffer[3:0]),
        .segments(sevenseg1_decoded)
    );
    
    k12a_spi spi0(
        .cpu_clock(cpu_clock),
        .reset_n(reset_n),
        .spi_data_io_load(spi0_data_io_load),
        .spi_data_io_store(spi0_data_io_store),
        .spi_begin(spi0_begin),
        .spi_busy(spi0_busy),
        .data_bus(data_bus),
        .spi_sck(spi0_sck),
        .spi_mosi(spi0_mosi),
        .spi_miso(spi0_miso)
    );
    
    k12a_spi spi1(
        .cpu_clock(cpu_clock),
        .reset_n(reset_n),
        .spi_data_io_load(spi1_data_io_load),
        .spi_data_io_store(spi1_data_io_store),
        .spi_begin(spi1_begin),
        .spi_busy(spi1_busy),
        .data_bus(data_bus),
        .spi_sck(spi1_sck),
        .spi_mosi(spi1_mosi),
        .spi_miso(spi1_miso)
    );

endmodule
