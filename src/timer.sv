module timer #(
  parameter CLK_Hz = 100_000_000, // input clock speed in Hz
  parameter NB = 8 // max delay is 2**NB - 1 ms
) (
  input i_CLK, // clock
  input i_RST, // reset
  
  // input interface
  input [NB-1:0] i_TIMER_MS, // time in ms
  input   	     i_VALID, // start timer
  output         o_READY, // if timer is ready to start
  
  // output interface
  output o_FIN // high on timer finish
);
  typedef enum {Idle, Hold, Done} e_state;
  
  localparam CLK_DIV = CLK_Hz / 1000;
  localparam NCLK = $clog2(CLK_DIV);
  
  e_state current_state;
  e_state next_state;
  reg [NCLK-1:0] r_clk_cnt;
  reg [NB-1:0]   r_ms_cnt;
  reg [NB-1:0]   r_timer_ms;
  
  // update current state
  always_ff @(posedge i_CLK) begin
    if(i_RST) current_state <= Idle;
    else 	  current_state <= next_state;
  end
  
  // next state logic
  always_comb begin
    next_state = current_state;
    case(current_state)
      Idle: if(i_VALID) next_state = Hold;
      Hold: if(r_ms_cnt == r_timer_ms - 1 && r_clk_cnt == CLK_DIV - 1)  next_state = Done;
      Done: next_state = Idle;
      default: next_state = Idle;
    endcase
  end
    
  // output logic
  assign o_FIN = (current_state == Done);
  assign o_READY = (current_state == Idle);
  
  // lock input
  always_ff @(posedge i_CLK) begin
    if(current_state == Idle && i_VALID)
      r_timer_ms <= i_TIMER_MS;
  end
  
  // counters
  always_ff @(posedge i_CLK) begin
    if(i_RST || current_state == Done) begin
      r_clk_cnt <= 0;
      r_ms_cnt <= 0;
    end else if(current_state == Hold) begin
      if(r_clk_cnt == CLK_DIV - 1) begin
        r_clk_cnt <= 0;
        r_ms_cnt <= r_ms_cnt + 1;
      end else begin
        r_clk_cnt <= r_clk_cnt + 1;
      end
    end
  end
  
endmodule