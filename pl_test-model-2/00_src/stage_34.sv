module stage_34 (
    input  logic        i_clk,
    input  logic        i_rst,
    input  logic        i_flush,

    input  logic [31:0] i_PC,
    input  logic [31:0] i_INST,
    input  logic [31:0] i_ALU,
    input  logic [31:0] i_RS2,
    input  logic        i_MEMRW,
    input  logic [2:0]  i_LOAD_TYPE,
    input  logic [1:0]  i_STORE_TYPE,
    input  logic [1:0]  i_WB_SEL,
    input  logic        i_REGWEN,

    output logic [31:0] o_PC,
    output logic [31:0] o_INST,
    output logic [31:0] o_ALU,
    output logic [31:0] o_RS2,
    output logic        o_MEMRW,
    output logic [2:0]  o_LOAD_TYPE,
    output logic [1:0]  o_STORE_TYPE,
    output logic [1:0]  o_WB_SEL,
    output logic        o_REGWEN
);
    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst || i_flush) begin
            o_PC        <= 32'b0;
            o_INST      <= 32'b0;
            o_ALU       <= 32'b0;
            o_RS2       <= 32'b0;
            o_MEMRW     <= 1'b0;
            o_LOAD_TYPE <= 3'b0;
            o_STORE_TYPE<= 2'b0;
            o_WB_SEL    <= 2'b0;
            o_REGWEN    <= 1'b0;
        end else begin
            o_PC        <= i_PC;
            o_INST      <= i_INST;
            o_ALU       <= i_ALU;
            o_RS2       <= i_RS2;
            o_MEMRW     <= i_MEMRW;
            o_LOAD_TYPE <= i_LOAD_TYPE;
            o_STORE_TYPE<= i_STORE_TYPE;
            o_WB_SEL    <= i_WB_SEL;
            o_REGWEN    <= i_REGWEN;
        end
    end
endmodule
