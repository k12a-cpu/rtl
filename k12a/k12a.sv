`include "iverilog-compat.inc.sv"
`include "k12a.inc.sv"

module k12a(
    input   logic               cpu_clock,
    input   logic               reset_n,
    input   logic               async_write,

    output  logic               halted,

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
    input   logic [7:0]         wake_sources
);

    parameter ROM_INIT_FILE = "";

    wire [7:0]          data_bus;
    wire [15:0]         addr_bus;

    logic [7:0]         a;
    logic               a_load;
    logic               a_store;
    acu_input1_sel_t    acu_input1_sel;
    acu_input2_sel_t    acu_input2_sel;
    logic               acu_load;
    logic               alu_condition;
    logic               alu_load;
    alu_operand_sel_t   alu_operand_sel;
    logic [7:0]         b;
    logic               b_store;
    logic [7:0]         c;
    logic               c_load;
    logic               c_store;
    logic               cd_load;
    cd_sel_t            cd_sel;
    logic [7:0]         d;
    logic               d_load;
    logic               d_store;
    logic [15:0]        inst;
    logic               inst_high_store;
    logic               inst_low_store;
    logic               io_load;
    logic               io_store;
    logic               is_skip;
    logic               mem_enable;
    mem_mode_t          mem_mode;
    state_t             next_state;
    logic [15:0]        pc;
    logic               pc_load;
    logic               pc_store;
    logic               skip;
    skip_sel_t          skip_sel;
    logic [15:0]        sp;
    logic               sp_load;
    logic               sp_store;
    state_t             state;
    logic               wake;

    assign halted = state == STATE_HALT;

    k12a_fsm fsm(
        .inst(inst),
        .state(state),
        .skip(skip),
        .wake(wake),
        .a_load(a_load),
        .a_store(a_store),
        .acu_input1_sel(acu_input1_sel),
        .acu_input2_sel(acu_input2_sel),
        .acu_load(acu_load),
        .alu_load(alu_load),
        .alu_operand_sel(alu_operand_sel),
        .b_store(b_store),
        .c_load(c_load),
        .c_store(c_store),
        .cd_load(cd_load),
        .cd_sel(cd_sel),
        .d_load(d_load),
        .d_store(d_store),
        .inst_high_store(inst_high_store),
        .inst_low_store(inst_low_store),
        .io_load(io_load),
        .io_store(io_store),
        .is_skip(is_skip),
        .mem_enable(mem_enable),
        .mem_mode(mem_mode),
        .next_state(next_state),
        .pc_load(pc_load),
        .pc_store(pc_store),
        .skip_sel(skip_sel),
        .sp_load(sp_load),
        .sp_store(sp_store)
    );

    k12a_acu acu(
        .acu_input1_sel(acu_input1_sel),
        .acu_input2_sel(acu_input2_sel),
        .acu_load(acu_load),
        .c(c),
        .d(d),
        .inst(inst),
        .pc(pc),
        .sp(sp),
        .addr_bus(addr_bus)
    );

    k12a_alu alu(
        .alu_load(alu_load),
        .alu_operand_sel(alu_operand_sel),
        .a(a),
        .b(b),
        .inst(inst),
        .data_bus(data_bus),
        .is_skip(is_skip),
        .alu_condition(alu_condition)
    );

    k12a_state_reg state_reg(
        .cpu_clock(cpu_clock),
        .reset_n(reset_n),
        .next_state(next_state),
        .state(state)
    );

    k12a_skip_reg skip_reg(
        .cpu_clock(cpu_clock),
        .reset_n(reset_n),
        .alu_condition(alu_condition),
        .skip_sel(skip_sel),
        .skip(skip)
    );

    k12a_pc_reg pc_reg(
        .cpu_clock(cpu_clock),
        .reset_n(reset_n),
        .pc_load(pc_load),
        .pc_store(pc_store),
        .addr_bus(addr_bus),
        .pc(pc)
    );

    k12a_sp_reg sp_reg(
        .cpu_clock(cpu_clock),
        .reset_n(reset_n),
        .sp_load(sp_load),
        .sp_store(sp_store),
        .addr_bus(addr_bus),
        .sp(sp)
    );

    k12a_inst_regs inst_regs(
        .cpu_clock(cpu_clock),
        .reset_n(reset_n),
        .inst_high_store(inst_high_store),
        .inst_low_store(inst_low_store),
        .addr_bus(addr_bus),
        .data_bus(data_bus),
        .inst(inst)
    );

    k12a_gp_regs gp_regs(
        .cpu_clock(cpu_clock),
        .reset_n(reset_n),
        .a_load(a_load),
        .a_store(a_store),
        .b_store(b_store),
        .c_load(c_load),
        .c_store(c_store),
        .cd_load(cd_load),
        .cd_sel(cd_sel),
        .d_load(d_load),
        .d_store(d_store),
        .addr_bus(addr_bus),
        .data_bus(data_bus),
        .a(a),
        .b(b),
        .c(c),
        .d(d)
    );

    k12a_memory #(
        .ROM_INIT_FILE(ROM_INIT_FILE)
    ) memory(
        .mem_enable(mem_enable),
        .mem_mode(mem_mode),
        .async_write(async_write),
        .addr_bus(addr_bus),
        .data_bus(data_bus)
    );

    k12a_io io(
        .cpu_clock(cpu_clock),
        .reset_n(reset_n),
        .async_write(async_write),
        .io_load(io_load),
        .io_store(io_store),
        .io_addr(inst[2:0]),
        .data_bus(data_bus),
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
        .wake_sources(wake_sources),
        .wake(wake)
    );

endmodule
