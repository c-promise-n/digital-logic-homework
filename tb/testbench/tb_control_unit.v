`timescale 1ns/1ps
`include "defines.vh"

module tb_control_unit;
    reg [6:0] op;
    reg [2:0] func3;
    reg func7_5;

    wire [1:0] result_src;
    wire mem_write;
    wire [3:0] alu_control;
    wire alu_srcA;
    wire alu_srcB;
    wire [2:0] imm_src;
    wire reg_write;
    wire lsu_read;
    wire lsu_write;
    wire [2:0] lsu_func3;
    wire jump;
    wire jalr;
    wire is_branch;
    wire [2:0] branch_op;
    wire illegal_inst;

    reg [15:0] checks;
    reg [15:0] errors;

    control_unit u_dut (
        .op(op),
        .func3(func3),
        .func7_5(func7_5),
        .result_src(result_src),
        .mem_write(mem_write),
        .alu_control(alu_control),
        .alu_srcA(alu_srcA),
        .alu_srcB(alu_srcB),
        .imm_src(imm_src),
        .reg_write(reg_write),
        .lsu_read(lsu_read),
        .lsu_write(lsu_write),
        .lsu_func3(lsu_func3),
        .jump(jump),
        .jalr(jalr),
        .is_branch(is_branch),
        .branch_op(branch_op),
        .illegal_inst(illegal_inst)
    );

    task chk;
        input [6:0]  in_op;
        input [2:0]  in_func3;
        input        in_func7_5;
        input [1:0]  exp_result;
        input        exp_mem;
        input [3:0]  exp_alu;
        input        exp_srcA;
        input        exp_srcB;
        input [2:0]  exp_imm;
        input        exp_reg;
        input        exp_lsu_r;
        input        exp_lsu_w;
        input        exp_jump;
        input        exp_jalr;
        input        exp_branch;
        input        exp_illegal;
        input [8*32-1:0] name;
        begin
            op = in_op;
            func3 = in_func3;
            func7_5 = in_func7_5;
            #1;
            checks = checks + 16'd1;
            if ((result_src !== exp_result) || (mem_write !== exp_mem) ||
                (alu_control !== exp_alu) || (alu_srcA !== exp_srcA) ||
                (alu_srcB !== exp_srcB) || (imm_src !== exp_imm) ||
                (reg_write !== exp_reg) || (lsu_read !== exp_lsu_r) ||
                (lsu_write !== exp_lsu_w) || (lsu_func3 !== in_func3) ||
                (jump !== exp_jump) || (jalr !== exp_jalr) ||
                (is_branch !== exp_branch) || (branch_op !== in_func3) ||
                (illegal_inst !== exp_illegal)) begin
                errors = errors + 16'd1;
                $display("FAIL @%0t [%0s] op=%07b f3=%03b f7_5=%b result=%b mem=%b alu=%h srcA=%b srcB=%b imm=%b reg=%b lsu_r=%b lsu_w=%b lsu_f3=%03b jump=%b jalr=%b branch=%b bop=%03b illegal=%b",
                         $time, name, op, func3, func7_5,
                         result_src, mem_write, alu_control, alu_srcA, alu_srcB,
                         imm_src, reg_write, lsu_read, lsu_write, lsu_func3,
                         jump, jalr, is_branch, branch_op, illegal_inst);
            end
        end
    endtask

    initial begin
        checks = 16'd0;
        errors = 16'd0;

        chk(`INST_LOAD,3'b010,0,2'b01,0,`ALU_ADD,0,1,`IMMSRC_I,1,1,0,0,0,0,0,"LW");
        chk(`INST_OP_IMM,3'b000,0,2'b00,0,`ALU_ADD,0,1,`IMMSRC_I,1,0,0,0,0,0,0,"ADDI");
        chk(`INST_OP_IMM,3'b101,0,2'b00,0,`ALU_SRL,0,1,`IMMSRC_I,1,0,0,0,0,0,0,"SRLI");
        chk(`INST_OP_IMM,3'b101,1,2'b00,0,`ALU_SRA,0,1,`IMMSRC_I,1,0,0,0,0,0,0,"SRAI");
        chk(`INST_AUIPC,3'b000,0,2'b00,0,`ALU_ADD,1,1,`IMMSRC_U,1,0,0,0,0,0,0,"AUIPC");
        chk(`INST_STORE,3'b010,0,2'b00,1,`ALU_ADD,0,1,`IMMSRC_S,0,0,1,0,0,0,0,"SW");
        chk(`INST_OP,3'b000,0,2'b00,0,`ALU_ADD,0,0,`IMMSRC_0,1,0,0,0,0,0,0,"ADD");
        chk(`INST_OP,3'b000,1,2'b00,0,`ALU_SUB,0,0,`IMMSRC_0,1,0,0,0,0,0,0,"SUB");
        chk(`INST_OP,3'b101,1,2'b00,0,`ALU_SRA,0,0,`IMMSRC_0,1,0,0,0,0,0,0,"SRA");
        chk(`INST_LUI,3'b000,0,2'b00,0,`ALU_PASS_B,0,1,`IMMSRC_U,1,0,0,0,0,0,0,"LUI");
        chk(`INST_BRANCH,3'b101,0,2'b00,0,`ALU_PASS_B,0,0,`IMMSRC_B,0,0,0,0,0,1,0,"BGE");
        chk(`INST_JALR,3'b000,0,2'b10,0,`ALU_PASS_B,0,1,`IMMSRC_I,1,0,0,1,1,0,0,"JALR");
        chk(`INST_JAL,3'b000,0,2'b10,0,`ALU_PASS_B,0,0,`IMMSRC_J,1,0,0,1,0,0,0,"JAL");

        chk(7'b0001111,3'b000,0,2'b00,0,`ALU_PASS_B,0,0,`IMMSRC_0,0,0,0,0,0,0,1,"UNKNOWN OPCODE");

        // Coverage for still-unchecked funct3 / illegal instruction cases.
        chk(`INST_LOAD,3'b011,0,2'b01,0,`ALU_ADD,0,1,`IMMSRC_I,1,1,0,0,0,0,1,"ILLEGAL LOAD FUNCT3");
        chk(`INST_STORE,3'b011,0,2'b00,1,`ALU_ADD,0,1,`IMMSRC_S,0,0,1,0,0,0,1,"ILLEGAL STORE FUNCT3");
        chk(`INST_BRANCH,3'b010,0,2'b00,0,`ALU_PASS_B,0,0,`IMMSRC_B,0,0,0,0,0,1,1,"ILLEGAL BRANCH FUNCT3");
        chk(`INST_JALR,3'b001,0,2'b10,0,`ALU_PASS_B,0,1,`IMMSRC_I,1,0,0,1,1,0,1,"ILLEGAL JALR FUNCT3");

        if (errors == 16'd0)
            $display("PASS: control_unit, %0d checks, 0 errors", checks);
        else
            $display("FAIL: control_unit, %0d checks, %0d errors", checks, errors);
        $finish;
    end
endmodule
