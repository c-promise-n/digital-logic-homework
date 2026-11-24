//=============================================================================
//  File    : wb_mux.v
//  Module  : wb_mux
//  Brief   : 写回数据选择器
//  Author  : 边思源
//  Rev     : 1.0                                          2026-11-23
//-----------------------------------------------------------------------------
//  写回源
//    wb_sel = 00 : alu_result   算术/逻辑/移位/比较/lui/auipc
//    wb_sel = 01 : mem_data     所有 load（LB/LH/LW/LBU/LHU）
//    wb_sel = 10 : pc_plus4     JAL / JALR 的返回地址
//    wb_sel = 11 : 保留，输出 0
//
//  说明
//    JAL / JALR 写回的是调用点的下一条指令地址（pc + 4），既不是 ALU 结果
//    也不是存储器数据，因此写回通路必须有三路数据源。
//    store 与 branch 的 RegWrite 为 0，wb_sel 为无关项，控制单元建议给 00。
//    本模块为纯组合逻辑。
//=============================================================================
`timescale 1ns/1ps

module wb_mux (
    input  wire [31:0] alu_result,   // ALU 结果
    input  wire [31:0] mem_data,     // LSU 读出的数据（已扩展）
    input  wire [31:0] pc_plus4,     // PC + 4
    input  wire [1:0]  wb_sel,       // 写回源选择
    output reg  [31:0] wb_data       // 写回数据
);

    always @(*) begin
        case (wb_sel)
            2'b00:   wb_data = alu_result;
            2'b01:   wb_data = mem_data;
            2'b10:   wb_data = pc_plus4;
            default: wb_data = 32'b0;
        endcase
    end

endmodule
