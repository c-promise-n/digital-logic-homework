`timescale 1ns/1ps
`include "defines.vh"

module tb_main_decoder;
    reg  [6:0] op;
    reg  [2:0] func3;
    wire branch;
    wire [1:0] result_src;
    wire mem_write;
    wire alu_srcA;
    wire alu_srcB;
    wire [2:0] imm_src;
    wire reg_write;
    wire [1:0] alu_op;
    wire lsu_read;
    wire jump;
    wire jalr;
    wire illegal_op;
    wire illegal_func;

    reg [15:0] checks;
    reg [15:0] errors;

    main_decoder u_dut (
        .op(op),
        .func3(func3),
        .branch(branch),
        .result_src(result_src),
        .mem_write(mem_write),
        .alu_srcA(alu_srcA),
        .alu_srcB(alu_srcB),
        .imm_src(imm_src),
        .reg_write(reg_write),
        .alu_op(alu_op),
        .lsu_read(lsu_read),
        .jump(jump),
        .jalr(jalr),
        .illegal_op(illegal_op),
        .illegal_func(illegal_func)
    );

    task chk;
        input [6:0]  in_op;
        input [2:0]  in_func3;
        input        exp_branch;
        input [1:0]  exp_result_src;
        input        exp_mem_write;
        input        exp_alu_srcA;
        input        exp_alu_srcB;
        input [2:0]  exp_imm_src;
        input        exp_reg_write;
        input [1:0]  exp_alu_op;
        input        exp_lsu_read;
        input        exp_jump;
        input        exp_jalr;
        input        exp_illegal_op;
        input        exp_illegal_func;
        input [8*32-1:0] name;
        begin
            op = in_op;
            func3 = in_func3;
            #1;
            checks = checks + 16'd1;
            if ({branch, result_src, mem_write, alu_srcA, alu_srcB, imm_src,
                 reg_write, alu_op, lsu_read, jump, jalr, illegal_op,
                 illegal_func}
                !==
                {exp_branch, exp_result_src, exp_mem_write, exp_alu_srcA,
                 exp_alu_srcB, exp_imm_src, exp_reg_write, exp_alu_op,
                 exp_lsu_read, exp_jump, exp_jalr, exp_illegal_op,
                 exp_illegal_func}) begin
                errors = errors + 16'd1;
                $display("FAIL @%0t [%0s] op=%07b f3=%03b branch=%b result=%b mem=%b srcA=%b srcB=%b imm=%b reg=%b alu_op=%b lsu_r=%b jump=%b jalr=%b illegal_op=%b illegal_func=%b",
                         $time, name, op, func3, branch, result_src, mem_write,
                         alu_srcA, alu_srcB, imm_src, reg_write, alu_op,
                         lsu_read, jump, jalr, illegal_op, illegal_func);
            end
        end
    endtask

    initial begin
        checks = 16'd0;
        errors = 16'd0;

        chk(`INST_LOAD,3'b010,0,2'b01,0,0,1,`IMMSRC_I,1,`ALU_OP_ADD,1,0,0,0,0,"LOAD valid");
        chk(`INST_LOAD,3'b000,0,2'b01,0,0,1,`IMMSRC_I,1,`ALU_OP_ADD,1,0,0,0,0,"LB");
        chk(`INST_LOAD,3'b001,0,2'b01,0,0,1,`IMMSRC_I,1,`ALU_OP_ADD,1,0,0,0,0,"LH");
        chk(`INST_LOAD,3'b100,0,2'b01,0,0,1,`IMMSRC_I,1,`ALU_OP_ADD,1,0,0,0,0,"LBU");
        chk(`INST_LOAD,3'b101,0,2'b01,0,0,1,`IMMSRC_I,1,`ALU_OP_ADD,1,0,0,0,0,"LHU");
        chk(`INST_OP_IMM,3'b000,0,2'b00,0,0,1,`IMMSRC_I,1,`ALU_OP_OP,0,0,0,0,0,"OP-IMM");
        chk(`INST_AUIPC,3'b000,0,2'b00,0,1,1,`IMMSRC_U,1,`ALU_OP_ADD,0,0,0,0,0,"AUIPC");
        chk(`INST_STORE,3'b010,0,2'b00,1,0,1,`IMMSRC_S,0,`ALU_OP_ADD,0,0,0,0,0,"STORE valid");
        chk(`INST_STORE,3'b000,0,2'b00,1,0,1,`IMMSRC_S,0,`ALU_OP_ADD,0,0,0,0,0,"SB");
        chk(`INST_STORE,3'b001,0,2'b00,1,0,1,`IMMSRC_S,0,`ALU_OP_ADD,0,0,0,0,0,"SH");
        chk(`INST_OP,3'b000,0,2'b00,0,0,0,`IMMSRC_0,1,`ALU_OP_OP,0,0,0,0,0,"OP");
        chk(`INST_LUI,3'b000,0,2'b00,0,0,1,`IMMSRC_U,1,`ALU_OP_PASSB,0,0,0,0,0,"LUI");
        chk(`INST_BRANCH,3'b101,1,2'b00,0,0,0,`IMMSRC_B,0,`ALU_OP_PASSB,0,0,0,0,0,"BRANCH valid");
        chk(`INST_BRANCH,3'b000,1,2'b00,0,0,0,`IMMSRC_B,0,`ALU_OP_PASSB,0,0,0,0,0,"BEQ");
        chk(`INST_BRANCH,3'b001,1,2'b00,0,0,0,`IMMSRC_B,0,`ALU_OP_PASSB,0,0,0,0,0,"BNE");
        chk(`INST_BRANCH,3'b100,1,2'b00,0,0,0,`IMMSRC_B,0,`ALU_OP_PASSB,0,0,0,0,0,"BLT");
        chk(`INST_BRANCH,3'b110,1,2'b00,0,0,0,`IMMSRC_B,0,`ALU_OP_PASSB,0,0,0,0,0,"BLTU");
        chk(`INST_BRANCH,3'b111,1,2'b00,0,0,0,`IMMSRC_B,0,`ALU_OP_PASSB,0,0,0,0,0,"BGEU");
        chk(`INST_JALR,3'b000,0,2'b10,0,0,1,`IMMSRC_I,1,`ALU_OP_PASSB,0,1,1,0,0,"JALR valid");
        chk(`INST_JAL,3'b000,0,2'b10,0,0,0,`IMMSRC_J,1,`ALU_OP_PASSB,0,1,0,0,0,"JAL");
        chk(7'b0001111,3'b000,0,2'b00,0,0,0,`IMMSRC_0,0,`ALU_OP_ERROR,0,0,0,1,0,"UNKNOWN OPCODE");

        chk(`INST_LOAD,3'b011,0,2'b00,0,0,0,`IMMSRC_0,0,`ALU_OP_ERROR,0,0,0,0,1,"ILLEGAL LOAD 011");
        chk(`INST_LOAD,3'b110,0,2'b00,0,0,0,`IMMSRC_0,0,`ALU_OP_ERROR,0,0,0,0,1,"ILLEGAL LOAD 110");
        chk(`INST_LOAD,3'b111,0,2'b00,0,0,0,`IMMSRC_0,0,`ALU_OP_ERROR,0,0,0,0,1,"ILLEGAL LOAD 111");
        chk(`INST_STORE,3'b011,0,2'b00,0,0,0,`IMMSRC_0,0,`ALU_OP_ERROR,0,0,0,0,1,"ILLEGAL STORE");
        chk(`INST_STORE,3'b100,0,2'b00,0,0,0,`IMMSRC_0,0,`ALU_OP_ERROR,0,0,0,0,1,"ILLEGAL STORE 100");
        chk(`INST_STORE,3'b101,0,2'b00,0,0,0,`IMMSRC_0,0,`ALU_OP_ERROR,0,0,0,0,1,"ILLEGAL STORE 101");
        chk(`INST_STORE,3'b110,0,2'b00,0,0,0,`IMMSRC_0,0,`ALU_OP_ERROR,0,0,0,0,1,"ILLEGAL STORE 110");
        chk(`INST_STORE,3'b111,0,2'b00,0,0,0,`IMMSRC_0,0,`ALU_OP_ERROR,0,0,0,0,1,"ILLEGAL STORE 111");
        chk(`INST_BRANCH,3'b010,0,2'b00,0,0,0,`IMMSRC_0,0,`ALU_OP_ERROR,0,0,0,0,1,"ILLEGAL BRANCH 010");
        chk(`INST_BRANCH,3'b011,0,2'b00,0,0,0,`IMMSRC_0,0,`ALU_OP_ERROR,0,0,0,0,1,"ILLEGAL BRANCH 011");
        chk(`INST_JALR,3'b001,0,2'b00,0,0,0,`IMMSRC_0,0,`ALU_OP_ERROR,0,0,0,0,1,"ILLEGAL JALR");

        if (errors == 16'd0)
            $display("PASS: main_decoder, %0d checks, 0 errors", checks);
        else
            $display("FAIL: main_decoder, %0d checks, %0d errors", checks, errors);
        $finish;
    end
endmodule
