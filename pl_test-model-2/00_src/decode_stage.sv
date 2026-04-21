module decode_stage (
    input  logic        i_clk,
    input  logic        i_rst,
    input  logic [31:0] i_PC,
    input  logic [31:0] i_INST,

    // Writeback feedback into RegFile
    input  logic [31:0] i_wb_data,
    input  logic [4:0]  i_rd_wb,
    input  logic        i_wb_en,

    // Outputs into ID/EX pipeline register
    output logic [31:0] o_PC,
    output logic [31:0] o_INST,
    output logic [31:0] o_RS1_data,
    output logic [31:0] o_RS2_data,
    output logic [31:0] o_IMM,
    output logic [3:0]  o_ALU_sel,
    output logic        o_BRU,
    output logic        o_MEMRW,
    output logic [2:0]  o_LOAD_TYPE,
    output logic [1:0]  o_STORE_TYPE,
    output logic [1:0]  o_WB_SEL,
    output logic        o_REGWEN,
    output logic        o_ASEL,
    output logic        o_BSEL,

    // For hazard/forward units
    output logic [4:0]  o_RS1,
    output logic [4:0]  o_RS2,
    output logic        o_insn_vld,
    output logic        o_is_ctrl
);

    logic [2:0] imm_sel;

    // Register file reads
    regfile rf (
        .clk    (i_clk),
        .reset  (i_rst),
        .rs1_addr    (o_RS1),
        .rs2_addr   (o_RS2),
        .rd_addr (i_rd_wb),
        .rd_data (i_wb_data),
        .rd_wren (i_wb_en),
        .data_1 (o_RS1_data),
        .data_2 (o_RS2_data)
    );

    // Immediate generator
    Imm_Gen ig (
        .instr    (i_INST),
        .Imm_Sel  (imm_sel),
        .imm_out  (o_IMM)
    );

    // Control logic
    logic pc_sel_unused;
    control_unit cu (
        .instr      (i_INST),
        .br_less    (1'b0),
        .br_equal   (1'b0),
        .pc_sel     (pc_sel_unused),
        .i_rd_wren  (o_REGWEN),
        .BrUn       (o_BRU),
        .opa_sel    (o_ASEL),
        .opb_sel    (o_BSEL),
        .i_alu_op   (o_ALU_sel),
        .MemRW      (o_MEMRW),
        .wb_sel     (o_WB_SEL),
        .load_type  (o_LOAD_TYPE),
        .store_type (o_STORE_TYPE),
        .Imm_Sel    (imm_sel),
        .insn_vld   (o_insn_vld)
    );

    // Decode-time helpers
    assign o_RS1 = i_INST[19:15];
    assign o_RS2 = i_INST[24:20];

    assign o_PC   = i_PC;
    assign o_INST = i_INST;

    // Identify control-flow instructions (for debug/trace)
    assign o_is_ctrl =
            (i_INST[6:0] == 7'b1100011) || // Branch
            (i_INST[6:0] == 7'b1101111) || // JAL
            (i_INST[6:0] == 7'b1100111);   // JALR

endmodule
