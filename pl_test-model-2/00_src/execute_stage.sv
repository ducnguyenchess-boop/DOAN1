module execute_stage (
    input  logic        i_clk,
    input  logic        i_resetn,
    input  logic [31:0] i_PC,
    input  logic [31:0] i_INST,
    input  logic [31:0] i_RS1,
    input  logic [31:0] i_RS2,
    input  logic [31:0] i_IMM,
    input  logic        i_ASEL,
    input  logic        i_BSEL,
    input  logic        i_BRU,
    input  logic [3:0]  i_ALU_SEL,
    input  logic [1:0]  i_fwdA_sel,
    input  logic [1:0]  i_fwdB_sel,
    input  logic [31:0] i_alu_mem,
    input  logic [31:0] i_mem_data_mem,
    input  logic [1:0]  i_wb_sel_mem,
    input  logic [31:0] i_wb_data,

    output logic [31:0] o_ALU,
    output logic [31:0] o_RS2_fwd,
    output logic [31:0] o_PC_target,
    output logic        o_PC_sel,
    output logic        o_pcpi_stall
);

    logic [31:0] forwardA, forwardB;
    logic [31:0] opA, opB;
    logic [31:0] alu_out;
    logic [31:0] pc_plus_imm, jalr_sum;
    logic        BrEq, BrLT;
    logic [2:0]  funct3;
    logic [6:0]  opcode;
    logic [6:0]  funct7;
    logic        is_branch, is_jal, is_jalr;
    logic        is_mul_insn;
    logic        is_div_insn;
    logic        branch_condition_met;
    logic [31:0] mem_fwd_data;
    logic        pcpi_mul_wr, pcpi_mul_wait, pcpi_mul_ready;
    logic [31:0] pcpi_mul_rd;
    logic        pcpi_div_wr, pcpi_div_wait, pcpi_div_ready;
    logic [31:0] pcpi_div_rd;

    // Chon du lieu MEM de forward: neu MEM la load thi dung du lieu load, nguoc lai dung ALU MEM
    assign mem_fwd_data = (i_wb_sel_mem == 2'b01) ? i_mem_data_mem : i_alu_mem;

    assign funct3    = i_INST[14:12];
    assign opcode    = i_INST[6:0];
    assign funct7    = i_INST[31:25];
    assign is_branch = (opcode == 7'b1100011);
    assign is_jal    = (opcode == 7'b1101111);
    assign is_jalr   = (opcode == 7'b1100111);
    assign is_mul_insn = (opcode == 7'b0110011) && (funct7 == 7'b0000001) &&
                         ((funct3 == 3'b000) || (funct3 == 3'b001) || (funct3 == 3'b010) || (funct3 == 3'b011));
    assign is_div_insn = (opcode == 7'b0110011) && (funct7 == 7'b0000001) &&
                         ((funct3 == 3'b100) || (funct3 == 3'b101) || (funct3 == 3'b110) || (funct3 == 3'b111));

    always_comb begin
        case (i_fwdA_sel)
            2'b10:   forwardA = mem_fwd_data;
            2'b01:   forwardA = i_wb_data;
            default: forwardA = i_RS1;
        endcase
    end

    always_comb begin
        case (i_fwdB_sel)
            2'b10:   forwardB = mem_fwd_data;
            2'b01:   forwardB = i_wb_data;
            default: forwardB = i_RS2;
        endcase
    end

    assign opA = (i_ASEL) ? i_PC : forwardA;
    assign opB = (i_BSEL) ? i_IMM : forwardB;

    ALU alu_instance (
        .i_op_a     (opA),
        .i_op_b     (opB),
        .i_alu_op   (i_ALU_SEL),
        .o_alu_data (alu_out)
    );

    pcpi_mul pcpi_mul_u (
        .clk        (i_clk),
        .resetn     (i_resetn),
        .pcpi_valid (is_mul_insn),
        .pcpi_insn  (i_INST),
        .pcpi_rs1   (forwardA),
        .pcpi_rs2   (forwardB),
        .pcpi_wr    (pcpi_mul_wr),
        .pcpi_rd    (pcpi_mul_rd),
        .pcpi_wait  (pcpi_mul_wait),
        .pcpi_ready (pcpi_mul_ready)
    );

    pcpi_div pcpi_div_u (
        .clk        (i_clk),
        .resetn     (i_resetn),
        .pcpi_valid (is_div_insn),
        .pcpi_insn  (i_INST),
        .pcpi_rs1   (forwardA),
        .pcpi_rs2   (forwardB),
        .pcpi_wr    (pcpi_div_wr),
        .pcpi_rd    (pcpi_div_rd),
        .pcpi_wait  (pcpi_div_wait),
        .pcpi_ready (pcpi_div_ready)
    );

    brc brc_instance (
        .i_rs1_data (forwardA),
        .i_rs2_data (forwardB),
        .i_br_un    (i_BRU),
        .o_br_less  (BrLT),
        .o_br_equal (BrEq)
    );

    Add_Sub_32bit adder_pc_imm (
        .A(i_PC),
        .B(i_IMM),
        .Sel(1'b0),
        .Y(pc_plus_imm),
        .Carry_out(),
        .overflow()
    );

    Add_Sub_32bit adder_jalr (
        .A(forwardA),
        .B(i_IMM),
        .Sel(1'b0),
        .Y(jalr_sum),
        .Carry_out(),
        .overflow()
    );

    always_comb begin
        case (funct3)
            3'b000:  branch_condition_met = BrEq;
            3'b001:  branch_condition_met = ~BrEq;
            3'b100:  branch_condition_met = BrLT;
            3'b101:  branch_condition_met = ~BrLT;
            3'b110:  branch_condition_met = BrLT;
            3'b111:  branch_condition_met = ~BrLT;
            default: branch_condition_met = 1'b0;
        endcase
    end

    assign o_PC_sel = is_jal || is_jalr || (is_branch && branch_condition_met);

    always_comb begin
        if (is_jalr)
            o_PC_target = {jalr_sum[31:2], 2'b00};
        else
            o_PC_target = {pc_plus_imm[31:2], 2'b00};
    end

    assign o_ALU        = is_mul_insn ? pcpi_mul_rd :
                          (is_div_insn ? pcpi_div_rd : alu_out);
    assign o_RS2_fwd    = forwardB;
    assign o_pcpi_stall = (is_mul_insn && pcpi_mul_wait) ||
                          (is_div_insn && pcpi_div_wait);

endmodule
