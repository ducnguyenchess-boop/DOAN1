module regfile (
    input  logic        clk,
    input  logic        reset,
    input  logic        rd_wren,
    input  logic [31:0] rd_data,     // write-back data
    input  logic [4:0]  rs1_addr,        // rs1 address
    input  logic [4:0]  rs2_addr,        // rs2 address
    input  logic [4:0]  rd_addr,        // rd address
    output logic [31:0] data_1,     // rs1 data
    output logic [31:0] data_2      // rs2 data
);

    logic [31:0] reg_mem [0:31];

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < 32; i++)
                reg_mem[i] <= 32'b0;
        end else begin
            if (rd_wren && (rd_addr != 5'd0))
                reg_mem[rd_addr] <= rd_data;
        end
    end

    assign data_1 = (rs1_addr == 5'd0) ? 32'b0 :
                    (rd_wren && (rd_addr == rs1_addr)) ? rd_data : // Internal Forwarding
                    reg_mem[rs1_addr];

    assign data_2 = (rs2_addr == 5'd0) ? 32'b0 :
                    (rd_wren && (rd_addr == rs2_addr)) ? rd_data : // Internal Forwarding
                    reg_mem[rs2_addr];
endmodule