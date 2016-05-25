`include "iverilog-compat.inc.sv"
`include "k12a.inc.sv"

module k12a_gp_regs(
    input   logic               cpu_clock,
    input   logic               reset_n,
    
    input   logic               a_load,
    input   logic               a_store,
    input   logic               b_store,
    input   logic               c_load,
    input   logic               c_store,
    input   logic               cd_load,
    input   cd_sel_t            cd_sel,
    input   logic               d_load,
    input   logic               d_store,
    
    inout   wire [15:0]         addr_bus,
    inout   wire [7:0]          data_bus,
    
    output  logic [7:0]         a,
    output  logic [7:0]         b,
    output  logic [7:0]         c,
    output  logic [7:0]         d
);

    logic [7:0] c_next, d_next;
    
    assign data_bus = a_load ? a : 8'hzz;
    assign data_bus = c_load ? c : 8'hzz;
    assign data_bus = d_load ? d : 8'hzz;
    assign addr_bus = cd_load ? {c, d} : 16'hzzzz;
    
    `ALWAYS_FF @(posedge cpu_clock or negedge reset_n) begin
        if (~reset_n) begin
            a <= 8'h00;
            b <= 8'h00;
            c <= 8'h00;
            d <= 8'h00;
        end
        else begin
            a <= a_store ? data_bus : a;
            b <= b_store ? data_bus : b;
            c <= c_store ? c_next : c;
            d <= d_store ? d_next : d;
        end
    end
    
    `ALWAYS_COMB begin
        c_next = 8'hxx;
        d_next = 8'hxx;
        case (cd_sel)
            CD_SEL_DATA_BUS: begin
                c_next = data_bus;
                d_next = data_bus;
            end
            CD_SEL_ADDR_BUS: begin
                c_next = addr_bus[15:8];
                d_next = addr_bus[7:0];
            end
        endcase
    end

endmodule
