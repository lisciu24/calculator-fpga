module oled_renderer #(
  parameter PAGE_COUNT = 4, 
  parameter COL_COUNT = 128,
  parameter NADDR = $clog2(PAGE_COUNT * COL_COUNT)
) (
  input i_CLK,
  input i_RST,
  
  // input interface
  input [7:0] i_ASCII_CHAR,
  input i_VALID,
  input [$clog2(COL_COUNT)-1:0] i_CURSOR,
  input [$clog2(PAGE_COUNT)-1:0] i_PAGE,
  input i_SET_POS,

  // output interface 
  output o_READY,
  output o_FIN,

  // oled ram
  output o_RAM_WE,
  output reg [NADDR-1:0] o_RAM_ADDR,
  output reg [7:0] o_RAM_DATA
);

  reg [7:0] r_char_rom [0:1023];
  reg [9:0] r_rom_addr;
  reg [8:0] r_ram_addr;
  reg [2:0] r_cnt;
  reg r_busy;

  initial begin 
      $readmemh("char_lib.mem", r_char_rom);
  end

  // busy
  always_ff @(posedge i_CLK) begin
    if(i_RST) begin
      r_busy <= 0;
    end else if (i_VALID & ~r_busy) begin
      r_busy <= 1;
    end else if (r_busy && r_cnt == 3'h7) begin
      r_busy <= 0;
    end
  end 

  // latch input
  always_ff @(posedge i_CLK) begin
    if(i_VALID & ~r_busy) begin
      r_rom_addr <= { 2'b0, i_ASCII_CHAR } << 3;
    end
  end

  // ram addr
  always_ff @(posedge i_CLK) begin
    if(i_RST) begin
      r_ram_addr <= 0;
    end else if(i_SET_POS & ~r_busy) begin
      r_ram_addr <= { i_PAGE, 7'b0 } + i_CURSOR;
    end else if (r_busy && r_cnt == 3'h7) begin
      r_ram_addr <= r_ram_addr + 9'h8;
    end 
  end

  // counter
  always_ff @(posedge i_CLK) begin
    if(i_RST) begin
      r_cnt <= 0;
    end else if(r_busy) begin
      r_cnt <= r_cnt + 1;
    end
  end

  assign o_READY = ~r_busy;
  assign o_FIN = (r_cnt == 3'h7);
  assign o_RAM_WE = r_busy;
  assign o_RAM_ADDR = r_ram_addr + r_cnt;
  assign o_RAM_DATA = r_char_rom[r_rom_addr + r_cnt];

endmodule