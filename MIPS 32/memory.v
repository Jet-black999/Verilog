module memory_32x512(
    input clk,
    input mem_read,
    input mem_write,
    input [31:0] address,        // Endereço de 32 bits
    input [31:0] write_data,     // Dado de escrita de 32 bits
    output reg [31:0] read_data  // Dado de leitura de 32 bits
);

    // Memória 512 posições de 32 bits
    reg [31:0] mem [0:511];
    
    integer i;
    
    // Inicialização da memória
    initial begin
        // Inicializa toda memória com 0
        for (i = 0; i < 512; i = i + 1) begin
            mem[i] = 32'b0;
        end
        
        // Exemplo: carrega um programa simples na memória
        // ADD r1, r2, r3
        mem[0] = {6'b000000, 5'd2, 5'd1, 5'd3, 5'b00000, 6'b100000};
        
        // LW r4, 100(r0)
        mem[1] = {6'b100011, 5'd0, 5'd4, 16'd100};
        
        // SW r4, 104(r0)
        mem[2] = {6'b101011, 5'd0, 5'd4, 16'd104};
        
        // BEQ r1, r2, 8
        mem[3] = {6'b000100, 5'd1, 5'd2, 16'd8};
        
        // Inicializa alguns dados
        mem[100] = 32'd42;      // Dado na posição 100
        mem[101] = 32'd123;     // Dado na posição 101
    end
    
    // Leitura síncrona
    always @(posedge clk) begin
        if (mem_read) begin
            if (address < 512) begin
                read_data <= mem[address];
            end else begin
                read_data <= 32'b0;  // Endereço inválido
            end
        end
    end
    
    // Escrita síncrona
    always @(posedge clk) begin
        if (mem_write) begin
            if (address < 512) begin
                mem[address] <= write_data;
            end
            // Endereços >= 512 são ignorados
        end
    end

endmodule

#instruções e dados separadados 

module unified_memory(
    input clk,
    // Interface de instruções (somente leitura)
    input [31:0] instr_address,
    output reg [31:0] instr_read_data,
    // Interface de dados (leitura/escrita)
    input data_mem_read,
    input data_mem_write,
    input [31:0] data_address,
    input [31:0] data_write_data,
    output reg [31:0] data_read_data
);

    // Memória 512 posições de 32 bits
    reg [31:0] mem [0:511];
    
    integer i;
    
    // Inicialização
    initial begin
        for (i = 0; i < 512; i = i + 1) begin
            mem[i] = 32'b0;
        end
        
        // Programa de exemplo
        mem[0] = 32'h00000000;  // NOP
        mem[1] = 32'h8C090000;  // LW $t1, 0($zero)
        mem[2] = 32'h8C0A0004;  // LW $t2, 4($zero)
        mem[3] = 32'h012A5820;  // ADD $t3, $t1, $t2
        mem[4] = 32'hAC0B0008;  // SW $t3, 8($zero)
        
        // Dados
        mem[100] = 32'd15;
        //numero 15 em hexadecimal 
        mem[101] = 32'd27;
    end
    
    // Leitura de instruções (assíncrona para melhor performance)
    always @(*) begin
        if (instr_address < 512) begin
            instr_read_data = mem[instr_address];
        end else begin
            instr_read_data = 32'b0;
        end
    end
    
    // Leitura/escrita de dados (síncrona)
    always @(posedge clk) begin
        // Leitura de dados
        if (data_mem_read && data_address < 512) begin
            data_read_data <= mem[data_address];
        end
        
        // Escrita de dados
        if (data_mem_write && data_address < 512) begin
            mem[data_address] <= data_write_data;
        end
    end

endmodule