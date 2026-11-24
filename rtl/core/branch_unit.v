`timescale 1ns/1ps
`include "defines.vh"
module branch_unit(
    input [31:0]rs1_data,
    input [31:0]rs2_data,
    input [2:0]branch_op,
    input is_branch,
    input jump,
    input jalr,
    input [31:0]pc,
    input [31:0]imm,
    output[31:0]target,
    output taken
);

wire [31:0]pc_plus_imm = pc + imm;
wire [31:0]rs1_plus_imm = rs1_data + imm;
wire is_eq = (rs1_data == rs2_data);
wire lt_u  = (rs1_data < rs2_data);
wire lt_s  = ($signed(rs1_data)<$signed(rs2_data));
reg cond;
always@(*)begin
    cond = 1'b0;
    case(branch_op)
    `BR_BEQ:if(is_eq) cond = 1'b1;
    `BR_BNE:if(!is_eq)cond =1'b1;
    `BR_BLT:if(lt_s) cond=1'b1;
    `BR_BGE:if(!lt_s) cond=1'b1;
    `BR_BLTU:if(lt_u) cond=1'b1;
    `BR_BGEU:if(!lt_u) cond=1'b1;
    default: cond = 1'b0;
    endcase
end
assign taken = jump | (cond & is_branch);
assign target = jalr ? (rs1_plus_imm & ~32'h1) : pc_plus_imm;
endmodule
