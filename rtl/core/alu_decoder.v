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
    input [6:0] func7_5,
    input [1:0] alu_op,
    output reg [3:0] alu_control,
    output reg illegal_func //active high
);

wire is_Rsub;               // if input is R-tpye sub, or branch type, active
assign is_Rsub = op_5 & func7_5;

always @(*) begin
    case(alu_op)
    `ALU_OP_ADD: begin
        alu_control = `ALU_ADD;
        illegal_func = 1'b0;
    end

    `ALU_OP_PASSB: begin 
        alu_control = `ALU_PASS_B;
        illegal_func = 1'b0;
    end

    `ALU_OP_OP: begin
        case (func3)

        3'b000: begin
        if (is_Rsub)
            alu_control = `ALU_SUB;
        else
            alu_control = `ALU_ADD;

        illegal_func = 1'b0;
        end

        3'b001: begin 
            alu_control = `ALU_SLL;
            illegal_func = 1'b0;
        end

        3'b010: begin 
            alu_control = `ALU_SLT;
            illegal_func = 1'b0;
        end

        3'b011: begin 
            alu_control = `ALU_SLTU;
            illegal_func = 1'b0;
        end

        3'b100: begin 
            alu_control = `ALU_XOR;
            illegal_func = 1'b0;
        end

        3'b101: begin
            if (func7_5)
                alu_control = `ALU_SRA;
            else
                alu_control = `ALU_SRL;

            illegal_func = 1'b0;
        end

        3'b110: begin
            alu_control = `ALU_OR;
            illegal_func = 1'b0;
        end

        3'b111: begin 
            alu_control = `ALU_AND;
            illegal_func = 1'b0;
        end

        default: begin 
            alu_control = `ALU_PASS_B;
            illegal_func = 1'b1;
        end
        endcase
    end
    default: begin 
        alu_control = `ALU_PASS_B;
        illegal_func = 1'b1;
    end
    endcase
end
endmodule