module hazard_detection_load (
  input  logic [31:0] inst_ID_i,
  input  logic [31:0] inst_EX_i,

  output logic        ID_EX_flush,
  output logic        pc_en,
  output logic        IF_ID_en
);

  // Basic field decode
  logic [4:0] rs1_ID, rs2_ID, rd_EX;
  logic [6:0] opcode_ID, opcode_EX;
  logic       is_load_EX;
  logic       uses_rs1_ID, uses_rs2_ID;

  assign opcode_ID = inst_ID_i[6:0];
  assign opcode_EX = inst_EX_i[6:0];

  assign rs1_ID = inst_ID_i[19:15];
  assign rs2_ID = inst_ID_i[24:20];
  assign rd_EX  = inst_EX_i[11:7];

  // Detect standard RISC-V load opcode 0000011 in EX
  assign is_load_EX = (opcode_EX == 7'b0000011);

  // Roughly detect whether the ID instruction reads rs1/rs2 to avoid over-stalling
  assign uses_rs1_ID = ~((opcode_ID == 7'b0110111) || // LUI
                         (opcode_ID == 7'b0010111) || // AUIPC (uses PC)
                         (opcode_ID == 7'b1101111));  // JAL (no rs1)

  assign uses_rs2_ID = (opcode_ID == 7'b0110011) || // R-type
                       (opcode_ID == 7'b0100011) || // STORE
                       (opcode_ID == 7'b1100011);   // BRANCH

  always_comb begin
    ID_EX_flush = 1'b0;
    IF_ID_en    = 1'b1;
    pc_en       = 1'b1;

    // Load-use hazard: stall IF/ID and inject bubble into ID/EX
    if (is_load_EX && (rd_EX != 5'd0) &&
        ((uses_rs1_ID && (rd_EX == rs1_ID)) ||
         (uses_rs2_ID && (rd_EX == rs2_ID)))) begin
      ID_EX_flush = 1'b1;
      IF_ID_en    = 1'b0;
      pc_en       = 1'b0;
    end
  end

endmodule
