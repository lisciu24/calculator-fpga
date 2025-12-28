import execution_opcode_pkg::*;

module execution_unit #(
  parameter NB = 32,
  parameter NB_FRAC = 8
) (
  input signed [NB-1:0] i_DATA_A,
  input signed [NB-1:0] i_DATA_B,
  input e_opcode        i_OPCODE,

  output reg [NB-1:0] o_RESULT,
  output reg o_OVFL
);

  reg [NB-1:0] r_alu_res;
  reg r_alu_ovfl;

  alu #(.NB(NB)) u_alu (
    .i_DATA_A(i_DATA_A),
    .i_DATA_B(i_DATA_B),
    .i_OPCODE(i_OPCODE),
    .o_RESULT(r_alu_res),
    .o_OVFL(r_alu_ovfl)
  );

  reg [NB-1:0] r_mult_res;
  reg r_mult_ovfl;

  multiplier  #(
    .NB(NB), .NB_FRAC(NB_FRAC)
  ) u_mult (
    .i_DATA_A(i_DATA_A),
    .i_DATA_B(i_DATA_B),
    .o_RESULT(r_mult_res),
    .o_OVFL(r_mult_ovfl)
  );

  always_comb begin
    o_RESULT = 0;
    o_OVFL = 0;
    case(i_OPCODE)
      OP_MULT: begin
        o_RESULT = r_mult_res;
        o_OVFL = r_mult_ovfl;
      end

      OP_DIV, OP_DIV: begin
        o_RESULT = 0;
        o_OVFL = 0;
      end

      default: begin
        o_RESULT = r_alu_res;
        o_OVFL = r_alu_ovfl;
      end
    endcase
  end

endmodule