module stage_12 (
    input  logic        i_clk,
    input  logic        i_rst,
    input  logic        i_stall,
    input  logic        i_flush,
    input  logic [31:0] i_PC,
    input  logic [31:0] i_INST,
    output logic [31:0] o_PC,
    output logic [31:0] o_INST
);
    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst || i_flush) begin
            o_PC   <= 32'b0;
            o_INST <= 32'b0;
        end else if (!i_stall) begin
            o_PC   <= i_PC;
            o_INST <= i_INST;
        end
    end
endmodule
