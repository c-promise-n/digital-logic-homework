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
// Additional Comments:
// 目前实现的是单周期处理器的功能，见P259
//////////////////////////////////////////////////////////////////////////////////

module control_unit(
    input [6:0] op,
    input [14:12] func3,
    input func7_5,          //fucn7的第5位，risc32i仅使用fucn7的第5位
    input zero,

    output pc_src,          //1'b0: pc+4; 1'b1: pc target
    output [1:0] result_src,      //2'b00: alu result; 2'b01: RAM data; 2'b11, pc+4
    output mem_write,       //active high
    output [3:0] alu_control,    //refer to defines.vh
    output alu_srcA,        //1'b1:choose immext, 1'b0: choose rd2
    output alu_srcB,        //1'b1:choose pc, 1'b0: choose rd2
    output [2:0] imm_src,   //refer to defines.vh
    output reg_write,       //active high
    output lsu_read,        //lsu read enable, active high
    output lsu_write,       //lsu write rnable, active high
    output [2:0] lsu_func3, //lsu func3 input, same as func3
    output pctarget_src     //control pac target MUX, active high
);  
wire branch;
wire jump;
wire [1:0] alu_op;
main_decoder U1 (
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
    .pctarget_src(pctarget_src)
);

alu_decoder U2 (
    .op_5(op[5]),
    .func3(func3),
    .func7_5(func7_5),
    .alu_op(alu_op),
    .alu_control(alu_control)
);

wire branch_check;// check if meet branch conditions, active high
assign branch_check = func3[2] ^ func3[0] ^ zero;
/*why this expression?
func3       instru      alu action      zero=?when meet condition
000         beq         sub             1
001         bne         sub             0
100         blt         slt             0
101         bge         slt             1
110         bltu        sltu            0
111         bgeu        sltu            1
*/

assign pc_src = (branch_check & branch) | jump;
assign lsu_func3 = func3;



endmodule