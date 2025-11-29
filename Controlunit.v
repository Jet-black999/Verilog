module control_unit(
    input clk,
    input reset,
    input [5:0] opcode,        // Opcode da instrução (6 bits)
    input [5:0] funct,         // Campo funct para instruções tipo R
    input zero,                // Flag zero da ULA
    input greater,             // Flag greater da ULA (para BGT)
    // Sinais de controle para o datapath
    output reg pc_write,
    output reg pc_write_cond,
    output reg i_or_d,
    output reg mem_read,
    output reg mem_write,
    output reg ir_write,
    output reg [1:0] reg_dst,
    output reg mem_to_reg,
    output reg reg_write,
    output reg alu_src_a,
    output reg [1:0] alu_src_b,
    output reg [3:0] alu_control,
    output reg [1:0] pc_src
);

    // Estados da máquina de controle (multiciclo)
    parameter FETCH     = 4'b0000;
    parameter DECODE    = 4'b0001;
    parameter MEM_ADDR  = 4'b0010;
    parameter MEM_READ  = 4'b0011;
    parameter MEM_WRITE = 4'b0100;
    parameter EXECUTE   = 4'b0101;
    parameter ALU_WB    = 4'b0110;
    parameter BRANCH    = 4'b0111;
    parameter JUMP      = 4'b1000;
    parameter BGT_EXEC  = 4'b1001;

    reg [3:0] current_state, next_state;

    // Opcodes das instruções (formato MIPS)
    parameter 
        OP_RTYPE = 6'b000000,  // Instruções tipo R
        OP_LW    = 6'b100011,  // Load Word
        OP_SW    = 6'b101011,  // Store Word
        OP_BEQ   = 6'b000100,  // Branch if Equal
        OP_BGT   = 6'b000101,  // Branch if Greater Than (custom)
        OP_J     = 6'b000010,  // Jump
        OP_ADDI  = 6'b001000,  // Add Immediate
        OP_ANDI  = 6'b001100,  // And Immediate
        OP_ORI   = 6'b001101;  // Or Immediate

    // Funct codes para instruções tipo R
    parameter
        FUNCT_ADD = 6'b100000,
        FUNCT_SUB = 6'b100010,
        FUNCT_AND = 6'b100100,
        FUNCT_OR  = 6'b100101,
        FUNCT_SLT = 6'b101010;

    // Transição de estados
    always @(posedge clk or posedge reset) begin
        if (reset) 
            current_state <= FETCH;
        else 
            current_state <= next_state;
    end

    // Lógica de próximo estado
    always @(*) begin
        case (current_state)
            FETCH: 
                next_state = DECODE;
                
            DECODE: 
                case (opcode)
                    OP_RTYPE: next_state = EXECUTE;
                    OP_LW, OP_SW: next_state = MEM_ADDR;
                    OP_BEQ: next_state = BRANCH;
                    OP_BGT: next_state = BGT_EXEC;
                    OP_J: next_state = JUMP;
                    OP_ADDI, OP_ANDI, OP_ORI: next_state = EXECUTE;
                    default: next_state = FETCH; // Instrução não reconhecida
                endcase
                
            MEM_ADDR:
                if (opcode == OP_LW) 
                    next_state = MEM_READ;
                else if (opcode == OP_SW) 
                    next_state = MEM_WRITE;
                else 
                    next_state = FETCH;
                    
            MEM_READ: 
                next_state = ALU_WB;
                
            MEM_WRITE: 
                next_state = FETCH;
                
            EXECUTE:
                if (opcode == OP_RTYPE || opcode == OP_ADDI || 
                    opcode == OP_ANDI || opcode == OP_ORI)
                    next_state = ALU_WB;
                else
                    next_state = FETCH;
                    
            ALU_WB: 
                next_state = FETCH;
                
            BRANCH: 
                next_state = FETCH;
                
            BGT_EXEC:
                next_state = FETCH;
                
            JUMP: 
                next_state = FETCH;
                
            default: 
                next_state = FETCH;
        endcase
    end

    // Geração de sinais de controle
    always @(*) begin
        // Valores padrão para todos os sinais
        pc_write = 1'b0;
        pc_write_cond = 1'b0;
        i_or_d = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        ir_write = 1'b0;
        reg_dst = 2'b00;
        mem_to_reg = 1'b0;
        reg_write = 1'b0;
        alu_src_a = 1'b0;
        alu_src_b = 2'b00;
        alu_control = 4'b0000;
        pc_src = 2'b00;

        case (current_state)
            FETCH: begin
                mem_read = 1'b1;
                ir_write = 1'b1;
                alu_src_a = 1'b0;           // PC
                alu_src_b = 2'b01;          // +4
                alu_control = 4'b0000;      // ADD
                pc_write = 1'b1;
                pc_src = 2'b00;             // ALU result
            end

            DECODE: begin
                alu_src_a = 1'b0;           // PC
                alu_src_b = 2'b11;          // Offset shifted
                alu_control = 4'b0000;      // ADD
            end

            MEM_ADDR: begin
                alu_src_a = 1'b1;           // Registrador A
                alu_src_b = 2'b10;          // Offset estendido
                alu_control = 4'b0000;      // ADD
            end

            MEM_READ: begin
                mem_read = 1'b1;
                i_or_d = 1'b1;              // Endereço da memória de dados
            end

            MEM_WRITE: begin
                mem_write = 1'b1;
                i_or_d = 1'b1;              // Endereço da memória de dados
            end

            EXECUTE: begin
                alu_src_a = 1'b1;           // Registrador A
                
                // Determina operação da ULA baseada no opcode/funct
                case (opcode)
                    OP_RTYPE: begin
                        alu_src_b = 2'b00;  // Registrador B
                        case (funct)
                            FUNCT_ADD: alu_control = 4'b0000; // ADD
                            FUNCT_SUB: alu_control = 4'b0001; // SUB
                            FUNCT_AND: alu_control = 4'b0010; // AND
                            FUNCT_OR:  alu_control = 4'b0011; // OR
                            FUNCT_SLT: alu_control = 4'b0110; // SLT
                            default:   alu_control = 4'b0000; // ADD
                        endcase
                    end
                    OP_ADDI: begin
                        alu_src_b = 2'b10;  // Imediato
                        alu_control = 4'b0000; // ADD
                    end
                    OP_ANDI: begin
                        alu_src_b = 2'b10;  // Imediato
                        alu_control = 4'b0010; // AND
                    end
                    OP_ORI: begin
                        alu_src_b = 2'b10;  // Imediato
                        alu_control = 4'b0011; // OR
                    end
                    default: begin
                        alu_src_b = 2'b00;
                        alu_control = 4'b0000;
                    end
                endcase
            end

            ALU_WB: begin
                reg_write = 1'b1;
                if (opcode == OP_LW) begin
                    mem_to_reg = 1'b1;      // Dado da memória
                    reg_dst = 2'b00;        // rt
                end else if (opcode == OP_RTYPE) begin
                    mem_to_reg = 1'b0;      // Resultado da ULA
                    reg_dst = 2'b01;        // rd
                end else begin
                    mem_to_reg = 1'b0;      // Resultado da ULA
                    reg_dst = 2'b00;        // rt (para I-type)
                end
            end

            BRANCH: begin
                alu_src_a = 1'b1;           // Registrador A
                alu_src_b = 2'b00;          // Registrador B
                alu_control = 4'b0001;      // SUB
                pc_write_cond = 1'b1;       // Escrita condicional
                pc_src = 2'b01;             // Branch target
            end

            BGT_EXEC: begin
                alu_src_a = 1'b1;           // Registrador A
                alu_src_b = 2'b00;          // Registrador B
                alu_control = 4'b0001;      // SUB
                pc_write_cond = greater;    // Escrita se greater=1
                pc_src = 2'b01;             // Branch target
            end

            JUMP: begin
                pc_write = 1'b1;
                pc_src = 2'b10;             // Jump address
            end
        endcase
    end

endmodule
