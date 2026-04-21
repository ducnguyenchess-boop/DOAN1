module pcpi_mul (
    input  logic        clk,
    input  logic        resetn,

    input  logic        pcpi_valid,
    input  logic [31:0] pcpi_insn,
    input  logic [31:0] pcpi_rs1,
    input  logic [31:0] pcpi_rs2,
    output logic        pcpi_wr,
    output logic [31:0] pcpi_rd,
    output logic        pcpi_wait,
    output logic        pcpi_ready
);

    logic instr_mul, instr_mulh, instr_mulhsu, instr_mulhu;
    logic active;
    logic ignore_req;

    logic        mul_start;
    logic [31:0] mul_rs1, mul_rs2;
    logic        mul_rs1_signed, mul_rs2_signed;
    logic [63:0] mul_result;
    logic        mul_busy, mul_done;
    logic        instr_any_mulh_latched;

    assign instr_mul    = pcpi_valid && (pcpi_insn[6:0] == 7'b0110011) && (pcpi_insn[31:25] == 7'b0000001) && (pcpi_insn[14:12] == 3'b000);
    assign instr_mulh   = pcpi_valid && (pcpi_insn[6:0] == 7'b0110011) && (pcpi_insn[31:25] == 7'b0000001) && (pcpi_insn[14:12] == 3'b001);
    assign instr_mulhsu = pcpi_valid && (pcpi_insn[6:0] == 7'b0110011) && (pcpi_insn[31:25] == 7'b0000001) && (pcpi_insn[14:12] == 3'b010);
    assign instr_mulhu  = pcpi_valid && (pcpi_insn[6:0] == 7'b0110011) && (pcpi_insn[31:25] == 7'b0000001) && (pcpi_insn[14:12] == 3'b011);

    wire instr_any_mul = instr_mul || instr_mulh || instr_mulhsu || instr_mulhu;
    wire req_any_mul   = instr_any_mul && !ignore_req;

    // Assert wait while the instruction is being serviced.
    always_comb begin
        pcpi_wait = active || req_any_mul;
    end

    multiplier_32bit mul_core (
        .clk        (clk),
        .resetn     (resetn),
        .start      (mul_start),
        .rs1        (mul_rs1),
        .rs2        (mul_rs2),
        .rs1_signed (mul_rs1_signed),
        .rs2_signed (mul_rs2_signed),
        .busy       (mul_busy),
        .done       (mul_done),
        .result     (mul_result)
    );

    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            active                 <= 1'b0;
            ignore_req             <= 1'b0;
            mul_start              <= 1'b0;
            mul_rs1                <= 32'b0;
            mul_rs2                <= 32'b0;
            mul_rs1_signed         <= 1'b0;
            mul_rs2_signed         <= 1'b0;
            instr_any_mulh_latched <= 1'b0;
            pcpi_wr                <= 1'b0;
            pcpi_ready             <= 1'b0;
            pcpi_rd                <= 32'b0;
        end else begin
            mul_start  <= 1'b0;
            pcpi_wr    <= 1'b0;
            pcpi_ready <= 1'b0;

            // Allow a new request once the EX-stage instruction changes.
            if (ignore_req && !instr_any_mul)
                ignore_req <= 1'b0;

            if (!active && req_any_mul) begin
                active                 <= 1'b1;
                mul_start              <= 1'b1;
                mul_rs1                <= pcpi_rs1;
                mul_rs2                <= pcpi_rs2;
                mul_rs1_signed         <= instr_mulh || instr_mulhsu;
                mul_rs2_signed         <= instr_mulh;
                instr_any_mulh_latched <= instr_mulh || instr_mulhsu || instr_mulhu;
            end else if (active && mul_done) begin
                active     <= 1'b0;
                ignore_req <= 1'b1;
                pcpi_wr    <= 1'b1;
                pcpi_ready <= 1'b1;
                pcpi_rd    <= instr_any_mulh_latched ? mul_result[63:32] : mul_result[31:0];
            end
        end
    end

endmodule