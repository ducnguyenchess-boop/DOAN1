module wb_stage (
    input  logic [31:0] i_PC,
    input  logic [31:0] i_ALU,
    input  logic [31:0] i_ld_data,
    input  logic [31:0] i_INST,
    input  logic [1:0]  i_WB_SEL,
    input  logic        i_REGWEN,

    output logic [31:0] o_wb_data,
    output logic [4:0]  o_rd,
    output logic        o_wb_en
);
    logic [31:0] pc_plus4;
  Add_Sub_32bit pc_add4 (
        .A(i_PC),
        .B(32'd4),
        .Sel(1'b0),
        .Y(pc_plus4),
        .Carry_out(),
        .overflow()
    );

    // Select writeback source
    always_comb begin
        case (i_WB_SEL)
            2'b00:   o_wb_data = i_ALU;      // ALU result
            2'b01:   o_wb_data = i_ld_data;  // Load data
            2'b10:   o_wb_data = pc_plus4;   // PC + 4 (JAL/JALR)
            default: o_wb_data = 32'b0;
        endcase
    end

    assign o_rd    = i_INST[11:7];
    assign o_wb_en = i_REGWEN;

endmodule
