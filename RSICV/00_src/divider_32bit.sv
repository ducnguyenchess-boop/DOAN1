module divider_32bit (
    input  logic        clk,
    input  logic        resetn,
    input  logic        start,
    input  logic [31:0] rs1,
    input  logic [31:0] rs2,
    input  logic        is_signed,
    input  logic        do_div,
    output logic        busy,
    output logic        done,
    output logic [31:0] result
);

    logic [31:0] dividend;
    logic [62:0] divisor;
    logic [31:0] quotient;
    logic [31:0] quotient_msk;
    logic        outsign;

    logic [31:0] rs1_abs;
    logic [31:0] rs2_abs;

    assign rs1_abs = (is_signed && rs1[31]) ? -rs1 : rs1;
    assign rs2_abs = (is_signed && rs2[31]) ? -rs2 : rs2;

    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            busy         <= 1'b0;
            done         <= 1'b0;
            result       <= 32'b0;
            dividend     <= 32'b0;
            divisor      <= 63'b0;
            quotient     <= 32'b0;
            quotient_msk <= 32'b0;
            outsign      <= 1'b0;
        end else begin
            done <= 1'b0;

            if (start && !busy) begin
                busy         <= 1'b1;
                dividend     <= rs1_abs;
                divisor      <= {31'b0, rs2_abs} << 31;
                outsign      <= is_signed && ((do_div && (rs1[31] != rs2[31]) && |rs2) || (!do_div && rs1[31]));
                quotient     <= 32'b0;
                quotient_msk <= 32'h8000_0000;
            end else if (busy) begin
                if (!quotient_msk) begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    if (do_div)
                        result <= outsign ? -quotient : quotient;
                    else
                        result <= outsign ? -dividend : dividend;
                end else begin
                    if (divisor <= {31'b0, dividend}) begin
                        dividend <= dividend - divisor[31:0];
                        quotient <= quotient | quotient_msk;
                    end
                    divisor <= divisor >> 1;
                    quotient_msk <= quotient_msk >> 1;
                end
            end
        end
    end

endmodule