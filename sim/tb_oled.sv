`timescale 1ns/1ps

module tb;
  
  logic clk, rst;
  logic init, valid, ready;
  logic [8:0] mem_addr;
  logic [7:0] mem_in;
  logic [7:0] mem_out;
  logic dc, vdd, vbat, res;
  logic spi_clk, spi_mosi;
  logic clear, mem_write;
  
  
  oled disp (
    .i_CLK(clk), 
    .i_RST(rst), 
    .i_INIT(init), 
    .i_VALID(valid),
    .o_READY(ready),
    .i_MEM_DATA(mem_out),
    .o_MEM_ADDR(mem_addr),
    .o_DC(dc), 
    .o_VDD(vdd), 
    .o_VBAT(vbat), 
    .o_RES(res),
    .o_SPI_CLK(spi_clk), 
    .o_SPI_MOSI(spi_mosi)
  );
  
  memory ram (
    .i_CLK(clk),
    .i_RST(rst),
    .i_CLEAR(clear),
    .i_WE(mem_write),
    .i_ADDR(mem_addr),
    .i_DATA(mem_in),
    .o_DATA(mem_out)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    $dumpfile("dump.vcd"); 
    $dumpvars(0, tb); 
    mem_write = 0;
    init = 0;
    valid = 0;
    rst = 1;
    #20;
    rst = 0;
    init = 1;
    #20
    init = 0;
    wait(ready);
    #200
    valid = 1;
    #20
    valid = 0;
    wait(ready);
    #200
    $display("Symulacja zakonczona.");
    $finish; 
  end

endmodule