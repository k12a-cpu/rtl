`include "iverilog-compat.inc.sv"
`include "k12a.inc.sv"

module k12a_fsm(
    input   logic [15:0]        inst,
    input   state_t             state,
    input   logic               skip,
    input   logic               wake, // when high during halt state, system will transition back to fetch state.
    input   logic               addr_bus_msb,
    input   logic               async_write,

    output  logic               a_load_n,
    output  logic               a_store,
    output  acu_input1_sel_t    acu_input1_sel,
    output  acu_input2_sel_t    acu_input2_sel,
    output  logic               acu_load_n,
    output  logic               alu_load_n,
    output  alu_operand_sel_t   alu_operand_sel,
    output  logic               alu_subtract,
    output  logic               b_store,
    output  logic               c_load_n,
    output  logic               c_store,
    output  logic               cd_load_n,
    output  cd_sel_t            cd_sel,
    output  logic               d_load_n,
    output  logic               d_store,
    output  logic               inst_high_store,
    output  logic               inst_low_store,
    output  logic               io_load_n,
    output  logic               io_store_n,
    output  logic               mem_rom_ce_n,
    output  logic               mem_ram_ce_n,
    output  logic               mem_oe_n,
    output  logic               mem_we_n,
    output  logic               pc_load_n,
    output  logic               pc_store,
    output  skip_sel_t          skip_sel,
    output  logic               sp_load_n,
    output  logic               sp_store,
    output  state_t             state_next
);

    logic mem_enable;
    mem_mode_t mem_mode;
    
    logic a_load;
    logic acu_load;
    logic alu_load;
    logic c_load;
    logic cd_load;
    logic d_load;
    logic io_load;
    logic io_store;
    logic mem_rom_ce;
    logic mem_ram_ce;
    logic mem_oe;
    logic mem_we;
    logic pc_load;
    logic sp_load;
    
    assign a_load_n = ~a_load;
    assign acu_load_n = ~acu_load;
    assign alu_load_n = ~alu_load;
    assign c_load_n = ~c_load;
    assign cd_load_n = ~cd_load;
    assign d_load_n = ~d_load;
    assign io_load_n = ~io_load;
    assign io_store_n = ~io_store;
    assign mem_rom_ce_n = ~mem_rom_ce;
    assign mem_ram_ce_n = ~mem_ram_ce;
    assign mem_oe_n = ~mem_oe;
    assign mem_we_n = ~mem_we;
    assign pc_load_n = ~pc_load;
    assign sp_load_n = ~sp_load;
    
    assign mem_rom_ce = mem_enable & (addr_bus_msb == 1'h0);
    assign mem_ram_ce = mem_enable & (addr_bus_msb == 1'h1);
    assign mem_oe = mem_mode == MEM_MODE_READ;
    assign mem_we = (mem_mode == MEM_MODE_WRITE) & async_write;

    assign alu_subtract = inst[8] | ~inst[11];

    `ALWAYS_COMB begin
        a_load = 1'h0;
        a_store = 1'h0;
        acu_input1_sel = ACU_INPUT1_SEL_PC;
        acu_input2_sel = ACU_INPUT2_SEL_0001;
        acu_load = 1'h0;
        alu_load = 1'h0;
        alu_operand_sel = ALU_OPERAND_SEL_B;
        b_store = 1'h0;
        c_load = 1'h0;
        c_store = 1'h0;
        cd_load = 1'h0;
        cd_sel = CD_SEL_DATA_BUS;
        d_load = 1'h0;
        d_store = 1'h0;
        inst_high_store = 1'h0;
        inst_low_store = 1'h0;
        io_load = 1'h0;
        io_store = 1'h0;
        mem_enable = 1'h0;
        mem_mode = MEM_MODE_READ;
        pc_load = 1'h0;
        pc_store = 1'h0;
        skip_sel = SKIP_SEL_HOLD;
        sp_load = 1'h0;
        sp_store = 1'h0;
        state_next = state;

        case (state)
            STATE_FETCH1: begin
                if (skip) begin
                    // addr_bus = pc + 2
                    acu_input1_sel = ACU_INPUT1_SEL_PC;
                    acu_input2_sel = ACU_INPUT2_SEL_0002;
                    acu_load = 1'h1;
                    // pc <- addr_bus
                    pc_store = 1'h1;
                end
                else begin
                    // addr_bus = pc
                    pc_load = 1'h1;
                end
                // data_bus = M[addr_bus]
                mem_enable = 1'h1;
                mem_mode = MEM_MODE_READ;
                // inst_high <- data_bus
                inst_high_store = 1'h1;
                // skip <- 0
                skip_sel = SKIP_SEL_0;

                state_next = STATE_FETCH2;
            end

            STATE_FETCH2: begin
                // addr_bus = pc + 1
                acu_input1_sel = ACU_INPUT1_SEL_PC;
                acu_input2_sel = ACU_INPUT2_SEL_0001;
                acu_load = 1'h1;
                // pc <- addr_bus
                pc_store = 1'h1;
                // data_bus = M[addr_bus]
                mem_enable = 1'h1;
                mem_mode = MEM_MODE_READ;
                // inst_low <- data_bus
                inst_low_store = 1'h1;

                state_next = STATE_FETCH3;
            end

            STATE_FETCH3: begin
                // addr_bus = pc + 1
                acu_input1_sel = ACU_INPUT1_SEL_PC;
                acu_input2_sel = ACU_INPUT2_SEL_0001;
                acu_load = 1'h1;
                // pc <- addr_bus
                pc_store = 1'h1;

                state_next = STATE_EXEC;
            end

            STATE_EXEC: begin
                // Default
                state_next = STATE_FETCH1;

                if (inst[11]) begin // mov instruction
                    case (inst[13:12]) // source
                        2'h0: begin
                            // data_bus = ALU(a, b)
                            alu_operand_sel = ALU_OPERAND_SEL_B;
                            alu_load = 1'h1;
                        end
                        2'h1: begin
                            // data_bus = ALU(a, inst[7:0])
                            alu_operand_sel = ALU_OPERAND_SEL_INST;
                            alu_load = 1'h1;
                        end
                        2'h2: begin
                            // data_bus = c
                            c_load = 1'h1;
                        end
                        2'h3: begin
                            // data_bus = d
                            d_load = 1'h1;
                        end
                    endcase
                    case (inst[15:14]) // dest
                        2'h0: begin
                            // a <- data_bus
                            a_store = 1'h1;
                        end
                        2'h1: begin
                            // b <- data_bus
                            b_store = 1'h1;
                        end
                        2'h2: begin
                            // c <- data_bus
                            cd_sel = CD_SEL_DATA_BUS;
                            c_store = 1'h1;
                        end
                        2'h3: begin
                            // d <- data_bus
                            cd_sel = CD_SEL_DATA_BUS;
                            d_store = 1'h1;
                        end
                    endcase
                end

                else begin // not a mov instruction
                    case (inst[15:12]) // opcode
                        4'h0, 4'h4: begin // inc/dec/getsp instruction
                            if (inst[10]) begin // getsp instruction
                                // addr_bus = sp
                                sp_load = 1'h1;
                            end
                            else begin // inc/dec instruction
                                // addr_bus = cd + 0x0001 (inc)
                                //  or
                                // addr_bus = cd + 0xFFFF (dec)
                                acu_input1_sel = ACU_INPUT1_SEL_CD;
                                acu_input2_sel = inst[14] ? ACU_INPUT2_SEL_FFFF : ACU_INPUT2_SEL_0001;
                                acu_load = 1'h1;
                            end
                            // cd <- addr_bus
                            cd_sel = CD_SEL_ADDR_BUS;
                            c_store = 1'h1;
                            d_store = 1'h1;
                        end

                        4'h1: begin // in/out instruction
                            if (inst[10]) begin // out instruction
                                // data_bus = a
                                a_load = 1'h1;
                                // IO[inst[2:0]] <- data_bus
                                io_store = 1'h1;
                            end
                            else begin // in instruction
                                // data_bus = IO[inst[2:0]]
                                io_load = 1'h1;
                                // a <- data_bus
                                a_store = 1'h1;
                            end
                        end

                        4'h2: begin // ld/pop instruction
                            if (inst[10]) begin // pop instruction
                                // addr_bus = sp
                                sp_load = 1'h1;
                                state_next = STATE_POP; // Additional state deals with incrementing SP
                            end
                            else begin // ld instruction
                                // addr_bus = cd
                                cd_load = 1'h1;
                            end
                            // data_bus = M[addr_bus]
                            mem_enable = 1'h1;
                            mem_mode = MEM_MODE_READ;
                            // a <- data_bus
                            a_store = 1'h1;
                        end

                        4'h3: begin // ldd instruction
                            // addr_bus = sp + inst[10:0]
                            acu_input1_sel = ACU_INPUT1_SEL_SP;
                            acu_input2_sel = ACU_INPUT2_SEL_REL_OFFSET;
                            acu_load = 1'h1;
                            // data_bus = M[addr_bus]
                            mem_enable = 1'h1;
                            mem_mode = MEM_MODE_READ;
                            // a <- data_bus
                            a_store = 1'h1;
                        end

                        4'h5: begin // addsp instruction
                            // addr_bus = sp + inst[10:0]
                            acu_input1_sel = ACU_INPUT1_SEL_SP;
                            acu_input2_sel = ACU_INPUT2_SEL_REL_OFFSET;
                            acu_load = 1'h1;
                            // sp <- addr_bus
                            sp_store = 1'h1;
                        end

                        4'h6: begin // st/push instruction
                            if (inst[10]) begin // push instruction
                                // addr_bus = sp - 1
                                acu_input1_sel = ACU_INPUT1_SEL_SP;
                                acu_input2_sel = ACU_INPUT2_SEL_FFFF;
                                acu_load = 1'h1;
                                // sp <- addr_bus
                                sp_store = 1'h1;
                            end
                            else begin
                                // addr_bus = cd
                                cd_load = 1'h1;
                            end
                            // data_bus = a
                            a_load = 1'h1;
                            // M[addr_bus] <- data_bus
                            mem_enable = 1'h1;
                            mem_mode = MEM_MODE_WRITE;
                        end

                        4'h7: begin // std instruction
                            // addr_bus = sp + inst[10:0]
                            acu_input1_sel = ACU_INPUT1_SEL_SP;
                            acu_input2_sel = ACU_INPUT2_SEL_REL_OFFSET;
                            acu_load = 1'h1;
                            // data_bus = a
                            a_load = 1'h1;
                            // M[addr_bus] <- data_bus
                            mem_enable = 1'h1;
                            mem_mode = MEM_MODE_WRITE;
                        end

                        4'h8, 4'h9, 4'hA, 4'hB: begin // sk/ski/skn/skni instruction
                            // compute ALU(a, b / i)
                            alu_operand_sel = inst[12] ? ALU_OPERAND_SEL_INST : ALU_OPERAND_SEL_B;
                            // skip <- alu_condition / ~alu_condition
                            skip_sel = inst[13] ? SKIP_SEL_CONDITION_N : SKIP_SEL_CONDITION;
                        end

                        4'hC, 4'hD: begin // rjmp/rcall instruction
                            // addr_bus = pc
                            pc_load = 1'h1;
                            // cd <- addr_bus (only if rcall)
                            cd_sel = CD_SEL_ADDR_BUS;
                            if (inst[12]) begin
                                c_store = 1'h1;
                                d_store = 1'h1;
                            end

                            state_next = STATE_RJMP;
                        end

                        4'hE: begin // ljmp/putsp instruction
                            // addr_bus = cd
                            cd_load = 1'h1;

                            if (inst[10]) begin // putsp instruction
                                // sp <- addr_bus
                                sp_store = 1'h1;
                            end
                            else begin // ljmp instruction
                                // pc <- addr_bus
                                pc_store = 1'h1;
                            end
                        end

                        4'hF: begin // halt instruction
                            state_next = STATE_HALT;
                        end
                    endcase
                end
            end

            STATE_POP: begin
                // addr_bus = sp + 1
                acu_input1_sel = ACU_INPUT1_SEL_SP;
                acu_input2_sel = ACU_INPUT2_SEL_0001;
                acu_load = 1'h1;
                // sp <- addr_bus
                sp_store = 1'h1;

                state_next = STATE_FETCH1;
            end

            STATE_RJMP: begin
                // addr_bus = pc + rel_offset
                acu_input1_sel = ACU_INPUT1_SEL_PC;
                acu_input2_sel = ACU_INPUT2_SEL_REL_OFFSET;
                acu_load = 1'h1;
                // pc <- addr_bus
                pc_store = 1'h1;

                state_next = STATE_FETCH1;
            end

            STATE_HALT: begin
                if (wake) begin
                    state_next = STATE_FETCH1;
                end
                else begin
                    // do nothing
                    state_next = STATE_HALT;
                end
            end
        endcase
    end

endmodule
