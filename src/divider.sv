module divider #(
  parameter NB = 32,
  parameter FRAC_DIGITS = 2
) (
  input i_CLK,
  input i_RST,
  input i_VALID,
  input signed [NB-1:0] i_DATA_A,
  input signed [NB-1:0] i_DATA_B,
  output reg [NB-1:0] o_QUOTIENT,
  output reg [NB-1:0] o_REMINDER,
  output o_DIV_BY_ZERO,
  output o_READY,
  output o_FIN 
);

  typedef enum { Idle, Prep, Divide, Done } e_state;
  e_state current_state, next_state;

  reg [$clog2(NB)-1:0] r_cnt;
  reg [$clog2(FRAC_DIGITS):0] r_prep_cnt;
  reg [NB-1:0] r_data_A, r_data_B;
  reg [NB*2-1:0] r_result;

  always_ff @(posedge i_CLK) begin
    if(i_RST) current_state <= Idle;
    else current_state <= next_state;
  end

  always_comb begin
    next_state = current_state;
    case(current_state)
      Idle: if(i_VALID) next_state = Prep;
      Prep: if(r_prep_cnt == FRAC_DIGITS) next_state = Divide;
      Divide: if(r_cnt == NB - 1) next_state = Done;
      Done: next_state = Idle;
    endcase
  end

  assign o_FIN = (current_state == Done);
  assign o_READY = (current_state == Idle);
  assign o_QUOTIENT = r_result[NB-1:0];
  assign o_REMINDER = r_result[2*NB-1:NB];

  always_ff @(posedge i_CLK) begin
    if(current_state == Idle && i_VALID) begin
      r_data_A <= i_DATA_A;
      r_data_B <= i_DATA_B;
      r_prep_cnt <= 0;
      r_cnt <= 0;
    end else if(current_state == Prep) begin
      r_prep_cnt <= r_prep_cnt + 1;
      r_data_A <= (r_data_A << 3) + (r_data_A << 1);
      r_result <= r_data_A;
    end else if(current_state == Divide) begin
      r_cnt <= r_cnt + 1;
      if(r_result[2*NB-2:NB-1] >= r_data_B) begin
        r_result <= { r_result[2*NB-2:NB-1] - r_data_B, r_result[NB-2:0], 1'b1 };
      end else begin
        r_result <= { r_result[2*NB-2:0], 1'b0 };
      end
    end
  end
  
  always_ff @(posedge i_CLK) begin
    if(i_RST || current_state == Idle) begin
    end else if(current_state == Divide) begin
    end
  end

endmodule