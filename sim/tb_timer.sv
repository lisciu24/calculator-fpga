`timescale 1ns/1ps

module tb_timer;

  localparam clk_Hz = 100_000;
  localparam nb = 12;

  logic clk;
  logic rst;
  logic valid;
  logic ready;
  logic [nb-1:0] timer_ms;
  logic timer_fin;

  timer #(
    .clk_Hz(clk_Hz), .nb(nb)
  ) dut (
    .i_CLK(clk),
    .i_RST(rst),
    .i_VALID(valid),
    .o_READY(ready),
    .i_TIMER_MS(timer_ms),
    .o_TIMER_FIN(timer_fin)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    $dumpfile("dump.vcd"); 
    $dumpvars(0, tb_timer); 
    timer_ms = 2;
    rst = 1;
    #20;
    rst = 0;
    #10
	valid = 1;
    wait(timer_fin)
    #200
    valid = 0;

    $display("Symulacja zakonczona.");
    $finish; 
  end

endmodule