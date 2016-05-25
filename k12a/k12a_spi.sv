`include "iverilog-compat.inc.sv"
`include "k12a.inc.sv"

module k12a_spi(
    // Global synchronisation
    input   logic               cpu_clock,
    input   logic               reset_n,
    
    // Interface to k12a_io
    input   logic               spi_data_io_load,
    input   logic               spi_data_io_store,
    input   logic               spi_begin,
    output  logic               spi_busy,
    
    // Data bus
    inout   wire [7:0]          data_bus,
    
    // SPI signals
    output  logic               spi_sck,
    output  logic               spi_mosi,
    input   logic               spi_miso
);

    logic           spi_counter_tick;
    logic           spi_counter_zero;
    spi_data_sel_t  spi_data_sel;
    logic           spi_data_store;
    spi_state_t     spi_next_state;
    spi_state_t     spi_state;
    
    assign spi_busy = spi_state != SPI_STATE_IDLE;

    k12a_spi_regs spi_regs(
        .cpu_clock(cpu_clock),
        .reset_n(reset_n),
        .spi_data_io_load(spi_data_io_load),
        .data_bus(data_bus),
        .spi_counter_zero(spi_counter_zero),
        .spi_state(spi_state),
        .spi_counter_tick(spi_counter_tick),
        .spi_data_sel(spi_data_sel),
        .spi_data_store(spi_data_store),
        .spi_next_state(spi_next_state),
        .spi_sck(spi_sck),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso)
    );
    
    k12a_spi_fsm spi_fsm(
        .spi_begin(spi_begin),
        .spi_data_io_store(spi_data_io_store),
        .spi_counter_zero(spi_counter_zero),
        .spi_state(spi_state),
        .spi_counter_tick(spi_counter_tick),
        .spi_data_sel(spi_data_sel),
        .spi_data_store(spi_data_store),
        .spi_next_state(spi_next_state),
        .spi_sck(spi_sck)
    );

endmodule
