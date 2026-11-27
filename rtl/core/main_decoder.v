//////////////////////////////////////////////////////////////////////////////////
// Engineer: Pinfeng_Song
// 
// Create Date: 2026/11/22 12:14
// Design Name: main decoer for control_unit module
// Module Name: main_decoder
// Project Name: digital-logic-homework
// Description: 
// ID模块的子模块，ID的主译码器
//
// Dependencies: defines.vh
// 
// Revision:
// - Revision 0.0.1: 2026/11/12
//      根据参考书P294和P259实现主译码器,imm_src采用三位，为了适配I,S,B,U,J五种指令
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`include "defines.vh"
module main_decoder (
    input [6:0] op,
    
    output reg branch,      //active high
    output reg [1:0] result_src,
    // 00: ALU result
    // 01: Read Data
    // 11: PC plus 4
    output reg mem_write,   //active high
    output reg alu_srcA,    //1'b1:choose pc, 1'b0: choose rd1
    output reg alu_srcB,    //1'b1:choose immext, 1'b0: choose rd2
    output reg [2:0] imm_src,//refer to defines.vh
    output reg reg_write,   //active high
    output reg [1:0] alu_op,
    //same as book P260
    //00: add, do NOT consider func3 and func7
    //01: branch instru, use func3[2:1] and func[0]
    //10: op and opim instru, consider func3 and func7
    //11: pass B
    output reg lsu_read,    //active high, control lsu mode
    output reg lsu_write,   //active high, control lsu mode
    output reg jump,        //active high. if JAL or JALR, active
    output reg pctarget_src //active high. 1'b0:pc, 1'b1:RD1(最低位置0).
);
    always @(*) begin
        case (op)
        `INST_LOAD: begin
            branch = 1'b0;
            result_src = 2'b01;
            mem_write = 1'b0;
            alu_srcA = 1'b0;
            alu_srcB = 1'b1;
            imm_src = `IMMSRC_I;
            reg_write = 1'b1;
            alu_op = 2'b00;
            lsu_read = 1'b1;
            lsu_write = 1'b0;
            jump = 1'b0;
            pctarget_src = 1'b0;
        end
        `INST_OP_IMM: begin
            branch = 1'b0;
            result_src = 2'b00;
            mem_write= 1'b0;
            alu_srcA = 1'b0;
            alu_srcB = 1'b1;
            imm_src = `IMMSRC_I;
            reg_write = 1'b1;
            alu_op = 2'b10;
            lsu_read = 1'b0;
            lsu_write = 1'b0;
            jump = 1'b0;
            pctarget_src = 1'b0;
        end
        `INST_AUIPC: begin
            branch = 1'b0;
            result_src = 2'b00;
            mem_write = 1'b0;
            alu_srcA = 1'b1;
            alu_srcB = 1'b1;
            imm_src = `IMMSRC_U;
            reg_write = 1'b1;
            alu_op = 2'b00;
            lsu_read = 1'b0;
            lsu_write = 1'b0;
            jump = 1'b0;
            pctarget_src = 1'b0;
        end
        `INST_STORE: begin
            branch = 1'b0;
            result_src = 2'b00;
            mem_write = 1'b1;
            alu_srcA = 1'b0;
            alu_srcB = 1'b1;
            imm_src = `IMMSRC_S;
            reg_write = 1'b0;
            alu_op = 2'b00;
            lsu_read = 1'b0;
            lsu_write = 1'b1;
            jump = 1'b0;
            pctarget_src = 1'b0;
        end
        `INST_OP: begin
            branch = 1'b0;
            result_src = 2'b00;
            mem_write = 1'b0;
            alu_srcA = 1'b0;
            alu_srcB = 1'b0;
            imm_src = `IMMSRC_X;
            reg_write = 1'b1;
            alu_op = 2'b10;
            lsu_read = 1'b0;
            lsu_write = 1'b0;
            jump = 1'b0;
            pctarget_src = 1'b0;
        end
        `INST_LUI: begin
            branch = 1'b0;
            result_src = 2'b00;
            mem_write = 1'b0;
            alu_srcA = 1'b0;
            alu_srcB = 1'b1;
            imm_src = `IMMSRC_U;
            reg_write = 1'b1;
            alu_op = 2'b11;
            lsu_read = 1'b0;
            lsu_write = 1'b0;
            jump = 1'b0;
            pctarget_src = 1'b0;
        end
        `INST_BRANCH: begin
            branch = 1'b1;
            result_src = 2'b00;
            mem_write = 1'b0;
            alu_srcA = 1'b0;
            alu_srcB = 1'b0;
            imm_src = `IMMSRC_B;
            reg_write = 1'b0;
            alu_op = 2'b01;
            lsu_read = 1'b0;
            lsu_write = 1'b0;
            jump = 1'b0;
            pctarget_src = 1'b0;
        end
        `INST_JALR: begin
            branch = 1'b0;
            result_src = 2'b10;
            mem_write = 1'b0;
            alu_srcA = 1'b0;
            alu_srcB = 1'b1;
            imm_src = `IMMSRC_I;
            reg_write = 1'b1;
            alu_op = 2'b00;
            lsu_read = 1'b0;
            lsu_write = 1'b0;
            jump = 1'b1;
            pctarget_src = 1'b1;
        end
        `INST_JAL: begin
            branch = 1'b0;
            result_src = 2'b10;
            mem_write = 1'b0;
            alu_srcA = 1'b0;
            alu_srcB = 1'b0;
            imm_src = `IMMSRC_J;
            reg_write = 1'b1;
            alu_op = 2'b00;
            lsu_read = 1'b0;
            lsu_write = 1'b0;
            jump = 1'b1;
            pctarget_src = 1'b0;
        end
        endcase
    end
endmodule