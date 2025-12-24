package execution_opcode_pkg;

  typedef enum logic [3:0] {
    OP_ADD, OP_SUB,
    OP_OR, OP_AND, OP_XOR,
    OP_NOT_A, OP_NOT_B,
    OP_ROR_A, OP_RAND_B,
    OP_SHL, OP_SHR,
    OP_MULT, OP_DIV, OP_MOD
  } e_opcode;

endpackage