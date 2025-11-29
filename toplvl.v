module top(
    input clk,
    input reset
);

    // Sinais de interconexão
    wire pc_write, pc_write_cond, i_or_d, mem_read, mem_write, ir_write;
    wire [1:0] reg_dst, pc_src, alu_src_b;
    wire mem_to_reg, reg_write, alu_src_a, zero, greater;
    wire [3:0] alu_control;
    wire [5:0] opcode, funct;
    wire [31:0] mem_addr, mem_write_data, mem_read_data;

    // Instanciação da Unidade de Controle
    control_unit cu(
        .clk(clk),
        .reset(reset),
        .opcode(opcode),
        .funct(funct),
        .zero(zero),
        .greater(greater),
        .pc_write(pc_write),
        .pc_write_cond(pc_write_cond),
        .i_or_d(i_or_d),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .ir_write(ir_write),
        .reg_dst(reg_dst),
        .mem_to_reg(mem_to_reg),
        .reg_write(reg_write),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .alu_control(alu_control),
        .pc_src(pc_src)
    );

    // Instanciação do Datapath
    datapath dp(
        .clk(clk),
        .reset(reset),
        .pc_write(pc_write),
        .pc_write_cond(pc_write_cond),
        .i_or_d(i_or_d),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .ir_write(ir_write),
        .reg_dst(reg_dst),
        .mem_to_reg(mem_to_reg),
        .reg_write(reg_write),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .alu_control(alu_control),
        .pc_src(pc_src),
        .opcode(opcode),
        .funct(funct),
        .zero(zero),
        .greater(greater),
        .mem_addr(mem_addr),
        .mem_write_data(mem_write_data),
        .mem_read_data(mem_read_data)
    );

    // Instanciação da Memória
    memory_32x512 mem(
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .address(mem_addr),
        .write_data(mem_write_data),
        .read_data(mem_read_data)
    );

endmodule