//=============================================================================
//  File    : mem_stage.v
//  Module  : mem_stage
//  Brief   : MEM + WB 两级子系统，封装 lsu / bus / dmem / wb_mux
//  Author  : 边思源
//  Rev     : 1.0                                          2026-11-23
//-----------------------------------------------------------------------------
//  数据通路
//    EX 输出的访存地址进入 lsu，转换成字地址、字节写使能与对齐后的写数据；
//    bus 按地址译码将请求分发到 dmem 或 mmio；读回数据经 wb_mux 选择后输出。
//
//  职责边界
//    - 本模块不产生控制信号（MemRead / MemWrite / RegWrite / wb_sel 由控制单元给出）
//    - 不实现寄存器堆（由 B 组提供），仅输出 wb_en / wb_rd / wb_data
//    - 不实现外设寄存器（由 B 组提供），仅输出 mmio_* 端口
//    - 不处理 x0 写入屏蔽，由寄存器堆负责
//
//  单周期版本：无 MEM/WB 流水线寄存器。
//=============================================================================
`timescale 1ns/1ps

module mem_stage #(
    parameter integer DMEM_WORDS = 1024,   // 数据存储器字数
    parameter         DMEM_INIT  = ""      // 数据存储器初始化文件
) (
    input  wire        clk,                // 时钟

    // EX 阶段输入
    input  wire [31:0] alu_result,         // 访存地址或运算结果
    input  wire [31:0] store_data,         // rs2 数据
    input  wire [2:0]  funct3,             // 指令 funct3
    input  wire        mem_read,           // load 指示
    input  wire        mem_write,          // store 指示
    input  wire [4:0]  rd,                 // 目标寄存器
    input  wire        reg_write,          // 寄存器写使能
    input  wire [31:0] pc_plus4,           // PC + 4
    input  wire [1:0]  wb_sel,             // 写回源选择

    // 写回接口（至寄存器堆）
    output wire        wb_en,
    output wire [4:0]  wb_rd,
    output wire [31:0] wb_data,

    // MMIO 接口（至外设）
    output wire [31:0] mmio_addr,
    output wire [31:0] mmio_wdata,
    output wire [3:0]  mmio_wstrb,
    output wire        mmio_we,
    output wire        mmio_re,
    input  wire [31:0] mmio_rdata
);

    // LSU <-> BUS
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [31:0] mem_rdata;
    wire [3:0]  mem_wstrb;
    wire [31:0] load_data;

    // BUS <-> DMEM
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire [31:0] dmem_rdata;
    wire [3:0]  dmem_wstrb;
    wire        dmem_we;

    //---------------------------------------------------------------------
    // LSU：地址转换与数据对齐
    //---------------------------------------------------------------------
    lsu u_lsu (
        .addr       (alu_result),
        .store_data (store_data),
        .funct3     (funct3),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .mem_addr   (mem_addr),
        .mem_wstrb  (mem_wstrb),
        .mem_wdata  (mem_wdata),
        .mem_rdata  (mem_rdata),
        .load_data  (load_data)
    );

    //---------------------------------------------------------------------
    // BUS：地址译码与请求分发
    //---------------------------------------------------------------------
    bus u_bus (
        .addr       (mem_addr),
        .wdata      (mem_wdata),
        .wstrb      (mem_wstrb),
        .we         (mem_write),
        .re         (mem_read),
        .rdata      (mem_rdata),
        .dmem_addr  (dmem_addr),
        .dmem_wdata (dmem_wdata),
        .dmem_wstrb (dmem_wstrb),
        .dmem_we    (dmem_we),
        .dmem_rdata (dmem_rdata),
        .mmio_addr  (mmio_addr),
        .mmio_wdata (mmio_wdata),
        .mmio_wstrb (mmio_wstrb),
        .mmio_we    (mmio_we),
        .mmio_re    (mmio_re),
        .mmio_rdata (mmio_rdata)
    );

    //---------------------------------------------------------------------
    // DMEM：数据存储器
    //---------------------------------------------------------------------
    dmem #(
        .WORDS     (DMEM_WORDS),
        .INIT_FILE (DMEM_INIT)
    ) u_dmem (
        .clk   (clk),
        .addr  (dmem_addr),
        .wdata (dmem_wdata),
        .wstrb (dmem_wstrb),
        .we    (dmem_we),
        .rdata (dmem_rdata)
    );

    //---------------------------------------------------------------------
    // WB：写回数据选择
    //---------------------------------------------------------------------
    wb_mux u_wb_mux (
        .alu_result (alu_result),
        .mem_data   (load_data),
        .pc_plus4   (pc_plus4),
        .wb_sel     (wb_sel),
        .wb_data    (wb_data)
    );

    //---------------------------------------------------------------------
    // 直通信号
    //---------------------------------------------------------------------
    assign wb_en = reg_write;
    assign wb_rd = rd;

endmodule
