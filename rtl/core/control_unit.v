//////////////////////////////////////////////////////////////////////////////////
// Engineer: Pinfeng_Song
// 
// Create Date: 2026/11/22 11:42
// Design Name: control unit for single period cpu ID module
// Module Name: control_unit
// Project Name: digital-logic-homework
// Description: 
// 单周期处理器的控制单元，ID模块的子模块
// Dependencies: defines.vh
// 
// Revision:
// - Revision 0.0.1 2026/11/22
//      暂未实现SYSTEM和MISC-MEM指令
// - Revision 0.0.2 2026/11/28
//      传入func7全部内容，但目前仅仅使用第六位。
//      添加了func3校验功能
//      其中LOAD、STORE、BRANCH和JALR指令的func3在main_decoder中完成校验，输出illegal_func_main
//      OP_IMM和OP的func3在alu_decoder中完成校验，输出illegal_func_alu
// Additional Comments:
// 目前实现的是单周期处理器的功能，见P259
//////////////////////////////////////////////////////////////////////////////////

module control_unit(
    input [6:0] op,
    input [14:12] func3,
    input [6:0] func7,      //fucn7，risc32i仅使用fucn7的第6位

    output [1:0] result_src,      //2'b00: alu result; 2'b01: RAM data; 2'b10, pc+4
    output mem_write,       //active high
    output [3:0] alu_control,    //refer to defines.vh
    output alu_srcA,        //1'b1:choose pc, 1'b0: choose rd2
    output alu_srcB,        //1'b1:choose immext, 1'b0: choose rd2
    output [2:0] imm_src,   //refer to defines.vh
    output reg_write,       //active high
    output lsu_read,        //lsu read enable, active high
    output [2:0] lsu_func3, //lsu func3 input, same as func3
    output jump,            //active high
    output jalr,            //active high
    output is_branch,       //active high
    output [2:0] branch_op, //refer to defines.vh
    output illegal_inst
);  

wire [1:0] alu_op;
wire illegal_op;
wire illegal_func_main;
main_decoder U1 (
    .op(op),
    .func3(func3),
    .branch(is_branch),
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
    .illegal_func(illegal_func_main)
);
wire illegal_func_alu;
alu_decoder U2 (
    .op_5(op[5]),
    .func3(func3),
    .func7(func7),
    .alu_op(alu_op),
    .alu_control(alu_control),
    .illegal_func(illegal_func_alu)
);


assign illegal_inst = illegal_func_main| illegal_func_alu | illegal_op;
assign lsu_func3 = func3;
assign branch_op = func3;



endmodule