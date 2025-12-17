module memory #(
  parameter WORD_SIZE = 8, 			// in bits
  parameter WORD_COUNT = 512 		// how many words
) (
  input i_CLK,
  input i_RST,
  input i_CLEAR,
  input i_WE,
  input [$clog2(WORD_COUNT)-1:0] i_ADDR,
  input [WORD_SIZE-1:0] i_DATA,
  output reg [WORD_SIZE-1:0] o_DATA
);
 
  reg [WORD_SIZE-1:0] r_mem [0:WORD_COUNT-1];
  reg [WORD_COUNT-1:0] r_valid;
  
  // write
  always_ff @(posedge i_CLK) begin
    if(i_RST || i_CLEAR) begin
      r_valid <= 0;
    end else if(i_WE) begin
      r_valid[i_ADDR] <= 1;
      r_mem[i_ADDR] <= i_DATA;
    end
  end
  
  //read
  always_ff @(posedge i_CLK) begin
    o_DATA <= r_valid[i_ADDR] ? r_mem[i_ADDR] : 0;
  end
  
endmodule