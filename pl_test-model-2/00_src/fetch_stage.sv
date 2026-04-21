module fetch_stage (
    input  logic        i_clk,
    input  logic        i_rst,
    input  logic        i_PC_sel,
    input  logic [31:0] i_PC_target,
    input  logic        i_stall,
    input  logic        i_flush,
    output logic [31:0] o_PC,
    output logic [31:0] o_INST
);

    logic [31:0] pc_q;
    logic [31:0] pc_next;
    logic [31:0] pc_plus4;
    logic [31:0] inst_raw;

    // Next PC selection between sequential and branch/jump target
    Mux2to1 pc_mux (
        .in0(pc_plus4),
        .in1(i_PC_target),
        .sel(i_PC_sel),
        .out(pc_next)
    );

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            pc_q <= 32'd0;
        end else if (!i_stall) begin
            pc_q <= {pc_next[31:2], 2'b00};
        end
    end

    // Increment PC by 4 (RISC-V aligned fetch)
    Add_Sub_32bit pc_add4 (
        .A(pc_q),
        .B(32'd4),
        .Sel(1'b0),
        .Y(pc_plus4),
        .Carry_out(),
        .overflow()
    );

    bram_wrapper IMEM (
        .clk   (i_clk),
        .we    (4'b0000),
        .addr  (pc_q),
        .wdata (32'b0),
        .rdata (inst_raw)
    );

    assign o_PC   = pc_q;
    assign o_INST = (i_flush) ? 32'h00000013 : inst_raw; // inject NOP on flush

endmodule
