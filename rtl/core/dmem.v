//=============================================================================
//  File    : dmem.v
//  Module  : dmem
//  Brief   : 数据存储器，异步读 / 同步写，字节粒度写使能
//  Author  : 边思源
//  Rev     : 1.0                                          2026-11-23
//-----------------------------------------------------------------------------
//  实现说明
//    1. 读口为组合读，保证单周期 CPU 在同一周期内取数。Vivado 综合为
//       LUTRAM，1024 x 32 bit 约占 512 个 LUT（每 64 bit 占用 1 个 LUT）。
//    2. 写口为字节粒度：wstrb[i] 控制 mem[word][8*i +: 8] 是否更新。
//    3. 若改为同步读（BRAM），读数据延迟一拍，需要流水线配合。
//    4. 容量 4 KB，地址索引仅使用 addr[11:2]。
//=============================================================================
`timescale 1ns/1ps

module dmem #(
    parameter integer WORDS     = 1024,   // 存储器字数
    parameter         INIT_FILE = ""      // 初始化文件（$readmemh 格式）
) (
    input  wire        clk,               // 时钟
    input  wire [31:0] addr,              // 字节地址，仅 [11:2] 参与索引
    input  wire [31:0] wdata,             // 写数据
    input  wire [3:0]  wstrb,             // 字节写使能
    input  wire        we,                // 写使能
    output wire [31:0] rdata              // 读数据
);

    reg [31:0] mem [0:WORDS-1];

    // 异步读：地址变化后当拍输出
    assign rdata = mem[addr[11:2]];

    // 同步写：字节粒度
    always @(posedge clk) begin
        if (we) begin
            if (wstrb[0]) mem[addr[11:2]][ 7: 0] <= wdata[ 7: 0];
            if (wstrb[1]) mem[addr[11:2]][15: 8] <= wdata[15: 8];
            if (wstrb[2]) mem[addr[11:2]][23:16] <= wdata[23:16];
            if (wstrb[3]) mem[addr[11:2]][31:24] <= wdata[31:24];
        end
    end

    // 初值：综合时映射为 RAM 初始化
    integer i;
    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end else begin
            for (i = 0; i < WORDS; i = i + 1) mem[i] = 32'h0000_0000;
        end
    end

endmodule
