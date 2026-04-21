module multiplier_32bit #(
	parameter int STEPS_AT_ONCE = 1,
	parameter int CARRY_CHAIN   = 4
) (
	input  logic        clk,
	input  logic        resetn,
	input  logic        start,
	input  logic [31:0] rs1,
	input  logic [31:0] rs2,
	input  logic        rs1_signed,
	input  logic        rs2_signed,
	output logic        busy,
	output logic        done,
	output logic [63:0] result
);

	logic [63:0] rs1_reg, rs2_reg, rd_reg, rdx_reg;
	logic [63:0] next_rs1, next_rs2, this_rs2;
	logic [63:0] next_rd, next_rdx, next_rdt;
	logic [63:0] rs1_ext, rs2_ext;
	logic [6:0]  mul_counter;

	integer i, j;

	assign rs1_ext = rs1_signed ? {{32{rs1[31]}}, rs1} : {32'b0, rs1};
	assign rs2_ext = rs2_signed ? {{32{rs2[31]}}, rs2} : {32'b0, rs2};

	// Carry-save accumulation of partial products.
	always_comb begin
		next_rd  = rd_reg;
		next_rdx = rdx_reg;
		next_rs1 = rs1_reg;
		next_rs2 = rs2_reg;

		for (i = 0; i < STEPS_AT_ONCE; i = i + 1) begin
			this_rs2 = next_rs1[0] ? next_rs2 : 64'b0;

			if (CARRY_CHAIN == 0) begin
				next_rdt = next_rd ^ next_rdx ^ this_rs2;
				next_rdx = ((next_rd & next_rdx) | (next_rd & this_rs2) | (next_rdx & this_rs2)) << 1;
				next_rd  = next_rdt;
			end else begin
				next_rdt = 64'b0;
				for (j = 0; j < 64; j = j + CARRY_CHAIN)
					{next_rdt[j + CARRY_CHAIN - 1], next_rd[j +: CARRY_CHAIN]} =
						next_rd[j +: CARRY_CHAIN] + next_rdx[j +: CARRY_CHAIN] + this_rs2[j +: CARRY_CHAIN];
				next_rdx = next_rdt << 1;
			end

			next_rs1 = next_rs1 >> 1;
			next_rs2 = next_rs2 << 1;
		end
	end

	always_ff @(posedge clk or negedge resetn) begin
		if (!resetn) begin
			rs1_reg     <= 64'b0;
			rs2_reg     <= 64'b0;
			rd_reg      <= 64'b0;
			rdx_reg     <= 64'b0;
			mul_counter <= 7'b0;
			busy        <= 1'b0;
			done        <= 1'b0;
			result      <= 64'b0;
		end else begin
			done <= 1'b0;

			if (start && !busy) begin
				rs1_reg     <= rs1_ext;
				rs2_reg     <= rs2_ext;
				rd_reg      <= 64'b0;
				rdx_reg     <= 64'b0;
				mul_counter <= 7'd63 - STEPS_AT_ONCE;
				busy        <= 1'b1;
			end else if (busy) begin
				rd_reg  <= next_rd;
				rdx_reg <= next_rdx;
				rs1_reg <= next_rs1;
				rs2_reg <= next_rs2;

				mul_counter <= mul_counter - STEPS_AT_ONCE;

				if (mul_counter[6]) begin
					// Resolve final carry-save pair to full 64-bit product.
					result <= next_rd + next_rdx;
					busy   <= 1'b0;
					done   <= 1'b1;
				end
			end
		end
	end

endmodule
