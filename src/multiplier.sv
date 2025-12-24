module multiplier #(
  parameter NB = 32,
  parameter NB_FRAC = 8
) (
  input signed [NB-1:0] i_DATA_A,
  input signed [NB-1:0] i_DATA_B,

  output reg [NB-1:0] o_RESULT,
  output reg o_OVFL
);

  reg signed [(2*NB)-1:0] r_full_res;

  always_comb begin
    r_full_res = i_DATA_A * i_DATA_B;
    o_RESULT = r_full_res[NB - 1 + NB_FRAC : NB_FRAC];
    if(i_DATA_A != 0 && i_DATA_B != 0)
      o_OVFL = (r_full_res[(2*NB) - 1 : NB + NB_FRAC] != {(NB - NB_FRAC){r_full_res[NB + NB_FRAC - 1]}});
    else
      o_OVFL = 0; 
  end

endmodule