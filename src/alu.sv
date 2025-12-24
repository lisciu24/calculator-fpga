import execution_opcode_pkg::*;

module alu #(
  parameter NB = 32
) (
  input signed [NB-1:0] i_DATA_A,
  input signed [NB-1:0] i_DATA_B,
  input e_opcode        i_OPCODE,

  output [NB-1:0] o_RESULT,
  output o_OVFL
);

  reg signed [NB-1:0] r_res;
  reg r_ovfl;

  always_comb begin
    r_ovfl = 1'b0;
    r_res = 0;
    case (i_OPCODE)
      OP_ADD: begin 
          r_res = i_DATA_A + i_DATA_B; 
          r_ovfl = (i_DATA_A[NB-1] == i_DATA_B[NB-1]) && (r_res[NB-1] != i_DATA_A[NB-1]);
      end
      OP_SUB: begin 
          r_res = i_DATA_A - i_DATA_B; 
          r_ovfl = (i_DATA_A[NB-1] == i_DATA_B[NB-1]) && (r_res[NB-1] != i_DATA_A[NB-1]);
      end
      OP_OR: r_res = i_DATA_A | i_DATA_B;
      OP_AND: r_res = i_DATA_A & i_DATA_B;
      OP_XOR: r_res = i_DATA_A ^ i_DATA_B;
      OP_NOT_A: r_res = ~i_DATA_A;
      OP_NOT_B: r_res = ~i_DATA_B;
      OP_ROR_A: r_res = {{(NB-1){1'b0}}, |i_DATA_A };
      OP_RAND_B: r_res = {{(NB-1){1'b0}}, &i_DATA_B };
      OP_SHL: r_res = i_DATA_A << i_DATA_B[$clog2(NB)-1:0];
      OP_SHR: r_res = i_DATA_A >>> i_DATA_B[$clog2(NB)-1:0];
      default: begin
        r_res = 0;
        r_ovfl = 1'b0;
      end
    endcase
  end

  assign o_RESULT = r_res;
  assign o_OVFL = r_ovfl;

endmodule