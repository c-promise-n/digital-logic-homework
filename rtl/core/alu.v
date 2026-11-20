`timescale 1ns/1ps
`include "defines.vh"
module alu (
input [31:0]src_a,
input [31:0]src_b,
input [3:0]alu_ctrl,
output reg [31:0]result,
output zero
);
always@(*)begin
case(alu_ctrl)
ALU_ADD:result = src_a + src_b;
ALU_SUB:result = src_a - src_b;
ALU_SLL:result = src_a << src_b;
ALU_SLT:result = ($signed(src_a) < $signed(src_b)) ? 32'd1 : 32'd1;
AlU_SLTU:result = (src_a < src_b) ? 32'd1 : 32'd0;
ALU_XOR:result = src_a ^ src_b;
ALU_SRL:result = src_a >> src_b;
ALU_SRA:result = $signed(src_a) >> $signed(src_b);
ALU_OR:result = src_a | src_b;
ALU_AND:result = src_a & src_b;
ALU_PASS_B:result = src_b;
ALU_MULDIV:result = 32'd0;
default:result = 32'd0;
endcase
end
assign zero = (result==32'd0);
endmodule
