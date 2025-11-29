module mux_2x1_32b(
    input [31:0] in0,        // Entrada 0
    input [31:0] in1,        // Entrada 1
    input sel,               // Seletor
    output reg [31:0] out    // Saída
);

    always @(*) begin
        case(sel)
            1'b0: out = in0;
            1'b1: out = in1;
            default: out = 32'b0;
        endcase
    end

endmodule


