`timescale 1ns/1ps

module tb;

  localparam CLK_Hz = 100_000_000;
  localparam SPI_CLK_Hz = 10_000_000;
  localparam SPI_MODE = 2'b10;
  localparam DATA_BS = 4;

  logic clk;
  logic rst;
  logic [DATA_BS-1:0] tx_data;
  logic tx_valid;
  logic tx_ready;
  logic [DATA_BS-1:0] rx_data;
  logic rx_valid;
  logic spi_clk;
  logic spi_mosi;
  logic spi_cs;
  logic spi_miso;

  spi_master #(
    .CLK_Hz(CLK_Hz), 
    .SPI_CLK_Hz(SPI_CLK_Hz), 
    .SPI_MODE(SPI_MODE),
    .DATA_BS(DATA_BS)
  )
  spi (
    .i_CLK(clk),
    .i_RST(rst),
    .i_TX_DATA(tx_data),
    .i_TX_VALID(tx_valid),
    .o_TX_READY(tx_ready),
    .o_RX_DATA(rx_data),
    .o_RX_VALID(rx_valid),
    .o_SPI_CLK(spi_clk),
    .o_SPI_MOSI(spi_mosi),
    .i_SPI_MISO(spi_miso),
    .o_SPI_CS(spi_cs)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    $dumpfile("dump.vcd"); 
    $dumpvars(0, tb); 
    tx_data = 4'ha;
    rst = 1; #20 rst = 0;
    #10 
    tx_valid = 1;
    spi_miso = 1;
    # 200
    spi_miso = 0;
//     #10 wait(tx_ready)
    #2000
    $display("Symulacja zakonczona.");
    $finish; 
  end

endmodule