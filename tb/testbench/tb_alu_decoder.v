`timescale 1ns/1ps
`include "defines.vh"

module tb_alu_decoder;
    reg op_5;
    reg [2:0] func3;
    reg [6:0] func7;
    reg [1:0] alu_op;
    wire [3:0] alu_control;
    wire illegal_func;

    reg [15:0] checks;
    reg [15:0] errors;

    alu_decoder u_dut (
        .op_5(op_5),
        .func3(func3),
        .func7_5(func7),
        .alu_op(alu_op),
        .alu_control(alu_control),
        .illegal_func(illegal_func)
    );

    task chk;
        input        in_op5;
        input [2:0]  in_func3;
        input [6:0]  in_func7;
        input [1:0]  in_alu_op;
        input [3:0]  exp_control;
        input        exp_illegal;
        input [8*32-1:0] name;
        begin
            op_5 = in_op5;
            func3 = in_func3;
            func7 = in_func7;
            alu_op = in_alu_op;
            #1;
            checks = checks + 16'd1;
            if ((alu_control !== exp_control) || (illegal_func !== exp_illegal)) begin
                errors = errors + 16'd1;
                $display("FAIL @%0t [%0s] op5=%b f3=%03b f7=%07b alu_op=%b got_ctrl=%h got_illegal=%b exp_ctrl=%h exp_illegal=%b",
                         $time, name, op_5, func3, func7, alu_op,
                         alu_control, illegal_func, exp_control, exp_illegal);
            end
        end
    endtask

    initial begin
        checks = 16'd0;
        errors = 16'd0;

        chk(0,3'b000,7'b0000000,`ALU_OP_ADD,`ALU_ADD,0,"ADD/Load/Store ADD");
        chk(0,3'bxxx,7'bxxxxxxx,`ALU_OP_ADD,`ALU_ADD,0,"ADD ignores func bits");

        chk(1,3'b000,7'b0100000,`ALU_OP_OP,`ALU_SUB,0,"SUB");
        chk(0,3'b000,7'b0100000,`ALU_OP_OP,`ALU_ADD,0,"I ADD-like f3=000");
        chk(1,3'b000,7'b0000000,`ALU_OP_OP,`ALU_ADD,0,"R ADD");
        chk(0,3'b001,7'b0000000,`ALU_OP_OP,`ALU_SLL,0,"SLLI/SLL");
        chk(0,3'b010,7'b0000000,`ALU_OP_OP,`ALU_SLT,0,"SLT/SLTI");
        chk(0,3'b011,7'b0000000,`ALU_OP_OP,`ALU_SLTU,0,"SLTU/SLTIU");
        chk(0,3'b100,7'b0000000,`ALU_OP_OP,`ALU_XOR,0,"XOR/XORI");
        chk(0,3'b101,7'b0000000,`ALU_OP_OP,`ALU_SRL,0,"SRL/SRLI");
        chk(1,3'b101,7'b0100000,`ALU_OP_OP,`ALU_SRA,0,"SRA");
        chk(0,3'b101,7'b0100000,`ALU_OP_OP,`ALU_SRA,0,"SRAI");
        chk(0,3'b110,7'b0000000,`ALU_OP_OP,`ALU_OR,0,"OR/ORI");
        chk(0,3'b111,7'b0000000,`ALU_OP_OP,`ALU_AND,0,"AND/ANDI");

        // Full funct7 validation coverage (currently only func7[5]/nonzero status is available).
        chk(1,3'b000,7'b0000001,`ALU_OP_OP,`ALU_ADD,1,"INVALID R-TYPE ADD/SUB funct7");
        chk(1,3'b101,7'b0000001,`ALU_OP_OP,`ALU_SRL,1,"INVALID SRL/SRA funct7");

        chk(0,3'b000,7'b0000000,`ALU_OP_PASSB,`ALU_PASS_B,0,"PASS-B");
        chk(0,3'bxxx,7'bxxxxxxx,`ALU_OP_ERROR,`ALU_PASS_B,1,"ALU_OP_ERROR default");
        chk(0,3'b000,7'b0000000,2'b00,`ALU_PASS_B,1,"Unknown alu_op");

        if (errors == 16'd0)
            $display("PASS: alu_decoder, %0d checks, 0 errors", checks);
        else
            $display("FAIL: alu_decoder, %0d checks, %0d errors", checks, errors);
        $finish;
    end
endmodule
