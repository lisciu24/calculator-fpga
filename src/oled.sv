`include "timer.sv"
`include "spi_mosi.sv"
`include "memory.sv"

module oled #(
  parameter PAGE_COUNT = 4,
  parameter COL_COUNT = 128,
  parameter NADDR = $clog2(PAGE_COUNT * COL_COUNT)
) (
  input i_CLK,
  input i_RST,
  
  // control signals
  input i_INIT,
  input i_VALID,
  output o_READY,

  // memory signals
  input [7:0] i_MEM_DATA,
  output reg [NADDR-1:0] o_MEM_ADDR,

  // oled signals
  output o_DC,
  output o_VDD,
  output o_VBAT,
  output o_RES,
  
  // spi signals
  output o_SPI_CLK,
  output o_SPI_MOSI
);

  localparam CMD_COUNT = 25;
  localparam NCMD = $clog2(CMD_COUNT);

  // 2 bit cmd type and 8 bit command
  // 00 - spi, 01 - power, 10 - delay
  localparam reg [9:0] CMD_INIT_SEQ [0:CMD_COUNT-1] = '{ 
    10'h180, // DC = 0
    10'h140, // VDD = 0 
    10'h201, // delay 1ms
    10'h0AE, // SPI display off
    10'h110, // RES = 0
    10'h201, // delay 1ms
    10'h11F, // RES = 1
    10'h08D, // SPI set charge pump >
    10'h014, // SPI enable
    10'h0D9, // SPI set charge pump period > 
    10'h0F1, // SPI phase 1 - 15 DCLK, phase 2 - 1 DCLK
    10'h120, // VBAT = 0
    10'h264, // delay 100ms
    10'h081, // SPI set contrast >
    10'h00F, // SPI 15 / 255
    10'h0A1, // SPI set segment remap, column address 127 is mapped to SEG0
    10'h0C8, // SPI set COM output scan direction, remapped mode
    10'h0DA, // SPI set COM pins hardware configuration >
    10'h022, // SPI sequential COM pin configuration, enable COM left/right remap
    10'h020, // SPI set memory addressing mode >
    10'h000, // SPI horizontal addressing mode
    10'h022, // SPI set page address >
    10'h000, // SPI start page address 00 >
    10'h00 + PAGE_COUNT - 1, // SPI end page address
    10'h0AF  // SPI display on
  };
  
  reg [1:0] r_cmd_type; // 0 -> spi / 1 -> signal
  reg [7:0] r_ccmd;
  reg [NCMD-1:0] r_cmd_cnt;
  
  // power
  reg [3:0] r_power;
  assign o_DC = r_power[3];
  assign o_VDD = r_power[2];
  assign o_VBAT = r_power[1];
  assign o_RES = r_power[0];
  
  // spi
  reg r_spi_valid, r_spi_ready, r_spi_fin;
  
  spi_mosi spi(.i_CLK, 
               .i_RST, 
               .i_TX_DATA(r_ccmd), 
               .i_TX_VALID(r_spi_valid), 
               .o_TX_READY(r_spi_ready),
               .o_SPI_CLK, 
               .o_SPI_MOSI,
               .o_SPI_FIN(r_spi_fin));
  
  // timer
  reg r_timer_valid, r_timer_ready, r_timer_fin;
  
  timer delay(.i_CLK, 
              .i_RST, 
              .i_TIMER_MS(r_ccmd), 
              .i_VALID(r_timer_valid), 
              .o_READY(r_timer_ready),
              .o_FIN(r_timer_fin));
  
  typedef enum {
    WaitInit, // waits for i_INIT to go high
    WaitValid,// waits for i_VALID to go high
    Decision, // decodes cmd
    Spi, 	    // 00 - sends spi data
    Power, 	  // 01 - change oled signal
    Delay,    // 10 - delays 
    Write,    // writes data to oled
    Check, 	  // check if initialization is finished
    NextInit  // advances to next init cmd
  } e_state;
  
  e_state current_state;
  e_state next_state;
  
  wire w_init_fin;
  wire w_write_fin;

  reg [NADDR:0] r_mem_addr;
  
  // update current state
  always_ff @(posedge i_CLK) begin
    if(i_RST) current_state <= WaitInit;
    else 	  current_state <= next_state;
  end
  
  // next state logic
  always_comb begin
    next_state = current_state;
    case(current_state)
      WaitInit: if(i_INIT) next_state = Decision;
      WaitValid: if(i_VALID) next_state = Write;
      Decision: begin
        if(r_cmd_type == 2'b00) 
          next_state = Spi;
        else if(r_cmd_type == 2'b10)
          next_state = Delay;
        else if(r_cmd_type == 2'b01)
          next_state = Power;
      end
      Spi: if(r_spi_fin) next_state = Check;
      Delay: if(r_timer_fin) next_state = Check;
      Power: next_state = Check;
      Check: begin
        if(w_init_fin) 
          next_state = w_write_fin ? WaitValid : Write;
        else
          next_state = NextInit;
      end
      NextInit: next_state = Decision;
      Write: next_state = Spi;
      default: next_state = WaitInit;
    endcase
  end
  
  // init fin 
  assign w_init_fin = (r_cmd_cnt == CMD_COUNT - 1);
  assign w_write_fin = (r_mem_addr == (PAGE_COUNT * COL_COUNT));
  assign o_READY = (current_state == WaitValid);   
  assign o_MEM_ADDR = r_mem_addr[NADDR-1:0]; 

  // cmd 
  always_ff @(posedge i_CLK) begin
    if(i_RST) begin
      r_ccmd <= 0;
      r_cmd_type <= 0;
      r_cmd_cnt <= 0;
    end else if(current_state == NextInit) begin
      r_cmd_type <= CMD_INIT_SEQ[r_cmd_cnt + 1][9:8];
      r_ccmd <= CMD_INIT_SEQ[r_cmd_cnt + 1][7:0];
      r_cmd_cnt <= r_cmd_cnt + 1;
    end else if(current_state == Write) begin
      r_ccmd <= i_MEM_DATA;
    end
  end
  
  // spi
  always_ff @(posedge i_CLK) begin
    if(i_RST) begin
      r_spi_valid <= 0;
    end else if(current_state == Spi) begin
      if(r_spi_ready) r_spi_valid <= 1;
      else r_spi_valid <= 0;
    end
  end
  
  // delay
  always_ff @(posedge i_CLK) begin
    if(i_RST) begin
      r_timer_valid <= 0;
    end else if(current_state == Delay) begin
      if(r_timer_ready) r_timer_valid <= 1;
      else r_timer_valid <= 0;
    end
  end
  
  // power 
  always_ff @(posedge i_CLK) begin
    if(i_RST) begin
      r_power <= 4'b1111;
    end else if(current_state == Power) begin
      r_power <= (r_ccmd[7:4] & r_ccmd[3:0]) | (~r_ccmd[7:4] & r_power);
    end
  end

  // write
  always_ff @(posedge i_CLK) begin
    if(i_RST) begin
      r_mem_addr <= (PAGE_COUNT * COL_COUNT);
    end else if(current_state == WaitValid) begin
      r_mem_addr <= 0;
    end else if (current_state == Write) begin
      r_mem_addr <= r_mem_addr + 1;
    end
  end 
  
endmodule