//=============================================================================
//  File    : bus.v
//  Module  : bus
//  Brief   : 存储器映射总线，完成地址译码、读写请求分发与读数据汇总
//  Author  : 边思源
//  Rev     : 1.0                                          2026-11-23
//-----------------------------------------------------------------------------
//  地址映射
//    0x0000_0000 - 0x0000_0FFF   DMEM    4 KB  窗口
//    0x8000_0000 - 0x8000_FFFF   MMIO   64 KB  窗口
//      0x8000_0000  UART TX
//      0x8000_0004  UART RX / status
//      0x8000_1000  timer mtime
//      0x8000_1004  timer mtimecmp
//      0x8000_2000  SW[15:0]
//      0x8000_2004  七段数码管
//      0x8000_2008  LED[15:0]
//    其余地址为未映射：读回 0，写丢弃。
//
//  设计要点
//    1. 译码采用掩码比较：(addr & MASK) == BASE。
//       窗口为 2^n 字节时，掩码低 n 位为 0。
//    2. 从设备写使能必须与片选相与，避免一次写操作被广播到所有从设备。
//    3. 读数据由多路选择器汇总；未命中任何从设备时返回 0，防止 X 传播。
//=============================================================================
`timescale 1ns/1ps

module bus (
    // 主设备接口
    input  wire [31:0] addr,        // 字节地址
    input  wire [31:0] wdata,       // 写数据
    input  wire [3:0]  wstrb,       // 字节写使能
    input  wire        we,          // 写使能
    input  wire        re,          // 读使能
    output reg  [31:0] rdata,       // 读数据

    // 从设备 1：数据存储器
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    output wire [3:0]  dmem_wstrb,
    output wire        dmem_we,
    input  wire [31:0] dmem_rdata,

    // 从设备 2：MMIO 外设
    output wire [31:0] mmio_addr,
    output wire [31:0] mmio_wdata,
    output wire [3:0]  mmio_wstrb,
    output wire        mmio_we,
    output wire        mmio_re,
    input  wire [31:0] mmio_rdata
);

    localparam [31:0] DMEM_BASE = 32'h0000_0000;
    localparam [31:0] MMIO_BASE = 32'h8000_0000;
    localparam [31:0] DMEM_MASK = 32'hFFFF_F000;   // 4 KB
    localparam [31:0] MMIO_MASK = 32'hFFFF_0000;   // 64 KB

    // 片选
    wire sel_dmem = ((addr & DMEM_MASK) == DMEM_BASE);
    wire sel_mmio = ((addr & MMIO_MASK) == MMIO_BASE);

    // 写通路：地址与数据广播，写使能门控
    assign dmem_addr  = {addr[31:2], 2'b00};
    assign dmem_wdata = wdata;
    assign dmem_wstrb = wstrb;
    assign dmem_we    = we && sel_dmem;

    assign mmio_addr  = {addr[31:2], 2'b00};
    assign mmio_wdata = wdata;
    assign mmio_wstrb = wstrb;
    assign mmio_we    = we && sel_mmio;
    assign mmio_re    = re && sel_mmio;

    // 读通路：多路选择
    always @(*) begin
        if (sel_dmem)
            rdata = dmem_rdata;
        else if (sel_mmio)
            rdata = mmio_rdata;
        else
            rdata = 32'b0;
    end

endmodule
