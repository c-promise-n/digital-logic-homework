`timescale 1ns/1ps
`include "defines.vh"
module forward_mux(
input [31:0]id_ex_rs1_data,
input [31:0]id_ex_rs2_data,
input [31:0]ex_mem_alu_result,
input [31:0]mem_wb_wdata,
input [1:0]forward_rs1,
input [1:0]forward_rs2,
input [1:0]forward_store,

input ctrl_alu_sel_pc,//1=pc
input [31:0]id_ex_pc,
input ctrl_alu_sel_imm,//1=imm
input [31:0]id_ex_imm,

output reg[31:0]ex_rs1_fwd,
output reg[31:0]ex_rs2_fwd,
output [31:0]ex_alu_a,
output [31:0]ex_alu_b,
output reg[31:0]ex_store_data

);

always@(*)begin
    case(forward_rs1)
    `FWD_NONE:ex_rs1_fwd=id_ex_rs1_data;
    `FWD_EX_MEM:ex_rs1_fwd=ex_mem_alu_result;
    `FWD_MEM_WB:ex_rs1_fwd=mem_wb_wdata;
    default:ex_rs1_fwd=id_ex_rs1_data;
    endcase

    case(forward_rs2)
    `FWD_NONE:ex_rs2_fwd=id_ex_rs2_data;
    `FWD_EX_MEM:ex_rs2_fwd=ex_mem_alu_result;
    `FWD_MEM_WB:ex_rs2_fwd=mem_wb_wdata;
    default:ex_rs2_fwd=id_ex_rs2_data;
    endcase

    case(forward_store)
    `FWD_NONE:ex_store_data=id_ex_rs2_data;
    `FWD_EX_MEM:ex_store_data=ex_mem_alu_result;
    `FWD_MEM_WB:ex_store_data=mem_wb_wdata;
    default:ex_store_data=id_ex_rs2_data;
    endcase

end
assign ex_alu_a = ctrl_alu_sel_pc ? id_ex_pc : ex_rs1_fwd;
assign ex_alu_b = ctrl_alu_sel_imm ? id_ex_imm : ex_rs2_fwd;

endmodule
