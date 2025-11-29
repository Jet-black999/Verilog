module ula_32b(
    input [31:0] a,          // Operando A (32 bits)
    input [31:0] b,          // Operando B (32 bits)  
    input [3:0] alu_control, // Controle da ULA (4 bits)
    output reg [31:0] result, // Resultado (32 bits)
    output zero,              // Flag zero
    output carry_out,         // Flag carry out
    output overflow           // Flag overflow
);

    // Definição das operações
    parameter 
        OP_ADD  = 4'b0000,   // Soma
        OP_SUB  = 4'b0001,   // Subtração
        OP_AND  = 4'b0010,   // AND lógico
        OP_OR   = 4'b0011,   // OR lógico
        OP_XOR  = 4'b0100,   // XOR lógico
        OP_NOR  = 4'b0101,   // NOR lógico
        OP_SLT  = 4'b0110,   // Set on Less Than (com sinal)
        OP_SLTU = 4'b0111,   // Set on Less Than Unsigned
        OP_SLL  = 4'b1000,   // Shift Left Logical
        OP_SRL  = 4'b1001,   // Shift Right Logical
        OP_SRA  = 4'b1010;   // Shift Right Arithmetic

    // Sinais internos
    wire [31:0] add_result;
    wire [31:0] sub_result;
    wire add_carry, sub_carry;
    
    // Somador/Subtrator de 32 bits
    assign {add_carry, add_result} = a + b;
    assign {sub_carry, sub_result} = a - b;
    
    // Lógica principal da ULA
    always @(*) begin
        case(alu_control)
            OP_ADD:  result = add_result;
            OP_SUB:  result = sub_result;
            OP_AND:  result = a & b;
            OP_OR:   result = a | b;
            OP_XOR:  result = a ^ b;
            OP_NOR:  result = ~(a | b);
            OP_SLT:  result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            OP_SLTU: result = (a < b) ? 32'd1 : 32'd0;
            OP_SLL:  result = a << b[4:0];  // Shift até 31 posições
            OP_SRL:  result = a >> b[4:0];
            OP_SRA:  result = $signed(a) >>> b[4:0];
            default: result = 32'b0;
        endcase
    end
    
    // Flags
    assign zero = (result == 32'b0);
    assign carry_out = (alu_control == OP_ADD) ? add_carry : 
                      (alu_control == OP_SUB) ? sub_carry : 1'b0;
    
    // Detecção de overflow (para operações com sinal)
    wire overflow_add = (a[31] == b[31]) && (result[31] != a[31]);
    wire overflow_sub = (a[31] != b[31]) && (result[31] != a[31]);
    assign overflow = (alu_control == OP_ADD) ? overflow_add :
                     (alu_control == OP_SUB) ? overflow_sub : 1'b0;

endmodule





