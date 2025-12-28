module bin_to_bcd #(
  parameter NB = 32,
  parameter DIGITS = (NB * 10 / 33) + 1
) (
  input i_CLK,
  input i_RST,
  input [NB-1:0] i_BIN,
  input i_VALID,
  output o_READY,
  output o_FIN,
  output [DIGITS*4-1:0] o_BCD,
  output [$clog2(DIGITS)-1:0] o_NDIGITS
);

  typedef enum {Idle, Check, Shift, Count, Done} e_state; 
  e_state current_state, next_state;

  reg [DIGITS*4 + NB-1:0] r_shift;
  reg [$clog2(DIGITS)-1:0] r_digit_cnt;
  reg [$clog2(NB):0] r_cnt;
  wire w_count_fin;

  always_ff @(posedge i_CLK) begin
    if(i_RST) current_state <= Idle;
    else current_state <= next_state;
  end

  always_comb begin
    next_state = current_state;
    case (current_state)
      Idle: if(i_VALID) next_state = Check;
      Check: next_state = Shift; 
      Shift: next_state = (r_cnt == NB - 1) ? Count : Check;
      Count: if(w_count_fin) next_state = Done;
      Done: next_state = Idle;
      default: next_state = Idle;
    endcase
  end

  assign o_READY = (current_state == Idle); 
  assign o_FIN = (current_state == Done);
  assign o_BCD = r_shift[DIGITS*4 + NB - 1 : NB];
  assign o_NDIGITS = r_digit_cnt + 1;
  assign w_count_fin = (r_shift[r_digit_cnt * 4 + NB +: 4] != 0) || (r_digit_cnt == 0);

  always_ff @(posedge i_CLK) begin
    if(current_state == Idle && i_VALID) begin
      r_shift <= { {(DIGITS*4){1'b0}}, i_BIN };
      r_cnt <= 0;
    end else if(current_state == Check) begin 
      for(int i = 0; i < DIGITS; i++) begin
        if(r_shift[NB + i*4 +: 4] >= 5)
          r_shift[NB + i*4 +: 4] <= r_shift[NB + i*4 +: 4] + 3; 
      end 
    end else if(current_state == Shift) begin
      r_shift <= r_shift << 1;
      r_cnt <= r_cnt + 1;
    end
  end

  always_ff @(posedge i_CLK) begin
    if(current_state == Idle) begin
      r_digit_cnt <= DIGITS - 1;
    end else if(current_state == Count) begin
      if(~w_count_fin) r_digit_cnt <= r_digit_cnt - 1; 
    end
  end
    
endmodule