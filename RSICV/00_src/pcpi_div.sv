module pcpi_div (
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

    logic instr_div, instr_divu, instr_rem, instr_remu;
    logic active;
    logic ignore_req;

    logic        div_start;
    logic [31:0] div_rs1, div_rs2;
    logic        div_signed;
    logic        div_do_div;
    logic [31:0] div_result;
    logic        div_done;

    wire instr_any_div;
    wire req_any_div;

    assign instr_div     = pcpi_valid && (pcpi_insn[6:0] == 7'b0110011) && (pcpi_insn[31:25] == 7'b0000001) && (pcpi_insn[14:12] == 3'b100);
    assign instr_divu    = pcpi_valid && (pcpi_insn[6:0] == 7'b0110011) && (pcpi_insn[31:25] == 7'b0000001) && (pcpi_insn[14:12] == 3'b101);
    assign instr_rem     = pcpi_valid && (pcpi_insn[6:0] == 7'b0110011) && (pcpi_insn[31:25] == 7'b0000001) && (pcpi_insn[14:12] == 3'b110);
    assign instr_remu    = pcpi_valid && (pcpi_insn[6:0] == 7'b0110011) && (pcpi_insn[31:25] == 7'b0000001) && (pcpi_insn[14:12] == 3'b111);
    assign instr_any_div = instr_div || instr_divu || instr_rem || instr_remu;
    assign req_any_div   = instr_any_div && !ignore_req;

    // Assert wait while the DIV/REM instruction is being serviced.
    always_comb begin
        pcpi_wait = active || req_any_div;
    end

    divider_32bit div_core (
        .clk       (clk),
        .resetn    (resetn),
        .start     (div_start),
        .rs1       (div_rs1),
        .rs2       (div_rs2),
        .is_signed (div_signed),
        .do_div    (div_do_div),
        .busy      (),
        .done      (div_done),
        .result    (div_result)
    );

    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            active      <= 1'b0;
            ignore_req  <= 1'b0;
            div_start   <= 1'b0;
            div_rs1     <= 32'b0;
            div_rs2     <= 32'b0;
            div_signed  <= 1'b0;
            div_do_div  <= 1'b0;
            pcpi_wr     <= 1'b0;
            pcpi_ready  <= 1'b0;
            pcpi_rd     <= 32'b0;
        end else begin
            div_start  <= 1'b0;
            pcpi_wr    <= 1'b0;
            pcpi_ready <= 1'b0;

            // Allow a new request once the EX-stage instruction changes.
            if (ignore_req && !instr_any_div)
                ignore_req <= 1'b0;

            if (!active && req_any_div) begin
                active     <= 1'b1;
                div_start  <= 1'b1;
                div_rs1    <= pcpi_rs1;
                div_rs2    <= pcpi_rs2;
                div_signed <= instr_div || instr_rem;
                div_do_div <= instr_div || instr_divu;
            end else if (active && div_done) begin
                active     <= 1'b0;
                ignore_req <= 1'b1;
                pcpi_wr    <= 1'b1;
                pcpi_ready <= 1'b1;
                pcpi_rd    <= div_result;
            end
        end
    end

endmodule
