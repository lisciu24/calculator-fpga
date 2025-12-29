`timescale 1ns/1ps

import key_codes_pkg::*;

module tb;
  
  localparam NB = 32;
  localparam NB_FRAC = 0;
  localparam COL_COUNT = 64;
  localparam PAGE_COUNT = 1;
`timescale 1ns/1ps

import key_codes_pkg::*;

module tb;
  
  localparam NB = 32;
  localparam NB_FRAC = 0;
  localparam COL_COUNT = 128;
  localparam PAGE_COUNT = 2;
  localparam FRAC_DIGITS = 2;
  
  logic clk, rst;
  logic [3:0] rows, cols;
  logic dc, vdd, vbat, res;
  logic spi_clk, spi_mosi;
  
  top #(
    .NB(NB), .NB_FRAC(NB_FRAC),
    .COL_COUNT(COL_COUNT), .PAGE_COUNT(PAGE_COUNT),
    .FRAC_DIGITS(FRAC_DIGITS)
  ) u_top (
    .i_CLK(clk),
    .i_RST(rst),
    .i_ROWS(rows),
    .o_COLS(cols),
    .o_DC(dc),
    .o_VDD(vdd),
    .o_VBAT(vbat),
    .o_RES(res),
    .o_SPI_CLK(spi_clk),
    .o_SPI_MOSI(spi_mosi)
  );
  
  logic [3:0] key_to_press = 4'hF;
  logic       is_pressed   = 0;
  logic [1:0] target_col;
  logic [1:0] target_row;

  always_comb begin
    case (key_to_press)
      4'h1: {target_col, target_row} = {2'd0, 2'd0}; // Col 0, Row 0
      4'h4: {target_col, target_row} = {2'd0, 2'd1}; // Col 0, Row 1
      4'h7: {target_col, target_row} = {2'd0, 2'd2}; // ...
      4'h0: {target_col, target_row} = {2'd0, 2'd3};
      4'h2: {target_col, target_row} = {2'd1, 2'd0};
      4'h5: {target_col, target_row} = {2'd1, 2'd1};
      4'h8: {target_col, target_row} = {2'd1, 2'd2};
      4'hF: {target_col, target_row} = {2'd1, 2'd3};
      4'h3: {target_col, target_row} = {2'd2, 2'd0};
      4'h6: {target_col, target_row} = {2'd2, 2'd1};
      4'h9: {target_col, target_row} = {2'd2, 2'd2};
      4'hE: {target_col, target_row} = {2'd2, 2'd3};
      4'hA: {target_col, target_row} = {2'd3, 2'd0};
      4'hB: {target_col, target_row} = {2'd3, 2'd1};
      4'hC: {target_col, target_row} = {2'd3, 2'd2};
      4'hD: {target_col, target_row} = {2'd3, 2'd3};
      default: {target_col, target_row} = {2'd0, 2'd0};
    endcase
  end

  always_comb begin
    rows = 4'b1111;
    if (is_pressed) begin
      if (cols[target_col] == 1'b0) begin
        rows[target_row] = 1'b0;
      end
    end
  end

  task press_key(input [3:0] key);
    begin
      key_to_press = key;
      is_pressed = 1;
      repeat(5) @(posedge u_top.u_key_decoder.r_timer_fin);
      is_pressed = 0;
      wait(u_top.key_valid == 1'b1);      
      #100;
    end
  endtask
  
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  initial begin 
//     $dumpfile("dump.vcd"); 
//     $dumpvars(1, u_top);
    
//     $dumpfile("spi.vcd");
//     $dumpvars(1, spi_clk, spi_mosi);
    
//     $dumpfile("exec.vcd");
//     $dumpvars(0, u_top.u_execution_unit);
    
    $dumpfile("mem.vcd");
    $dumpvars(1, u_top.mem_data_in, u_top.mem_data_out);
  end

  initial begin
	rst = 1;    
    #20 rst = 0;
    wait(u_top.oled_ready);
    
    #2000 press_key(KEY_6);
    #2000 wait(u_top.oled_fin);
    
    #2000 press_key(KEY_COMMA);
    #2000 wait(u_top.oled_fin);
    
    #2000 press_key(KEY_9);
    #2000 wait(u_top.oled_fin);
    
    #2000 press_key(KEY_DIV);
    #2000 wait(u_top.oled_fin);
    
    #2000 press_key(KEY_3);
    #2000 wait(u_top.oled_fin);
    
    #2000 press_key(KEY_EQUAL);
    #2000 wait(u_top.oled_fin);
    
    #20000
    $finish; 
  end

endmodule