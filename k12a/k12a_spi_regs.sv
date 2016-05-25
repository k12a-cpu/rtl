`include "iverilog-compat.inc.sv"
`include "k12a.inc.sv"

module k12a_spi_regs(
    // Global synchronisation
    input   logic               cpu_clock,
    input   logic               reset_n,
    
    // Decoded IO control signals
    input   logic               spi_data_io_load,
    
    // Data bus
    inout   wire [7:0]          data_bus,
    
    // FSM inputs
    output  logic               spi_counter_zero,
    output  spi_state_t         spi_state,
    
    // FSM outputs
    input   logic               spi_counter_tick,
    input   spi_data_sel_t      spi_data_sel,
    input   logic               spi_data_store,
    input   spi_state_t         spi_next_state,
    
    // SPI signals
    output  logic               spi_sck,
    output  logic               spi_mosi,
    input   logic               spi_miso
);

    logic [3:0] spi_counter;
    logic [7:0] spi_data, spi_data_next, spi_data_shifted;
    
    assign spi_counter_zero = ~|spi_counter;
    assign spi_sck = spi_counter[0];
    
    assign {spi_data_shifted, spi_mosi} = {spi_miso, spi_data};
    
    assign data_bus = spi_data_io_load ? spi_data : 8'hzz;
    
    `ALWAYS_FF @(posedge cpu_clock or negedge reset_n) begin
        if (~reset_n) begin
            spi_counter <= 4'h0;
            spi_data <= 8'h00;
            spi_state <= SPI_STATE_IDLE;
        end
        else begin
            spi_counter <= spi_counter_tick ? (spi_counter + 4'h1) : spi_counter;
            spi_data <= spi_data_store ? spi_data_next : spi_data;
            spi_state <= spi_next_state;
        end
    end
    
    `ALWAYS_COMB begin
        spi_data_next = 8'hxx;
        case (spi_data_sel)
            SPI_DATA_SEL_DATA_BUS: spi_data_next = data_bus;
            SPI_DATA_SEL_SHIFT:    spi_data_next = spi_data_shifted;
        endcase
    end

endmodule
