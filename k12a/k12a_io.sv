`include "iverilog-compat.inc.sv"
`include "k12a.inc.sv"

module k12a_io(
    input   logic               cpu_clock,
    input   logic               reset_n,
    input   logic               async_write,

    input   logic               io_load_n,
    input   logic               io_store_n,
    input   logic [2:0]         io_addr,

    inout   wire [7:0]          data_bus,

    output  logic [7:0]         gpio_out0,
    output  logic [7:0]         gpio_out1,
    output  logic [7:0]         gpio_out2,
    input   logic [7:0]         gpio_in0,
    input   logic [7:0]         gpio_in1,
    input   logic [7:0]         gpio_in2,
    output  logic [7:0]         sevenseg0, // dot, a, b, c, d, e, f, g
    output  logic [7:0]         sevenseg1,
    output  logic               lcd_rs, // 0: instruction, 1: data
    output  logic               lcd_rw, // 0: write, 1: read
    output  logic               lcd_en,
    output  logic [7:0]         lcd_data,
    output  logic               spi_sck,
    output  logic               spi_mosi,
    input   logic               spi_miso,
    input   logic [7:0]         wake_sources,

    output  logic               wake
);

    logic io_load, io_store;
    assign io_load = ~io_load_n;
    assign io_store = ~io_store_n;

    logic gpio_out0_load;
    logic gpio_out1_load;
    logic gpio_out2_load;
    logic control_load;
    logic gpio_in0_load;
    logic gpio_in1_load;
    logic gpio_in2_load;
    logic spi_data_load;

    logic gpio_out0_store;
    logic gpio_out1_store;
    logic gpio_out2_store;
    logic control_store;
    logic sevenseg0_store;
    logic sevenseg1_store;
    logic lcd_data_store;
    logic spi_data_store;

    logic lcd_xfer;
    logic spi_begin;
    logic spi_busy;
    logic [5:0] control;
    logic sevenseg0_mode;
    logic sevenseg1_mode;
    logic [7:0] sevenseg0_reg;
    logic [7:0] sevenseg1_reg;
    logic [6:0] sevenseg0_decoded;
    logic [6:0] sevenseg1_decoded;

    assign sevenseg0_mode = control[0];
    assign sevenseg1_mode = control[1];
    assign lcd_rs = control[2];
    assign lcd_xfer = control_store & data_bus[6];
    assign spi_begin = control_store & data_bus[7];

    assign sevenseg0 = sevenseg0_mode ? {1'h0, sevenseg0_decoded} : sevenseg0_reg;
    assign sevenseg1 = sevenseg1_mode ? {1'h0, sevenseg1_decoded} : sevenseg1_reg;

    assign lcd_rw = 1'h0; // always write
    assign lcd_en = lcd_xfer & async_write;

    assign wake = |wake_sources;

    assign data_bus = gpio_out0_load ? gpio_out0 : 8'hzz;
    assign data_bus = gpio_out1_load ? gpio_out1 : 8'hzz;
    assign data_bus = gpio_out2_load ? gpio_out2 : 8'hzz;
    assign data_bus = control_load ? {spi_busy, 1'h0, control} : 8'hzz;
    assign data_bus = gpio_in0_load ? gpio_in0 : 8'hzz;
    assign data_bus = gpio_in1_load ? gpio_in1 : 8'hzz;
    assign data_bus = gpio_in2_load ? gpio_in2 : 8'hzz;

    // Registers
    `ALWAYS_FF @(posedge cpu_clock or negedge reset_n) begin
        if (~reset_n) begin
            gpio_out0 <= 8'h00;
            gpio_out1 <= 8'h00;
            gpio_out2 <= 8'h00;
            control <= 6'h00;
            sevenseg0_reg <= 8'h00;
            sevenseg1_reg <= 8'h00;
            lcd_data <= 8'h00;
        end
        else begin
            gpio_out0 <= gpio_out0_store ? data_bus : gpio_out0;
            gpio_out1 <= gpio_out1_store ? data_bus : gpio_out1;
            gpio_out2 <= gpio_out2_store ? data_bus : gpio_out2;
            control <= control_store ? data_bus[5:0] : control;
            sevenseg0_reg <= sevenseg0_store ? data_bus : sevenseg0_reg;
            sevenseg1_reg <= sevenseg1_store ? data_bus : sevenseg1_reg;
            lcd_data <= lcd_data_store ? data_bus : lcd_data;
        end
    end

    // IO address demultiplexer
    `ALWAYS_COMB begin
        gpio_out0_load = 1'h0;
        gpio_out1_load = 1'h0;
        gpio_out2_load = 1'h0;
        control_load = 1'h0;
        gpio_in0_load = 1'h0;
        gpio_in1_load = 1'h0;
        gpio_in2_load = 1'h0;
        spi_data_load = 1'h0;

        gpio_out0_store = 1'h0;
        gpio_out1_store = 1'h0;
        gpio_out2_store = 1'h0;
        control_store = 1'h0;
        sevenseg0_store = 1'h0;
        sevenseg1_store = 1'h0;
        lcd_data_store = 1'h0;
        spi_data_store = 1'h0;

        case (io_addr)
            3'h0: begin
                gpio_out0_load = io_load;
                gpio_out0_store = io_store;
            end
            3'h1: begin
                gpio_out1_load = io_load;
                gpio_out1_store = io_store;
            end
            3'h2: begin
                gpio_out2_load = io_load;
                gpio_out2_store = io_store;
            end
            3'h3: begin
                control_load = io_load;
                control_store = io_store;
            end
            3'h4: begin
                gpio_in0_load = io_load;
                sevenseg0_store = io_store;
            end
            3'h5: begin
                gpio_in1_load = io_load;
                sevenseg1_store = io_store;
            end
            3'h6: begin
                gpio_in2_load = io_load;
                lcd_data_store = io_store;
            end
            3'h7: begin
                spi_data_load = io_load;
                spi_data_store = io_store;
            end
        endcase
    end

    k12a_sevenseg_decoders sevenseg_decoders(
        .digit0(sevenseg0_reg[3:0]),
        .segments0(sevenseg0_decoded),
        .digit1(sevenseg1_reg[3:0]),
        .segments1(sevenseg1_decoded)
    );

    k12a_spi spi(
        .cpu_clock(cpu_clock),
        .reset_n(reset_n),
        .spi_data_io_load(spi_data_load),
        .spi_data_io_store(spi_data_store),
        .spi_begin(spi_begin),
        .spi_busy(spi_busy),
        .data_bus(data_bus),
        .spi_sck(spi_sck),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso)
    );

endmodule
