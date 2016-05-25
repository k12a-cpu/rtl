`include "iverilog-compat.inc.sv"
`include "k12a.inc.sv"

module k12a_spi_fsm(
    // Decoded IO control signals
    input   logic               spi_begin,
    input   logic               spi_data_io_store,
    
    // FSM inputs
    input   logic               spi_counter_zero,
    input   spi_state_t         spi_state,
    
    // FSM outputs
    output  logic               spi_counter_tick,
    output  spi_data_sel_t      spi_data_sel,
    output  logic               spi_data_store,
    output  spi_state_t         spi_next_state,
    
    // SPI signal feedback from k12a_spi_regs
    input   logic               spi_sck
);

    `ALWAYS_COMB begin
        spi_counter_tick = 1'h0;
        spi_data_sel = SPI_DATA_SEL_DATA_BUS;
        spi_data_store = 1'h0;
        spi_next_state = spi_state;
    
        case (spi_state)
            SPI_STATE_IDLE: begin
                if (spi_data_io_store) begin
                    spi_data_sel = SPI_DATA_SEL_DATA_BUS;
                    spi_data_store = 1'h1;
                end
                if (spi_begin) begin
                    spi_counter_tick = 1'h1;
                    spi_next_state = SPI_STATE_XFER;
                end
            end
            
            SPI_STATE_XFER: begin
                if (spi_sck) begin
                    // On the next cpu clock event, an SCK falling edge will occur.
                    // Shift the data reg simultaneously.
                    spi_data_sel = SPI_DATA_SEL_SHIFT;
                    spi_data_store = 1'h1;
                end
                if (spi_counter_zero) begin
                    spi_next_state = SPI_STATE_IDLE;
                end
                else begin
                    spi_counter_tick = 1'h1;
                end
            end
        endcase
    end

endmodule
