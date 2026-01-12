package key_codes_pkg;

  typedef logic [3:0] t_key_code;

  // digits 
  localparam t_key_code KEY_0     = 4'h0;
  localparam t_key_code KEY_1     = 4'h1;
  localparam t_key_code KEY_2     = 4'h2;
  localparam t_key_code KEY_3     = 4'h3;
  localparam t_key_code KEY_4     = 4'h4;
  localparam t_key_code KEY_5     = 4'h5;
  localparam t_key_code KEY_6     = 4'h6;
  localparam t_key_code KEY_7     = 4'h7;
  localparam t_key_code KEY_8     = 4'h8;
  localparam t_key_code KEY_9     = 4'h9;
  
  // comands 
  localparam t_key_code KEY_COMMA = 4'hF; 
  localparam t_key_code KEY_EQUAL = 4'hE; 
  localparam t_key_code KEY_PLUS  = 4'hA; 
  localparam t_key_code KEY_MINUS = 4'hB; 
  localparam t_key_code KEY_MULT  = 4'hC; 
  localparam t_key_code KEY_DIV   = 4'hD; 

  function automatic logic is_digit(t_key_code code);
    return (code >= KEY_0 && code <= KEY_9);
  endfunction

  function automatic logic [7:0] to_ascii(t_key_code code);
    case(code)
      KEY_0, KEY_1, KEY_2, KEY_3, KEY_4,
      KEY_5, KEY_6, KEY_7, KEY_8, KEY_9: 
        return 8'h30 + { 4'h0, code };

      KEY_COMMA: return 8'h2E;
      KEY_EQUAL: return 8'h3D;
      KEY_PLUS: return 8'h2B;
      KEY_MINUS: return 8'h2D;
      KEY_MULT: return 8'h2A;
      KEY_DIV: return 8'h2F;

      default: return 8'h20;
    endcase
  endfunction
  
endpackage