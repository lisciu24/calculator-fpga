module key_decoder(
  input i_CLK,
	input i_RST,
  input [3:0] i_ROWS,
  output [3:0] o_COLS,
  output reg [3:0] o_DECODED,
  output o_VALID
);

  reg [7:0] r_timer_ms;
  reg r_timer_valid;
  reg r_timer_ready;
  reg r_timer_fin;
	
  timer delay (
    .i_CLK, 
	  .i_RST,
	  .i_TIMER_MS(r_timer_ms),
    .i_VALID(r_timer_valid), 
    .o_READY(r_timer_ready), 
	  .o_FIN(r_timer_fin) 
  );

  reg [3:0] r_cols;
  reg [3:0] r_input;
  reg [1:0] r_valid;

  always_ff @(posedge i_CLK) begin
    if(i_RST) begin
      r_timer_valid <= 1;
      r_timer_ms <= 1;
    end
  end
  
  always_ff @(posedge i_CLK) begin
    if(i_RST) begin
      r_valid <= 2'b00;
    end else if(r_timer_fin) begin
      r_valid <= { r_valid[0], |r_input };
    end
  end

  always_ff @(posedge i_CLK) begin
    if(i_RST) begin
      r_cols <= 4'b0001;
    end else if(r_timer_fin) begin
      if (r_cols == 4'b1000) r_cols <= 4'b0001;
      else r_cols <= { r_cols[2:0], 1'b0 };
    end
  end

  assign o_COLS = ~r_cols;
  assign o_VALID = r_valid[1] & ~r_valid[0];

  always_ff @(posedge i_CLK) begin
    if(i_RST) begin
      o_DECODED <= 4'b0000;
      r_input <= 4'b0000;
    end else if(r_timer_fin) begin
      if(r_cols == 4'b0001) begin
        r_input[0] <= |(~i_ROWS);
        if(i_ROWS == 4'b1110)
          o_DECODED <= 4'b0001;   //1
        else if(i_ROWS == 4'b1101) 
          o_DECODED <= 4'b0100; 	//4
        else if(i_ROWS == 4'b1011) 
          o_DECODED <= 4'b0111; 	//7
        else if(i_ROWS == 4'b0111) 
          o_DECODED <= 4'b0000; 	//0
      end else if(r_cols == 4'b0010) begin
        r_input[1] <= |(~i_ROWS);
        if(i_ROWS == 4'b1110)
          o_DECODED <= 4'b0010; 	//2
        else if(i_ROWS == 4'b1101) 
          o_DECODED <= 4'b0101; 	//5
        else if(i_ROWS == 4'b1011) 
          o_DECODED <= 4'b1000; 	//8
        else if(i_ROWS == 4'b0111) 
          o_DECODED <= 4'b1111; 	//F
      end else if(r_cols == 4'b0100) begin
        r_input[2] <= |(~i_ROWS);
        if(i_ROWS == 4'b1110)
          o_DECODED <= 4'b0011;		//3	
        else if(i_ROWS == 4'b1101) 
          o_DECODED <= 4'b0110;		//6
        else if(i_ROWS == 4'b1011) 
          o_DECODED <= 4'b1001;		//9
        else if(i_ROWS == 4'b0111) 
          o_DECODED <= 4'b1110;		//E
      end else if(r_cols == 4'b1000) begin
        r_input[3] <= |(~i_ROWS);
        if(i_ROWS == 4'b1110)
          o_DECODED <= 4'b1010;   //A
        else if(i_ROWS == 4'b1101) 
          o_DECODED <= 4'b1011;   //B
        else if(i_ROWS == 4'b1011) 
          o_DECODED <= 4'b1100;   //C
        else if(i_ROWS == 4'b0111) 
          o_DECODED <= 4'b1101;   //D
      end
    end
	end
endmodule