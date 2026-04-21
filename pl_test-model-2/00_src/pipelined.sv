module pipelined (
    input  logic        i_clk,
    input  logic        i_reset,   // active-low from testbench
    input  logic [31:0] i_io_sw,

    output logic [31:0] o_io_ledr,
    output logic [31:0] o_io_ledg,
    output logic [31:0] o_io_lcd,
    output logic [6:0]  o_io_hex0,
    output logic [6:0]  o_io_hex1,
    output logic [6:0]  o_io_hex2,
    output logic [6:0]  o_io_hex3,
    output logic [6:0]  o_io_hex4,
    output logic [6:0]  o_io_hex5,
    output logic [6:0]  o_io_hex6,
    output logic [6:0]  o_io_hex7,

    output logic        o_ctrl,
    output logic        o_mispred,
    output logic [31:0] o_pc_debug,
    output logic        o_insn_vld
);

    // IF / ID wires
    logic [31:0] PC_IF, INST_IF;
    logic [31:0] PC_ID, INST_ID;

    // Decode outputs
    logic [31:0] RS1_ID_DATA, RS2_ID_DATA, IMM_ID;
    logic [31:0] PC_ID_DEC, INST_ID_DEC;
    logic [3:0]  ALU_SEL_ID;
    logic        BRU_ID, MEMRW_ID, ASEL_ID, BSEL_ID, REGWEN_ID;
    logic [2:0]  LOAD_TYPE_ID;
    logic [1:0]  STORE_TYPE_ID;
    logic [1:0]  WB_SEL_ID;
    logic [4:0]  RS1_ID, RS2_ID;
    logic        INSN_VLD_ID, IS_CTRL_ID;

    // ID / EX wires
    logic [31:0] PC_EX, INST_EX, RS1_EX, RS2_EX, IMM_EX;
    logic [3:0]  ALU_SEL_EX;
    logic        BRU_EX, MEMRW_EX, ASEL_EX, BSEL_EX, REGWEN_EX;
    logic [2:0]  LOAD_TYPE_EX;
    logic [1:0]  STORE_TYPE_EX;
    logic [1:0]  WB_SEL_EX;

    // Execute outputs
    logic [31:0] ALU_EX;
    logic [31:0] RS2_FWD_EX;
    logic [31:0] PC_TARGET_EX;
    logic        PC_SEL_EX;

    // EX / MEM wires
    logic [31:0] PC_MEM, INST_MEM, ALU_MEM, RS2_MEM;
    logic        MEMRW_MEM;
    logic [2:0]  LOAD_TYPE_MEM;
    logic [1:0]  STORE_TYPE_MEM;
    logic [1:0]  WB_SEL_MEM;
    logic        REGWEN_MEM;

    // MEM outputs
    logic [31:0] MEM_DATA_MEM;

    // MEM / WB wires
    logic [31:0] PC_WB, INST_WB, ALU_WB, MEM_WB;
    logic [1:0]  WB_SEL_WB;
    logic        REGWEN_WB;

    // WB outputs
    logic [31:0] wb_data;
    logic [4:0]  RD_WB;
    logic        WB_EN;

    // Forward / hazard
    logic [1:0] forwardA_sel, forwardB_sel;
    logic       ID_EX_FLUSH;
    logic       PC_EN, IF_ID_EN;
    logic       PCPI_STALL_EX;

    logic [31:0] EX_INST_TO_MEM;
    logic [31:0] EX_ALU_TO_MEM;
    logic [31:0] EX_RS2_TO_MEM;
    logic        EX_MEMRW_TO_MEM;
    logic [2:0]  EX_LOAD_TYPE_TO_MEM;
    logic [1:0]  EX_STORE_TYPE_TO_MEM;
    logic [1:0]  EX_WB_SEL_TO_MEM;
    logic        EX_REGWEN_TO_MEM;

    logic FLUSH_BRANCH;
    logic FLUSH_BRANCH_ONLY;  // chỉ đánh dấu nhánh được lấy (không áp cho JAL/JALR)
    logic RST;
    logic FLUSH_ID_EX_COMB;
    logic STALL_IF, STALL_ID;

    assign RST            = ~i_reset; // đổi reset thành active-high nội bộ
    assign FLUSH_BRANCH     = PC_SEL_EX;
    // Flush ID/EX khi load-use hoặc branch/jump được lấy (xóa lệnh đường sai)
    assign FLUSH_ID_EX_COMB = FLUSH_BRANCH | ID_EX_FLUSH;
    assign STALL_IF       = (~PC_EN)   | PCPI_STALL_EX;
    assign STALL_ID       = (~IF_ID_EN) | PCPI_STALL_EX;

    // While PCPI waits, hold ID/EX and inject bubbles into EX/MEM.
    assign EX_INST_TO_MEM      = PCPI_STALL_EX ? 32'h00000013 : INST_EX;
    assign EX_ALU_TO_MEM       = PCPI_STALL_EX ? 32'b0 : ALU_EX;
    assign EX_RS2_TO_MEM       = PCPI_STALL_EX ? 32'b0 : RS2_FWD_EX;
    assign EX_MEMRW_TO_MEM     = PCPI_STALL_EX ? 1'b0 : MEMRW_EX;
    assign EX_LOAD_TYPE_TO_MEM = PCPI_STALL_EX ? 3'b0 : LOAD_TYPE_EX;
    assign EX_STORE_TYPE_TO_MEM= PCPI_STALL_EX ? 2'b0 : STORE_TYPE_EX;
    assign EX_WB_SEL_TO_MEM    = PCPI_STALL_EX ? 2'b0 : WB_SEL_EX;
    assign EX_REGWEN_TO_MEM    = PCPI_STALL_EX ? 1'b0 : REGWEN_EX;

    // ------------------ IF stage ------------------
    fetch_stage IFU (
        .i_clk      (i_clk),
        .i_rst      (RST),
        .i_PC_sel   (PC_SEL_EX),
        .i_PC_target(PC_TARGET_EX),
        .i_stall    (STALL_IF),
        .i_flush    (FLUSH_BRANCH),
        .o_PC       (PC_IF),
        .o_INST     (INST_IF)
    );

    // ------------------ IF/ID ------------------
    stage_12 STAGE12 (
        .i_clk  (i_clk),
        .i_rst  (RST),
        .i_flush(FLUSH_BRANCH),
        .i_stall(STALL_ID),
        .i_PC   (PC_IF),
        .i_INST (INST_IF),
        .o_PC   (PC_ID),
        .o_INST (INST_ID)
    );

    // ------------------ ID stage ------------------
    decode_stage IDU (
        .i_clk     (i_clk),
        .i_rst     (RST),
        .i_PC      (PC_ID),
        .i_INST    (INST_ID),
        .i_wb_data (wb_data),
        .i_rd_wb   (RD_WB),
        .i_wb_en   (WB_EN),
        .o_PC      (PC_ID_DEC),
        .o_INST    (INST_ID_DEC),
        .o_RS1_data(RS1_ID_DATA),
        .o_RS2_data(RS2_ID_DATA),
        .o_IMM     (IMM_ID),
        .o_ALU_sel (ALU_SEL_ID),
        .o_BRU     (BRU_ID),
        .o_MEMRW   (MEMRW_ID),
        .o_LOAD_TYPE(LOAD_TYPE_ID),
        .o_STORE_TYPE(STORE_TYPE_ID),
        .o_WB_SEL  (WB_SEL_ID),
        .o_REGWEN  (REGWEN_ID),
        .o_ASEL    (ASEL_ID),
        .o_BSEL    (BSEL_ID),
        .o_RS1     (RS1_ID),
        .o_RS2     (RS2_ID),
        .o_insn_vld(INSN_VLD_ID),
        .o_is_ctrl (IS_CTRL_ID)
    );

    // ------------------ ID/EX ------------------
    stage_23 STAGE23 (
        .i_clk      (i_clk),
        .i_rst      (RST),
        .i_flush    (FLUSH_ID_EX_COMB),
        .i_stall    (PCPI_STALL_EX),
        .i_PC       (PC_ID_DEC),
        .i_INST     (INST_ID_DEC),
        .i_RS1      (RS1_ID_DATA),
        .i_RS2      (RS2_ID_DATA),
        .i_IMM      (IMM_ID),
        .i_ALU_SEL  (ALU_SEL_ID),
        .i_BRU      (BRU_ID),
        .i_MEMRW    (MEMRW_ID),
        .i_LOAD_TYPE(LOAD_TYPE_ID),
        .i_STORE_TYPE(STORE_TYPE_ID),
        .i_WB_SEL   (WB_SEL_ID),
        .i_REGWEN   (REGWEN_ID),
        .i_ASEL     (ASEL_ID),
        .i_BSEL     (BSEL_ID),
        .o_PC       (PC_EX),
        .o_INST     (INST_EX),
        .o_RS1      (RS1_EX),
        .o_RS2      (RS2_EX),
        .o_IMM      (IMM_EX),
        .o_ALU_SEL  (ALU_SEL_EX),
        .o_BRU      (BRU_EX),
        .o_MEMRW    (MEMRW_EX),
        .o_LOAD_TYPE(LOAD_TYPE_EX),
        .o_STORE_TYPE(STORE_TYPE_EX),
        .o_WB_SEL   (WB_SEL_EX),
        .o_REGWEN   (REGWEN_EX),
        .o_ASEL     (ASEL_EX),
        .o_BSEL     (BSEL_EX)
    );

    // ------------------ EX stage ------------------
    execute_stage EXU (
        .i_clk       (i_clk),
        .i_resetn    (i_reset),
        .i_PC        (PC_EX),
        .i_INST      (INST_EX),
        .i_RS1       (RS1_EX),
        .i_RS2       (RS2_EX),
        .i_IMM       (IMM_EX),
        .i_ASEL      (ASEL_EX),
        .i_BSEL      (BSEL_EX),
        .i_BRU       (BRU_EX),
        .i_ALU_SEL   (ALU_SEL_EX),
        .i_fwdA_sel  (forwardA_sel),
        .i_fwdB_sel  (forwardB_sel),
        .i_alu_mem   (ALU_MEM),
        .i_mem_data_mem(MEM_DATA_MEM),
        .i_wb_sel_mem (WB_SEL_MEM),
        .i_wb_data   (wb_data),
        .o_ALU       (ALU_EX),
        .o_RS2_fwd   (RS2_FWD_EX),
        .o_PC_target (PC_TARGET_EX),
        .o_PC_sel    (PC_SEL_EX),
        .o_pcpi_stall(PCPI_STALL_EX)
    );

    // ------------------ EX/MEM ------------------
    // Mispred: static not-taken, chỉ khi branch được lấy
    assign FLUSH_BRANCH_ONLY = FLUSH_BRANCH && (INST_EX[6:0] == 7'b1100011);
    forward_control FWD (
        .inst_EX_fwd(INST_EX),
        .rd_MEM     (INST_MEM[11:7]),
        .rd_WB      (INST_WB[11:7]),
        .regWEn_MEM (REGWEN_MEM),
        .regWEn_WB  (REGWEN_WB),
        .forwardA_EX(forwardA_sel),
        .forwardB_EX(forwardB_sel)
    );

    stage_34 STAGE34 (
        .i_clk      (i_clk),
        .i_rst      (RST),
        .i_flush    (1'b0), // không flush chính lệnh branch đang ở EX/MEM
        .i_PC       (PC_EX),
        .i_INST     (EX_INST_TO_MEM),
        .i_ALU      (EX_ALU_TO_MEM),
        .i_RS2      (EX_RS2_TO_MEM),
        .i_MEMRW    (EX_MEMRW_TO_MEM),
        .i_LOAD_TYPE(EX_LOAD_TYPE_TO_MEM),
        .i_STORE_TYPE(EX_STORE_TYPE_TO_MEM),
        .i_WB_SEL   (EX_WB_SEL_TO_MEM),
        .i_REGWEN   (EX_REGWEN_TO_MEM),
        .o_PC       (PC_MEM),
        .o_INST     (INST_MEM),
        .o_ALU      (ALU_MEM),
        .o_RS2      (RS2_MEM),
        .o_MEMRW    (MEMRW_MEM),
        .o_LOAD_TYPE(LOAD_TYPE_MEM),
        .o_STORE_TYPE(STORE_TYPE_MEM),
        .o_WB_SEL   (WB_SEL_MEM),
        .o_REGWEN   (REGWEN_MEM)
    );

    // ------------------ MEM stage ------------------
    mem_stage MEMU (
        .i_clk     (i_clk),
        .i_rst     (RST),
        .i_addr    (ALU_MEM),
        .i_RS2     (RS2_MEM),
        .i_MEMRW   (MEMRW_MEM),
        .i_LOAD_TYPE(LOAD_TYPE_MEM),
        .i_STORE_TYPE(STORE_TYPE_MEM),
        .i_io_sw   (i_io_sw),
        .i_io_keys (),
        .i_PC      (PC_MEM),
        .o_ld_data (MEM_DATA_MEM),
        .o_io_ledr (o_io_ledr),
        .o_io_ledg (o_io_ledg),
        .o_io_hex0 (o_io_hex0),
        .o_io_hex1 (o_io_hex1),
        .o_io_hex2 (o_io_hex2),
        .o_io_hex3 (o_io_hex3),
        .o_io_hex4 (o_io_hex4),
        .o_io_hex5 (o_io_hex5),
        .o_io_hex6 (o_io_hex6),
        .o_io_hex7 (o_io_hex7),
        .o_io_lcd  (o_io_lcd)
    );

    // ------------------ MEM/WB ------------------
    stage_45 STAGE45 (
        .i_clk    (i_clk),
        .i_rst    (RST),
        .i_flush  (1'b0), // không flush chính lệnh branch đang ở MEM/WB
        .i_PC     (PC_MEM),
        .i_INST   (INST_MEM),
        .i_ALU    (ALU_MEM),
        .i_MEM    (MEM_DATA_MEM),
        .i_WB_SEL (WB_SEL_MEM),
        .i_REGWEN (REGWEN_MEM),
        .o_PC     (PC_WB),
        .o_INST   (INST_WB),
        .o_ALU    (ALU_WB),
        .o_MEM    (MEM_WB),
        .o_WB_SEL (WB_SEL_WB),
        .o_REGWEN (REGWEN_WB)
    );

    // ------------------ WB stage ------------------
    wb_stage WBU (
        .i_PC     (PC_WB),
        .i_ALU    (ALU_WB),
        .i_ld_data    (MEM_WB),
        .i_INST   (INST_WB),
        .i_WB_SEL (WB_SEL_WB),
        .i_REGWEN (REGWEN_WB),
        .o_wb_data(wb_data),
        .o_rd     (RD_WB),
        .o_wb_en  (WB_EN)
    );

    // ------------------ Forward & Hazard ------------------
 
    hazard_detection_load HZD (
        .inst_ID_i  (INST_ID),
        .inst_EX_i  (INST_EX),
        .ID_EX_flush(ID_EX_FLUSH),
        .pc_en      (PC_EN),
        .IF_ID_en   (IF_ID_EN)
    );

    // ------------------ Debug ------------------
    // Xuất PC/valid tại WB (lệnh đã retire) cho scoreboard/trace
    assign o_pc_debug = PC_WB;
    assign o_insn_vld = (INST_WB != 32'b0); // bọt reset/flush không được tính
    assign o_ctrl     = (INST_WB[6:0] == 7'b1100011) || // Branch
                        (INST_WB[6:0] == 7'b1101111) || // JAL
                        (INST_WB[6:0] == 7'b1100111);   // JALR
    // Mispred: static not-taken, chỉ khi branch được lấy (tín hiệu từ EX).
    assign o_mispred =PC_SEL_EX;
 
endmodule
