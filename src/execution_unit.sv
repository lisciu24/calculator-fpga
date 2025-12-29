import execution_opcode_pkg::*;

module execution_unit #(
  parameter NB = 32,
  parameter NB_FRAC = 8,
  parameter FRAC_DIGITS = 2
) (
  input i_CLK,
  input i_RST,
  input i_VALID,

  input signed [NB-1:0] i_DATA_A,
  input signed [NB-1:0] i_DATA_B,
  input e_opcode        i_OPCODE,

  output o_READY,
  output o_FIN,
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
  multiplier #(
    .NB(NB), .NB_FRAC(NB_FRAC)
  ) u_mult (
    .i_DATA_A(i_DATA_A),
    .i_DATA_B(i_DATA_B),
    .o_RESULT(r_mult_res),
    .o_OVFL(r_mult_ovfl)
  );

  reg [NB-1:0] r_div_quotient, r_div_reminder;
  reg r_div_zero, r_div_ready, r_div_fin, r_div_valid;
  divider #(
    .NB(NB), .FRAC_DIGITS(FRAC_DIGITS)
  ) u_divider (
    .i_CLK(i_CLK),
    .i_RST(i_RST),
    .i_VALID(r_div_valid),
    .i_DATA_A(i_DATA_A),
    .i_DATA_B(i_DATA_B),
    .o_QUOTIENT(r_div_quotient),
    .o_REMINDER(r_div_reminder),
    .o_DIV_BY_ZERO(r_div_zero),
    .o_READY(r_div_ready),
    .o_FIN(r_div_fin)
  );

  typedef enum { Idle, Alu, Mult, Div, Done } e_state;
  e_state current_state, next_state;

  always_ff @(posedge i_CLK) begin
    if(i_RST) current_state <= Idle;
    else current_state <= next_state;
  end

  always_comb begin
    next_state = current_state;
    case(current_state)
      Idle: if(i_VALID) begin
        case(i_OPCODE)
          OP_MULT: next_state = Mult;
          OP_DIV, OP_MOD: next_state = Div;
          default next_state = Alu;
        endcase
      end
      Alu: next_state = Done;
      Mult: next_state = Done;
      Div: if(r_div_fin) next_state = Done;
      Done: next_state = Idle;
    endcase
  end

  assign o_FIN = (current_state == Done);
  assign o_READY = (current_state == Idle);

  always_ff @(posedge i_CLK) begin
    if(i_RST) begin
      o_RESULT <= 0;
    end else if(current_state == Alu) begin
      o_RESULT <= r_alu_res;
      o_OVFL <= r_alu_ovfl;
    end else if(current_state == Mult) begin
      o_RESULT <= r_mult_res;
      o_OVFL <= r_mult_ovfl;
    end else if(current_state == Div) begin
      if(r_div_ready) r_div_valid <= 1;
      else r_div_valid <= 0;

      if(r_div_fin) begin
        if(i_OPCODE == OP_DIV) o_RESULT <= r_div_quotient;
        else if(i_OPCODE == OP_MOD) o_RESULT <= r_div_reminder;
        o_OVFL <= r_div_zero;
      end
    end
  end

endmodule