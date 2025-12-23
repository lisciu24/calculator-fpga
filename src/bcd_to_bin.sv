module bcd_to_bin #(
    parameter NB = 32 // max number - 2 * NB - 1
) (
    input i_CLK,
    input i_RST,
    input i_CLEAR,
    input i_VALID,
    input [3:0] i_BCD,
    output [NB-1:0] o_BIN
);

reg [NB-1:0] r_acc;

always_ff @(posedge i_CLK) begin
    if(i_RST | i_CLEAR) begin
        r_acc <= 0;
    end else if(i_VALID && i_BCD <= 4'h9) begin
        r_acc <= (r_acc << 3) + (r_acc << 1) + i_BCD;
    end
end

assign o_BIN = r_acc;

endmodule