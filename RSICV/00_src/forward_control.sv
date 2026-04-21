module forward_control(
    input logic [31:0] inst_EX_fwd,
    input logic [4:0]  rd_MEM, rd_WB,
    input logic        regWEn_MEM, regWEn_WB,
    output logic [1:0] forwardA_EX, forwardB_EX
);

    logic [4:0] rs1_EX, rs2_EX;
    assign rs1_EX = inst_EX_fwd[19:15];
    assign rs2_EX = inst_EX_fwd[24:20];

    always_comb begin
        forwardA_EX = 2'b00;
        forwardB_EX = 2'b00;

        // Lý thuyết : 00 no forward
        // 01 : Forward từ MEM
        // 10: Forward từ WB
        // Có nghĩa là nếu như tín hiệu tại MEM và WB đều ghi vào thanh ghi và thanh ghi đích của chúng phải đúng là EX
        // thì sẽ ưu tiên lấy tín hiệu từ MEM để dự đoán A B_sel 
        if ((regWEn_MEM && (rd_MEM == rs1_EX)) && (rd_MEM != 0)) forwardA_EX = 2'b10;
        else if ((regWEn_WB && (rd_WB != 0)) && (rd_WB == rs1_EX)) forwardA_EX = 2'b01;

        if ((regWEn_MEM && (rd_MEM == rs2_EX)) && (rd_MEM != 0)) forwardB_EX = 2'b10;
        else if ((regWEn_WB && (rd_WB != 0)) && (rd_WB == rs2_EX)) forwardB_EX = 2'b01;

    end
endmodule
