`timescale 1ns/1ps

module tb;

  logic clk, rst;
  logic init, fin;
  logic dc, vdd, vbat, res;
  logic spi_clk, spi_mosi;
  
  oled_init oi(
    .i_CLK(clk), 
    .i_RST(rst), 
    .i_INIT(init), 
    .o_FIN(fin), 
    .o_DC(dc), 
    .o_VDD(vdd), 
    .o_VBAT(vbat), 
    .o_RES(res),
    .o_SPI_CLK(spi_clk), 
    .o_SPI_MOSI(spi_mosi)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    $dumpfile("dump.vcd"); 
    $dumpvars(0, tb); 
    init = 0;
    rst = 1;
    #20;
    rst = 0;
    init = 1;
    #20
    init = 0;
    wait(fin)
    #200
    $display("Symulacja zakonczona.");
    $finish; 
  end

endmodule