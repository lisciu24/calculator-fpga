module spi_mosi #(
  parameter CLK_Hz = 100_000_000,
  parameter SPI_CLK_Hz = 10_000_000,
  parameter SPI_MODE = 2'b00,
  parameter DATA_BS = 8
) (
  // control
  input 		i_CLK, // fpga clock
  input 		i_RST, // fpga reset
  output 		o_SPI_FIN,
  
  // TX (MOSI)
  input [DATA_BS-1:0] i_TX_DATA,
  input 		    i_TX_VALID,
  output 		    o_TX_READY,
  
  // SPI interface
  output reg 	o_SPI_CLK,
  output reg	o_SPI_MOSI
);
 
  typedef enum {Idle, Send, Done} e_state;
  
  localparam CLK_DIV = CLK_Hz / (2 * SPI_CLK_Hz);
  localparam NCLK = $clog2(CLK_DIV);
  localparam NDATA = $clog2(DATA_BS);
  
  wire w_CPOL, w_CPHA;
  assign w_CPOL = SPI_MODE[1];
  assign w_CPHA = SPI_MODE[0];
  
  reg [NCLK-1:0] r_clk_cnt;
  reg [NDATA:0] r_edge_cnt;
  wire w_clk_tick;
  assign w_clk_tick = r_clk_cnt == (CLK_DIV - 1);
  reg r_leading_edge, r_trailing_edge;
  
  e_state current_state;
  e_state next_state;
  reg [DATA_BS-1:0] r_tx_data;
  reg [NDATA:0] r_tx_cnt;
  
  // update current state
  always_ff @(posedge i_CLK) begin
    if(i_RST) current_state <= Idle;
    else 	  current_state <= next_state;
  end
  
  // next state logic
  always_comb begin
    next_state = current_state;
    case(current_state)
      Idle: 	if(i_TX_VALID) next_state = Send;
      Send: 	if(r_edge_cnt == (2 * DATA_BS - 1) && w_clk_tick) next_state = Done;
      Done:     next_state = Idle;
      default: next_state = Idle;
    endcase
  end
  
  // output logic
  assign o_SPI_FIN = (current_state == Done);
  assign o_TX_READY = (current_state == Idle);

  // MOSI
  always_ff @(posedge i_CLK) begin
    if(i_RST || current_state == Done) begin
      o_SPI_MOSI <= 0;
      r_tx_cnt <= 0;
    end else if (current_state == Idle && i_TX_VALID && ~w_CPHA) begin 
      o_SPI_MOSI <= i_TX_DATA[DATA_BS - 1];
      r_tx_cnt <= r_tx_cnt + 1;
    end else if((w_CPHA & r_leading_edge) | (~w_CPHA & r_trailing_edge)) begin
       r_tx_cnt <= r_tx_cnt + 1;
      if(r_tx_cnt < DATA_BS)
        o_SPI_MOSI <= r_tx_data[DATA_BS - 1 - r_tx_cnt];
      else 
        o_SPI_MOSI <= 0;
    end
  end
  
  // lock input
  always_ff @(posedge i_CLK) begin
    if(current_state == Idle && i_TX_VALID)
      r_tx_data <= i_TX_DATA;
  end
  
  // gen spi clk edges
  always_ff @(posedge i_CLK) begin
    if(i_RST || current_state == Done) begin
      r_leading_edge <= 0;
      r_trailing_edge <= 0;
    end else if(current_state == Send) begin
      if(r_clk_cnt == CLK_DIV - 2) begin
        r_leading_edge <= (w_CPOL & o_SPI_CLK) | (~w_CPOL & ~o_SPI_CLK);
        r_trailing_edge <= (w_CPOL & ~o_SPI_CLK) | (~w_CPOL & o_SPI_CLK);
      end else begin
        r_leading_edge <= 0;
        r_trailing_edge <= 0;
      end
    end
  end
  
  // gen spi clk
  always_ff @(posedge i_CLK) begin
    if(i_RST || current_state == Done) begin
      r_clk_cnt <= 0;
      r_edge_cnt <= 0;
      o_SPI_CLK <= w_CPOL;
      
    end else if(current_state == Send) begin
      if(w_clk_tick) begin 
        r_clk_cnt <= 0;
        r_edge_cnt <= r_edge_cnt + 1;
        o_SPI_CLK <= ~o_SPI_CLK;
      end else begin 
        r_clk_cnt <= r_clk_cnt + 1;
      end
    end
  end
endmodule