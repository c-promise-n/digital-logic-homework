`timescale 1ns/1ps
`include "defines.vh"

module tb_main_decoder;
    reg  [6:0] op;
    wire branch;
    wire [1:0] result_src;
    wire mem_write;
    wire alu_srcA;
    wire alu_srcB;
    wire [2:0] imm_src;
    wire reg_write;
    wire [1:0] alu_op;
    wire lsu_read;
    wire lsu_write;
    wire jump;
    wire jalr;
    wire illegal_op;

    reg [15:0] checks;
    reg [15:0] errors;

    main_decoder u_dut (
        .op(op),
        .branch(branch),
        .result_src(result_src),
        .mem_write(mem_write),
        .alu_srcA(alu_srcA),
        .alu_srcB(alu_srcB),
        .imm_src(imm_src),
        .reg_write(reg_write),
        .alu_op(alu_op),
        .lsu_read(lsu_read),
        .lsu_write(lsu_write),
        .jump(jump),
        .jalr(jalr),
        .illegal_op(illegal_op)
    );

    task chk;
        input [6:0]  opcode;
        input        exp_branch;
        input [1:0]  exp_result_src;
        input        exp_mem_write;
        input        exp_alu_srcA;
        input        exp_alu_srcB;
        input [2:0]  exp_imm_src;
        input        exp_reg_write;
        input [1:0]  exp_alu_op;
        input        exp_lsu_read;
        input        exp_lsu_write;
        input        exp_jump;
        input        exp_jalr;
        input        exp_illegal;
        input [8*32-1:0] name;
        begin
            op = opcode;
            #1;
            checks = checks + 16'd1;
            if ({branch, result_src, mem_write, alu_srcA, alu_srcB, imm_src,
                 reg_write, alu_op, lsu_read, lsu_write, jump, jalr, illegal_op}
                !==
                {exp_branch, exp_result_src, exp_mem_write, exp_alu_srcA,
                 exp_alu_srcB, exp_imm_src, exp_reg_write, exp_alu_op,
                 exp_lsu_read, exp_lsu_write, exp_jump, exp_jalr, exp_illegal}) begin
                errors = errors + 16'd1;
                $display("FAIL @%0t [%0s] branch=%b result=%b mem=%b srcA=%b srcB=%b imm=%b reg=%b alu_op=%b lsu_r=%b lsu_w=%b jump=%b jalr=%b illegal=%b",
                         $time, name, branch, result_src, mem_write, alu_srcA,
                         alu_srcB, imm_src, reg_write, alu_op, lsu_read,
                         lsu_write, jump, jalr, illegal_op);
            end
        end
    endtask

    initial begin
        checks = 16'd0;
        errors = 16'd0;

        chk(`INST_LOAD, 0,2'b01,0,0,1,`IMMSRC_I,1,`ALU_OP_ADD,1,0,0,0,0,"LOAD");
        chk(`INST_OP_IMM,0,2'b00,0,0,1,`IMMSRC_I,1,`ALU_OP_OP,0,0,0,0,0,"OP-IMM");
        chk(`INST_AUIPC,0,2'b00,0,1,1,`IMMSRC_U,1,`ALU_OP_ADD,0,0,0,0,0,"AUIPC");
        chk(`INST_STORE,0,2'b00,1,0,1,`IMMSRC_S,0,`ALU_OP_ADD,0,1,0,0,0,"STORE");
        chk(`INST_OP,0,2'b00,0,0,0,`IMMSRC_0,1,`ALU_OP_OP,0,0,0,0,0,"OP");
        chk(`INST_LUI,0,2'b00,0,0,1,`IMMSRC_U,1,`ALU_OP_PASSB,0,0,0,0,0,"LUI");
        chk(`INST_BRANCH,1,2'b00,0,0,0,`IMMSRC_B,0,`ALU_OP_PASSB,0,0,0,0,0,"BRANCH");
        chk(`INST_JALR,0,2'b10,0,0,1,`IMMSRC_I,1,`ALU_OP_PASSB,0,0,1,1,0,"JALR");
        chk(`INST_JAL,0,2'b10,0,0,0,`IMMSRC_J,1,`ALU_OP_PASSB,0,0,1,0,0,"JAL");
        chk(7'b0001111,0,2'b00,0,0,0,`IMMSRC_0,0,`ALU_OP_ERROR,0,0,0,0,1,"UNKNOWN OPCODE");

        if (errors == 16'd0)
            $display("PASS: main_decoder, %0d checks, 0 errors", checks);
        else
            $display("FAIL: main_decoder, %0d checks, %0d errors", checks, errors);
        $finish;
    end
endmodule
