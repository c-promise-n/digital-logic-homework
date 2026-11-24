//=============================================================================
//  File    : lsu.v
//  Module  : lsu
//  Brief   : 访存单元，完成地址对齐、字节选通生成、写数据对齐与读数据扩展
//  Author  : 边思源
//  Rev     : 1.0                                          2026-11-23
//-----------------------------------------------------------------------------
//  funct3 编码
//    LOAD (opcode 0000011) : 000 LB  001 LH  010 LW  100 LBU  101 LHU
//    STORE(opcode 0100011) : 000 SB  001 SH  010 SW
//    funct3[1:0] : 00 -> 1 Byte, 01 -> 2 Byte, 10 -> 4 Byte
//    funct3[2]   : 1  -> 无符号，零扩展
//                  0  -> 有符号，符号扩展
//
//  输出关系
//    off       = addr[1:0]
//    mem_addr  = {addr[31:2], 2'b00}
//    mem_wstrb = ((1 << size) - 1) << off
//    mem_wdata = store_data << (8 * off)
//    load_data = extend(mem_rdata >> (8 * off))
//
//  约束
//    仅支持对齐访问：LW/SW 要求 off = 0，LH/SH 要求 off 属于 {0, 2}。
//    非对齐访问的行为未定义，本实现不做检查。
//
//  备注
//    mem_read / mem_write 在本模块内部不参与运算，仅向总线透传。
//    组合逻辑无副作用，读通路与写通路恒同时计算，由顶层控制信号选择。
//=============================================================================
`timescale 1ns/1ps

module lsu (
    input  wire [31:0] addr,         // 字节地址（ALU 输出）
    input  wire [31:0] store_data,   // rs2 数据
    input  wire [2:0]  funct3,       // 指令 funct3
    input  wire        mem_read,     // load 指示，透传至总线
    input  wire        mem_write,    // store 指示，透传至总线
    output wire [31:0] mem_addr,     // 字地址
    output wire [3:0]  mem_wstrb,    // 字节写使能
    output wire [31:0] mem_wdata,    // 对齐后的写数据
    input  wire [31:0] mem_rdata,    // 读回的一整字
    output reg  [31:0] load_data     // 扩展后的读数据
);

    wire [1:0] off = addr[1:0];

    assign mem_addr = {addr[31:2], 2'b00};

    // 目标字段右移到最低位，供读通路统一处理
    wire [31:0] shifted = mem_rdata >> (8 * off);

    // 字节写使能：宽度由 funct3[1:0] 决定，再按 off 平移
    //   funct3[1:0] 对 load / store 通用：
    //     LB=000 与 LBU=100 的低两位均为 00 -> 1 字节
    //     LH=001 与 LHU=101 的低两位均为 01 -> 2 字节
    assign mem_wstrb = (funct3[1:0] == 2'b10) ? 4'b1111           :
                       (funct3[1:0] == 2'b01) ? (4'b0011 << off) :
                                                (4'b0001 << off) ;

    // 写数据与写选通保持同字节位置
    assign mem_wdata = store_data << (8 * off);

    // 读数据扩展
    always @(*) begin
        case (funct3)
            3'b000:  load_data = {{24{shifted[7]}},  shifted[7:0]};   // LB
            3'b100:  load_data = {24'b0,             shifted[7:0]};   // LBU
            3'b001:  load_data = {{16{shifted[15]}}, shifted[15:0]};  // LH
            3'b101:  load_data = {16'b0,             shifted[15:0]};  // LHU
            3'b010:  load_data = mem_rdata;                           // LW
            default: load_data = 32'b0;                               // 未定义编码
        endcase
    end

endmodule
