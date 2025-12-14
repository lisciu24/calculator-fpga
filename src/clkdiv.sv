module clkdiv #(
  parameter DIV=100
) (
  input i_CLK, // input clock
  input i_RST, // reset
  output o_CLK, // output clock divided by div
  output o_EN // output enable, pulse high once a period
);
  
  localparam nb = $clog2(DIV);
  reg [nb-1:0] r_cnt;
  
  always_ff @(posedge i_CLK) begin
    if(i_RST) 
      r_cnt <= 0;
    else if(r_cnt == DIV - 1)
      r_cnt <= 0;
    else 
      r_cnt <= r_cnt + 1;
  end
  
  assign o_CLK = (r_cnt < DIV / 2);
  assign o_EN = (r_cnt == DIV - 1);
endmodule