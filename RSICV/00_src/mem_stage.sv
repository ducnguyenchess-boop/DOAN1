module mem_stage (
  input  logic        i_clk,
  input  logic        i_rst,
  input  logic [31:0] i_addr,
  input  logic [31:0] i_RS2,
  input  logic        i_MEMRW,
  input  logic [2:0]  i_LOAD_TYPE,
  input  logic [1:0]  i_STORE_TYPE,
  input  logic [31:0] i_io_sw,
  input  logic [31:0] i_io_keys,
  input  logic [31:0] i_PC,

  output logic [31:0] o_ld_data,
  output logic [31:0] o_io_ledr,
  output logic [31:0] o_io_lcd,
  output logic [31:0] o_io_ledg,
  output logic [6:0]  o_io_hex0, o_io_hex1, o_io_hex2, o_io_hex3,
  output logic [6:0]  o_io_hex4, o_io_hex5, o_io_hex6, o_io_hex7
);

  logic [1:0] lsu_size;
  logic       lsu_unsigned;

  always_comb begin
    if (i_MEMRW) begin
      // 00=byte
      // 01=half
      // 10=word
      unique case (i_STORE_TYPE)
        2'b00: lsu_size = 2'b00;
        2'b01: lsu_size = 2'b01;
        default: lsu_size = 2'b10; 
      endcase
      lsu_unsigned = 1'b0;
    end else begin
      unique case (i_LOAD_TYPE)
        3'b000: begin lsu_size = 2'b00; lsu_unsigned = 1'b0; end //LB
        3'b001: begin lsu_size = 2'b01; lsu_unsigned = 1'b0; end //LH
        3'b010: begin lsu_size = 2'b10; lsu_unsigned = 1'b0; end //lW
        3'b100: begin lsu_size = 2'b00; lsu_unsigned = 1'b1; end //LBU
        3'b101: begin lsu_size = 2'b01; lsu_unsigned = 1'b1; end //LHU
        default:begin lsu_size = 2'b10; lsu_unsigned = 1'b0; end // LW
      endcase
    end
  end

  lsu lsu_module (
    .i_clk         (i_clk),
    .i_reset       (i_rst),
    .i_lsu_addr    (i_addr),
    .i_st_data     (i_RS2),
    .i_lsu_wren    (i_MEMRW),
    .i_lsu_size    (lsu_size),
    .i_lsu_unsigned(lsu_unsigned),
    .i_io_sw       (i_io_sw),
    .o_ld_data     (o_ld_data),
    .o_io_ledr     (o_io_ledr),
    .o_io_ledg     (o_io_ledg),
    .o_io_lcd      (o_io_lcd),
    .o_io_hex0     (o_io_hex0),
    .o_io_hex1     (o_io_hex1),
    .o_io_hex2     (o_io_hex2),
    .o_io_hex3     (o_io_hex3),
    .o_io_hex4     (o_io_hex4),
    .o_io_hex5     (o_io_hex5),
    .o_io_hex6     (o_io_hex6),
    .o_io_hex7     (o_io_hex7)
  );
endmodule
