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
// immsrc出错后imm_ext_o归零
//
// Dependencies: defines.vh
// 
// Revision:
// - Revision 0.0.1: 2026/11/12
//      实现根据Immsrc进行符号位扩展，Immsrc编码规则遵循参考书P257
// Additional Comments:
// Immsrc编码规则详见defines.vh
// 
//////////////////////////////////////////////////////////////////////////////////

`include "defines.vh"
module imm_ext (
    input [2:0] imm_src,
    input [31:7] instr_i,       
    output reg [31:0] imm_ext_o
);

always @(*) begin
    case (imm_src)
    `IMMSRC_I: imm_ext_o = {{20{instr_i[31]}},instr_i[31:20]};
//  `IMMSRC_I_S: imm_ext_o = {{27'b0},instr_i[24:20]}; //special I-type instruction: slli, srli, srai.
//do not need, cause ALU only use least 5 bits
    `IMMSRC_S: imm_ext_o = {{20{instr_i[31]}},instr_i[31:25], instr_i[11:7]};
    `IMMSRC_B: imm_ext_o = {{20{instr_i[31]}}, instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};
    `IMMSRC_U: imm_ext_o = {instr_i[31:12], 12'b0};
    `IMMSRC_J: imm_ext_o = {{12{instr_i[31]}}, instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};
    default: imm_ext_o = 32'b0;
    endcase
end


endmodule