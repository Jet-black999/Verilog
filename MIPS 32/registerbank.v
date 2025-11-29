module register_bank(
    input clk,
    input reset,
    input write_enable,
    input [3:0] read_addr1,    // 4 bits para endereçar 16 registradores
    input [3:0] read_addr2,
    input [3:0] write_addr,
    input [15:0] write_data,   // Dado de 16 bits
    output reg [15:0] read_data1,
    output reg [15:0] read_data2
);

    // Declaração dos 16 registradores de 16 bits
    reg [15:0] registers [0:15];
    
    integer i;
    
    // Inicialização e reset
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset todos os registradores para 0
            for (i = 0; i < 16; i = i + 1) begin
                registers[i] <= 16'b0;
            end
        end else if (write_enable) begin
            // Escrita síncrona - apenas se write_enable estiver ativo
            registers[write_addr] <= write_data;
        end
    end
    
    // Leitura assíncrona - sempre disponível
    always @(*) begin
        read_data1 = registers[read_addr1];
        read_data2 = registers[read_addr2];
    end

endmodule