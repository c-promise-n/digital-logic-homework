//////////////////////////////////////////////////////////////////////////////////
// Engineer: Pinfeng_Song
// 
// Create Date: 2026/11/22 12:14
// Design Name: immediate number extend unit for signle cycle cpu
// Module Name: imm_ext
// Project Name: digital-logic-homework
// Description: 
// 单周期处理器的立即数扩展单元，属于ID模块的子模块
// 与单元(ImmExt)组合形成ID模块
//
// Dependencies: defines.vh
// 
// Revision:
// - Revision 0.0.1: 2026/11/12
//      实现根据Immsrc进行符号位扩展，Immsrc编码规则遵循参考书P257
// Additional Comments:
// Immsrc编码规则：
//  00：I指令，01：S指令，10：B指令
//////////////////////////////////////////////////////////////////////////////////

module imm_ext (
    input [1:0] imm_src,
    input [31:7] instr_i,       
    output [31:0] imm_ext_o
);


    
endmodule