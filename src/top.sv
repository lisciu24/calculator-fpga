import execution_opcode_pkg::*;
import key_codes_pkg::*;

module top #(
  parameter NB = 32,
  parameter NB_FRAC = 0,
  parameter FRAC_DIGITS = 2,
  parameter COL_COUNT = 128,
  parameter PAGE_COUNT = 4
) (
  input i_CLK,
  input i_RST,
  input i_CLEAR,
  // key decoder
  input [3:0] i_ROWS,
  output [3:0] o_COLS,
  // oled
  output o_DC,
  output o_VDD,
  output o_VBAT,
  output o_RES,
  // spi 
  output o_SPI_CLK,
  output o_SPI_MOSI
);

  localparam WORD_COUNT = PAGE_COUNT * COL_COUNT;
  localparam DIGITS = (NB * 10 / 33) + 1;

  t_key_code key_code;
  logic key_valid; 
  key_decoder u_key_decoder (
    .i_CLK        (i_CLK),
    .i_RST        (i_RST),
    .i_ROWS       (i_ROWS),
    .o_COLS       (o_COLS),
    .o_DECODED    (key_code),
    .o_VALID      (key_valid)
  );

  logic bcd_clear, bcd_valid;
  logic [NB-1:0] bcd_bin;
  bcd_to_bin #(
    .NB         (NB)
  ) u_bcd_to_bin (
    .i_CLK      (i_CLK),
    .i_RST      (i_RST),
    .i_CLEAR    (bcd_clear),
    .i_VALID    (bcd_valid),
    .i_BCD      (key_code),
    .o_BIN      (bcd_bin)
  );

  logic [NB-1:0] exec_data_A, exec_data_B, exec_result;
  e_opcode exec_opcode;
  logic exec_ovfl, exec_ready, exec_fin, exec_valid; 
  logic [$clog2(DIGITS):0] comma_data_A, comma_data_B, comma_result;
  logic comma_digit;
  execution_unit #(
    .NB          (NB),
    .NB_FRAC     (NB_FRAC)
  ) u_execution_unit (
    .i_CLK       (i_CLK),
    .i_RST       (i_RST),
    .i_VALID     (exec_valid),
    .i_DATA_A    (exec_data_A),
    .i_DATA_B    (exec_data_B),
    .i_OPCODE    (exec_opcode),
    .o_READY     (exec_ready),
    .o_FIN       (exec_fin),
    .o_RESULT    (exec_result),
    .o_OVFL      (exec_ovfl)
  );

  logic [NB-1:0] bin_bin;
  logic bin_valid, bin_ready, bin_fin;
  logic [DIGITS*4-1:0] bin_bcd;
  logic [$clog2(DIGITS)-1:0] bin_ndigits;
  bin_to_bcd #(
    .NB         (NB),
    .DIGITS     (DIGITS)
  ) u_bin_to_bcd (
    .i_CLK      (i_CLK),
    .i_RST      (i_RST),
    .i_BIN      (bin_bin),
    .i_VALID    (bin_valid),
    .o_READY    (bin_ready),
    .o_FIN      (bin_fin),
    .o_BCD      (bin_bcd),
    .o_NDIGITS  (bin_ndigits)
  );

  logic mem_clear, mem_we;
  logic [$clog2(WORD_COUNT)-1:0] mem_addr;
  logic [7:0] mem_data_in, mem_data_out;
  memory #(
    .WORD_SIZE     (8),
    .WORD_COUNT    (WORD_COUNT)
  ) u_memory (
    .i_CLK         (i_CLK),
    .i_RST         (i_RST),
    .i_CLEAR       (mem_clear),
    .i_WE          (mem_we),
    .i_ADDR        (mem_addr),
    .i_DATA        (mem_data_in),
    .o_DATA        (mem_data_out)
  );

  logic oled_init, oled_valid, oled_ready, oled_fin;
  logic [$clog2(WORD_COUNT)-1:0] oled_mem_addr;
  oled #(
    .PAGE_COUNT    (PAGE_COUNT),
    .COL_COUNT     (COL_COUNT)
  ) u_oled (
    .i_CLK         (i_CLK),
    .i_RST         (i_RST),
    .i_INIT        (oled_init),
    .i_VALID       (oled_valid),
    .o_READY       (oled_ready),
    .o_FIN         (oled_fin),
    .i_MEM_DATA    (mem_data_out),
    .o_MEM_ADDR    (oled_mem_addr),
    .o_DC          (o_DC),
    .o_VDD         (o_VDD),
    .o_VBAT        (o_VBAT),
    .o_RES         (o_RES),
    .o_SPI_CLK     (o_SPI_CLK),
    .o_SPI_MOSI    (o_SPI_MOSI)
  );

  logic rend_valid, rend_ready, rend_fin, rend_set_pos;
  logic [7:0] rend_ascii_char;
  logic [$clog2(COL_COUNT)-1:0] rend_cursor;
  logic [$clog2(PAGE_COUNT)-1:0] rend_page;
  logic [$clog2(WORD_COUNT)-1:0] rend_mem_addr;
  oled_renderer #(
    .PAGE_COUNT(PAGE_COUNT),
    .COL_COUNT(COL_COUNT)
  ) u_oled_renderer (
    .i_CLK           (i_CLK),
    .i_RST           (i_RST),
    .i_ASCII_CHAR    (rend_ascii_char),
    .i_VALID         (rend_valid),
    .i_CURSOR        (rend_cursor),
    .i_PAGE          (rend_page),
    .i_SET_POS       (rend_set_pos),
    .o_READY         (rend_ready),
    .o_FIN           (rend_fin),
    .o_RAM_WE        (mem_we),
    .o_RAM_ADDR      (rend_mem_addr),
    .o_RAM_DATA      (mem_data_in)
  );

  typedef enum {
    Init, // wait for oled to init
    WaitKey, // wait for key press
    Decide,
    KeyDigit, 
    KeyOp,
    KeyClear,
    KeyComma,
    AlignComma,
    Calc,
    Convert,
    CheckSign,
    ClearMem,
    SetResultCursor,
    SaveSign,
    SaveResult,
    ResetCursor,
    SaveKey,
    PrintOp,
    Flush
  } e_state;
  
  e_state current_state, next_state;
  logic load_reg; // 0 - A, 1 - B
  e_opcode next_op;
  logic shift_result;
  logic [$clog2(DIGITS)-1:0] result_cnt;
  logic print_comma;
  logic align_fin;
  assign align_fin = (comma_data_A == comma_data_B);

  always_ff @(posedge i_CLK) begin
    if(i_RST) current_state <= Init;
    else current_state <= next_state;
  end

  always_comb begin
    next_state = current_state;
    case(current_state)
      Init: if(oled_ready) next_state = WaitKey; 
      WaitKey: if(key_valid || i_CLEAR) next_state = SaveKey;
      SaveKey: if(rend_fin) next_state = Decide;
      Decide: begin
        if(i_CLEAR) next_state = KeyClear; 
        else if(is_digit(key_code)) next_state = KeyDigit;
        else if(key_code == KEY_COMMA) next_state = KeyComma;
        else next_state = KeyOp;
      end
      KeyDigit: next_state = Flush; 
      KeyOp: begin
        if(load_reg == 1'b1) next_state = AlignComma;
        else next_state = Flush;
      end
      KeyClear: next_state = Flush;
      KeyComma: next_state = Flush;
      AlignComma: if(align_fin) next_state = Calc;
      Calc: if(exec_fin) next_state = CheckSign;
      CheckSign: next_state = Convert;
      Convert: if(bin_fin) next_state = ClearMem;
      ClearMem: next_state = SetResultCursor;
      SetResultCursor: next_state = SaveSign;
      SaveSign: if(rend_fin) next_state = SaveResult;
      SaveResult: if(rend_fin && result_cnt == 0) next_state = ResetCursor;
      ResetCursor: next_state = PrintOp;
      PrintOp: if(rend_fin) next_state = Flush;
      Flush: if(oled_fin) next_state = WaitKey; 
      default: next_state = WaitKey;
    endcase
  end

  // execution_unit
  always_ff @(posedge i_CLK) begin
    if(i_RST || current_state == KeyClear) begin
      exec_data_A <= 0;
      exec_data_B <= 0;
      exec_opcode <= OP_PASS_A;
      exec_valid <= 0;
      load_reg <= 0;
      shift_result <= 0;
      next_op <= OP_PASS_A;
      comma_digit <= 0;
      comma_data_A <= 0;
      comma_data_B <= 0;
      comma_result <= 0;
    end else if(current_state == KeyComma) begin
      comma_digit <= 1;
    end else if(current_state == KeyDigit) begin
      if(comma_digit) begin
        if(load_reg == 1'b0) begin
          comma_data_A <= comma_data_A + 1;
        end else begin
          comma_data_B <= comma_data_B + 1;
        end
      end
    end else if(current_state == KeyOp) begin
      comma_digit <= 0;
      if(load_reg == 1'b0) begin
        exec_data_A <= bcd_bin;
        load_reg <= 1;
      end else begin
        exec_data_B <= bcd_bin;
      end

      exec_opcode <= next_op;
      case(key_code)
        KEY_PLUS: next_op <= OP_ADD;
        KEY_MINUS: next_op <= OP_SUB;
        KEY_MULT: next_op <= OP_MULT;
        KEY_DIV: next_op <= OP_DIV;
        KEY_EQUAL: next_op <= next_op;
        default: next_op <= OP_PASS_A;
      endcase
    end else if(current_state == AlignComma) begin
      if(comma_data_A > comma_data_B) begin
        exec_data_B <= (exec_data_B << 3) + (exec_data_B << 1);
        comma_data_B <= comma_data_B + 1;
      end else if(comma_data_B > comma_data_A) begin
        exec_data_A <= (exec_data_A << 3) + (exec_data_A << 1);
        comma_data_A <= comma_data_A + 1;
      end
    end else if(current_state == Calc) begin
      if(exec_ready) begin 
        exec_valid <= 1;
        case(exec_opcode)
          OP_ADD, OP_SUB: comma_result <= comma_data_A;
          OP_MULT: comma_result <= comma_data_A << 1;
          OP_DIV: comma_result <= FRAC_DIGITS;
        endcase
      end else exec_valid <= 0;

      shift_result <= 1;
    end else if(current_state == CheckSign) begin
      if(exec_result[NB-1]) bin_bin <= ~(exec_result) + 1;
      else bin_bin <= exec_result;
    end else if(current_state == Convert) begin
      if(shift_result == 1'b1) begin
        exec_data_A <= exec_result;
        comma_data_A <= comma_result;
        comma_data_B <= 0;
        shift_result <= 0;
      end
    end
  end 

  // result counter
  always_ff @(posedge i_CLK) begin
    if(i_RST || current_state == KeyClear) begin
      result_cnt <= DIGITS - 1;
    end else if(current_state == Convert && bin_fin) begin
      result_cnt <= bin_ndigits - 1;
    end else if(current_state == SaveResult && rend_fin && ~print_comma) begin
      if(result_cnt == 0) result_cnt <= DIGITS - 1;
      else result_cnt <= result_cnt - 1;
    end
  end

  // bcd_to_bin
  always_comb begin
    bcd_valid = 0;
    bcd_clear = 0;
    if(current_state == KeyDigit) begin
      bcd_valid = 1;
    end else if(current_state == KeyOp || current_state == KeyClear) begin
      bcd_clear = 1;
    end
  end

  // bin_to_bcd
  always_comb begin
    bin_valid = 0;
    if(current_state == Convert) begin
      if(bin_ready) bin_valid = 1;
    end
  end

  // memory
  always_comb begin 
    mem_clear = 0;
    mem_addr = 0;
    if(current_state == SaveKey || current_state == SaveResult || current_state == PrintOp || current_state == SaveSign) begin
      mem_addr = rend_mem_addr;
    end else if(current_state == Flush) begin
      mem_addr = oled_mem_addr;
    end else if(current_state == ClearMem || current_state == KeyClear) begin
      mem_clear = 1;
    end
  end

  always_ff @(posedge i_CLK) begin
    if(i_RST || current_state == KeyClear) begin
      print_comma <= 0;
    end else if(current_state == SaveResult) begin
      if(rend_ready) begin
        if(~print_comma && result_cnt == comma_result && result_cnt != 0) begin
          print_comma <= 1;
        end else begin
          print_comma <= 0;
        end
      end
    end
  end

  // oled_renderer
  always_comb begin
    rend_valid = 0;
    rend_set_pos = 0;
    rend_ascii_char = 0;
    rend_cursor = 0;
    rend_page = 0;
    if(current_state == SaveKey) begin
      if(rend_ready) begin
        rend_ascii_char = to_ascii(key_code);
        rend_valid = 1;
      end
    end else if(current_state == SaveSign) begin
      if(rend_ready) begin
        if(exec_result[NB-1]) rend_ascii_char = to_ascii(KEY_MINUS);
        else rend_ascii_char = 8'h20;
        rend_valid = 1;
      end
    end else if(current_state == SaveResult) begin
      if(rend_ready) begin
        if(print_comma) begin
          rend_ascii_char = to_ascii(KEY_COMMA);
        end else begin
          rend_ascii_char = to_ascii(bin_bcd[result_cnt * 4 +: 4]);
        end
        rend_valid = 1;
      end
    end else if(current_state == PrintOp) begin
      if(rend_ready) begin
        rend_ascii_char = to_ascii(key_code);
        rend_valid = 1;
      end
    end else if(current_state == SetResultCursor) begin
      rend_page = PAGE_COUNT - 1;
      rend_set_pos = 1;
    end else if(current_state == ResetCursor || current_state == KeyClear) begin
      rend_set_pos = 1;
    end
  end

  // oled 
  always_comb begin
    oled_init = 1; 
    oled_valid = 0;
    if(current_state == Flush) begin
      if(oled_ready) begin
        oled_valid = 1;
      end
    end
  end

endmodule