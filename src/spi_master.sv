module spi_master #(
  parameter CLK_Hz = 100_000_000,
  parameter SPI_CLK_Hz = 10_000,
  parameter SPI_MODE = 2'b00,
  parameter DATA_BS = 8
) (
  // control
  input 		i_CLK, // fpga clock
  input 		i_RST, // fpga reset
  
  // TX (MOSI)
  input [DATA_BS-1:0] i_TX_DATA,
  input 		    i_TX_VALID,
  output 		    o_TX_READY,
  
  // RX (MISO)
  output reg [DATA_BS-1:0] o_RX_DATA,
  output 				   o_RX_VALID,
  
  // SPI interface
  output reg 	o_SPI_CLK,
  input 		i_SPI_MISO,
  output reg	o_SPI_MOSI,
  output reg	o_SPI_CS
);
 
  typedef enum {Idle, Prepare, Send, Clear, Done} e_state;
  
  localparam CLK_DIV = CLK_Hz / (2 * SPI_CLK_Hz);
  localparam NCLK = $clog2(CLK_DIV);
  localparam NDATA = $clog2(DATA_BS);
  
  wire w_CPOL, w_CPHA;
  assign w_CPOL = SPI_MODE[1];
  assign w_CPHA = SPI_MODE[0];
  reg r_offset;
  
  reg [NCLK-1:0] r_clk_cnt;
  reg [NDATA:0] r_edge_cnt;
  wire w_clk_tick;
  assign w_clk_tick = r_clk_cnt == (CLK_DIV - 1);
  reg r_leading_edge, r_trailing_edge;
  
  e_state current_state;
  e_state next_state;
  reg [DATA_BS-1:0] r_tx_data;
  reg [NDATA:0] r_tx_cnt;
  reg [DATA_BS-1:0] r_rx_data;
  reg [NDATA:0] r_rx_cnt;
  
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
      Send: 	if(r_edge_cnt == (2 * DATA_BS - 1) && w_clk_tick) next_state = Clear;
      Clear: 	if(w_clk_tick) next_state = Done;
      Done:     next_state = Idle;
      default: next_state = Idle;
    endcase
  end
  
  // output logic
  assign o_TX_READY = (current_state == Idle);
  assign o_RX_VALID = (current_state == Done);
  
  always_comb begin
    o_SPI_CS = 1;
    case(current_state)
      Send: o_SPI_CS = 0;
      Clear: o_SPI_CS = 0;
      default: o_SPI_CS = 1;
    endcase
  end
  
  // MOSI
  always_ff @(posedge i_CLK) begin
    if(i_RST || current_state == Done) begin
      o_SPI_MOSI <= 0;
      r_tx_cnt <= 0;
    end else if (next_state == Send && ~w_CPHA && r_tx_cnt == 0) begin 
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
  
  // MISO
  always_ff @(posedge i_CLK) begin
    if(i_RST) begin
      r_rx_cnt <= 0;
      r_rx_data <= 0;
      o_RX_DATA <= 0;
    end else if(next_state == Done) begin
      r_rx_cnt <= 0;
      r_rx_data <= 0;
      o_RX_DATA <= r_rx_data;
    end else if((w_CPHA & r_leading_edge) | (~w_CPHA & r_trailing_edge)) begin
      r_rx_cnt <= r_rx_cnt + 1;
      r_rx_data[DATA_BS - 1 - r_rx_cnt] <= i_SPI_MISO;
    end
  end
  
  // lock input
  always_ff @(posedge i_CLK) begin
    if(current_state == Idle && i_TX_VALID)
      r_tx_data <= i_TX_DATA;
  end
  
  // gen spi clk
  always_ff @(posedge i_CLK) begin
    if(i_RST || current_state == Done) begin
      r_clk_cnt <= 0;
      r_edge_cnt <= 0;
      r_leading_edge <= 0;
      r_trailing_edge <= 0;
      o_SPI_CLK <= w_CPOL;
      
    end else if(current_state == Send) begin
      if(r_clk_cnt == CLK_DIV - 2) begin
        r_leading_edge <= (w_CPOL & o_SPI_CLK) | (~w_CPOL & ~o_SPI_CLK);
        r_trailing_edge <= (w_CPOL & ~o_SPI_CLK) | (~w_CPOL & o_SPI_CLK);
      end else begin
        r_leading_edge <= 0;
        r_trailing_edge <= 0;
      end
      
      if(w_clk_tick) begin 
        r_clk_cnt <= 0;
        r_edge_cnt <= r_edge_cnt + 1;
        o_SPI_CLK <= ~o_SPI_CLK;
      end else begin 
        r_clk_cnt <= r_clk_cnt + 1;
      end
      
    end else if(current_state == Clear) begin      
      if(w_clk_tick) r_clk_cnt <= 0;
      else r_clk_cnt <= r_clk_cnt + 1;
      
    end
  end
endmodule