//////////////////////////////////////////////////////////////////////////////////
// Engineer: Pinfeng_Song
// 
// Create Date: 2026/11/22 20:06
// Design Name: alu decoer for control_unit module
// Module Name: alu_decoder
// Project Name: digital-logic-homework
// Description: 
// ID模块的子模块，ID的ALU译码器
//
// Dependencies: defines.vh
// 
// Revision:
// - Revision 0.0.1: 2026/11/25
//      根据参考书P294和P259实现ALU译码器, func7 仅取第5位
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`include "defines.vh"
module alu_decoder (
    input op_5,             //第六位op[5]，用于判断是否为sub指令
    input [2:0] func3,
    input func7_5,
    input [1:0] alu_op,
    output reg [3:0] alu_control
);

wire is_Rsub;               // if input is R-tpye sub, or branch type, active
assign is_Rsub = (alu_op == 2'b01)? 1'b0: op_5 & func7_5;

wire func3_r;
assign func3_r = (alu_op == 2'b01)? {1'b0,func3[2:1]} : func3;
always @(*) begin
    case(alu_op)
    2'b00: alu_control = `ALU_ADD;
    2'b11: alu_control = `ALU_PASS_B;
    2'b01, 2'b10: begin
        case (func3_r)
        3'b000: begin
        if (is_Rsub)
        alu_control = `ALU_SUB;
        else
        alu_control = `ALU_ADD;
        end
        3'b001: alu_control = `ALU_SLL;
        3'b010: alu_control = `ALU_SLT;
        3'b011: alu_control = `ALU_SLTU;
        3'b100: alu_control = `ALU_XOR;
        3'b101: begin
            if (func7_5)
                alu_control = `ALU_SRA;
            else
                alu_control = `ALU_SRL;
        end
        3'b110: alu_control = `ALU_OR;
        3'b111: alu_control = `ALU_AND;
        endcase
    end
    endcase
end
endmodule