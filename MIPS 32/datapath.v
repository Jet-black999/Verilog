module datapath(
    input clk,
    input reset,
    // Sinais de controle da UC
    input pc_write,
    input pc_write_cond,
    input i_or_d,
    input mem_read,
    input mem_write,
    input ir_write,
    input [1:0] reg_dst,
    input mem_to_reg,
    input reg_write,
    input alu_src_a,
    input [1:0] alu_src_b,
    input [3:0] alu_control,
    input [1:0] pc_src,
    // Saídas para a UC
    output [5:0] opcode,
    output [5:0] funct,
    output zero,
    output greater,
    // Interface com a memória
    output [31:0] mem_addr,
    output [31:0] mem_write_data,
    input [31:0] mem_read_data
);

    // Registradores do datapath
    reg [31:0] PC;
    reg [31:0] IR;
    reg [31:0] MDR;
    reg [31:0] A;
    reg [31:0] B;
    reg [31:0] ALUOut;

    // Banco de registradores
    reg [31:0] reg_file [0:31];
    
    // Fios internos
    wire [31:0] pc_next;
    wire [31:0] alu_result;
    wire [31:0] alu_a, alu_b;
    wire [31:0] sign_extended;
    wire [31:0] sign_extended_shifted;
    wire [31:0] reg_write_data;
    wire [4:0] reg_write_addr;
    
    integer i;

    // Inicialização
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PC <= 32'b0;
            IR <= 32'b0;
            MDR <= 32'b0;
            A <= 32'b0;
            B <= 32'b0;
            ALUOut <= 32'b0;
            for (i = 0; i < 32; i = i + 1)
                reg_file[i] <= 32'b0;
        end
    end

    // Extensão de sinal
    assign sign_extended = {{16{IR[15]}}, IR[15:0]};
    assign sign_extended_shifted = sign_extended << 2;

    // Banco de registradores
    wire [31:0] reg_data1 = reg_file[IR[25:21]]; // rs
    wire [31:0] reg_data2 = reg_file[IR[20:16]]; // rt

    always @(posedge clk) begin
        A <= reg_data1;
        B <= reg_data2;
        
        if (reg_write) begin
            reg_file[reg_write_addr] <= reg_write_data;
        end
    end

    // Seleção do endereço de escrita no banco de registradores
    assign reg_write_addr = (reg_dst == 2'b01) ? IR[15:11] : // rd
                           (reg_dst == 2'b00) ? IR[20:16] : // rt
                           5'b0;

    // Seleção do dado para write-back
    assign reg_write_data = (mem_to_reg) ? MDR : ALUOut;

    // ULA
    assign alu_a = (alu_src_a) ? A : PC;
    
    assign alu_b = (alu_src_b == 2'b00) ? B :
                   (alu_src_b == 2'b01) ? 32'd4 :
                   (alu_src_b == 2'b10) ? sign_extended :
                   (alu_src_b == 2'b11) ? sign_extended_shifted :
                   32'b0;

    ula_32b alu(
        .a(alu_a),
        .b(alu_b),
        .alu_control(alu_control),
        .result(alu_result),
        .zero(zero),
        .carry_out(),
        .overflow(),
        .greater(greater)
    );

    // Atualização do PC
    assign pc_next = (pc_src == 2'b00) ? alu_result :           // PC+4 ou ALU
                    (pc_src == 2'b01) ? ALUOut :               // Branch
                    (pc_src == 2'b10) ? {PC[31:28], IR[25:0], 2'b00} : // Jump
                    alu_result;

    always @(posedge clk) begin
        if (pc_write || (pc_write_cond && zero))
            PC <= pc_next;
    end

    // Interface com memória
    assign mem_addr = (i_or_d) ? ALUOut : PC;
    assign mem_write_data = B;

    // Registradores intermediários
    always @(posedge clk) begin
        if (ir_write)
            IR <= mem_read_data;
            
        if (mem_read)
            MDR <= mem_read_data;
            
        ALUOut <= alu_result;
    end

    // Saídas para UC
    assign opcode = IR[31:26];
    assign funct = IR[5:0];

endmodule