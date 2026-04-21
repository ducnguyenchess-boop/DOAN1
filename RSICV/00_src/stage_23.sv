module stage_23 (
    input  logic        i_clk,
    input  logic        i_rst,
    input  logic        i_flush,
    input  logic        i_stall,

    input  logic [31:0] i_PC,
    input  logic [31:0] i_INST,
    input  logic [31:0] i_RS1,
    input  logic [31:0] i_RS2,
    input  logic [31:0] i_IMM,
    input  logic [3:0]  i_ALU_SEL,
    input  logic        i_BRU,
    input  logic        i_MEMRW,
    input  logic [2:0]  i_LOAD_TYPE,
    input  logic [1:0]  i_STORE_TYPE,
    input  logic [1:0]  i_WB_SEL,
    input  logic        i_REGWEN,
    input  logic        i_ASEL,
    input  logic        i_BSEL,

    output logic [31:0] o_PC,
    output logic [31:0] o_INST,
    output logic [31:0] o_RS1,
    output logic [31:0] o_RS2,
    output logic [31:0] o_IMM,
    output logic [3:0]  o_ALU_SEL,
    output logic        o_BRU,
    output logic        o_MEMRW,
    output logic [2:0]  o_LOAD_TYPE,
    output logic [1:0]  o_STORE_TYPE,
    output logic [1:0]  o_WB_SEL,
    output logic        o_REGWEN,
    output logic        o_ASEL,
    output logic        o_BSEL
);
    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst || i_flush) begin
            o_PC         <= 32'b0;
            o_INST       <= 32'b0;
            o_RS1        <= 32'b0;
            o_RS2        <= 32'b0;
            o_IMM        <= 32'b0;
            o_ALU_SEL    <= 4'b0;
            o_BRU        <= 1'b0;
            o_MEMRW      <= 1'b0;
            o_LOAD_TYPE  <= 3'b0;
            o_STORE_TYPE <= 2'b0;
            o_WB_SEL     <= 2'b0;
            o_REGWEN     <= 1'b0;
            o_ASEL       <= 1'b0;
            o_BSEL       <= 1'b0;
        end 
        
        else if (!i_stall) begin
            o_PC         <= i_PC;
            o_INST       <= i_INST;
            o_RS1        <= i_RS1;
            o_RS2        <= i_RS2;
            o_IMM        <= i_IMM;
            o_ALU_SEL    <= i_ALU_SEL;
            o_BRU        <= i_BRU;
            o_MEMRW      <= i_MEMRW;
            o_LOAD_TYPE  <= i_LOAD_TYPE;
            o_STORE_TYPE <= i_STORE_TYPE;
            o_WB_SEL     <= i_WB_SEL;
            o_REGWEN     <= i_REGWEN;
            o_ASEL       <= i_ASEL;
            o_BSEL       <= i_BSEL;
        end
    end
endmodule
