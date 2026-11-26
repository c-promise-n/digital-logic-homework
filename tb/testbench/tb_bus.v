//=============================================================================
//  File    : tb_bus.v
//  Module  : tb_bus
//  Brief   : bus 单元测试，覆盖地址译码、写使能门控、读数据汇总与未映射地址
//  Author  : 边思源
//  Rev     : 1.0                                          2026-11-23
//-----------------------------------------------------------------------------
//  从设备 1：dmem（真实模块）
//  从设备 2：tb 内的寄存器模型，模拟 MMIO 从设备
//=============================================================================
`timescale 1ns/1ps

module tb_bus;

    reg clk = 0;
    always #5 clk = ~clk;

    reg  [31:0] addr, wdata;
    reg  [3:0]  wstrb;
    reg         we, re;

    wire [31:0] rdata;

    wire [31:0] dmem_addr, dmem_wdata, dmem_rdata;
    wire [3:0]  dmem_wstrb;
    wire        dmem_we;

    wire [31:0] mmio_addr, mmio_wdata, mmio_rdata;
    wire [3:0]  mmio_wstrb;
    wire        mmio_we, mmio_re;

    bus u_bus (
        .addr(addr), .wdata(wdata), .wstrb(wstrb), .we(we), .re(re),
        .rdata(rdata),
        .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata),
        .dmem_wstrb(dmem_wstrb), .dmem_we(dmem_we), .dmem_rdata(dmem_rdata),
        .mmio_addr(mmio_addr), .mmio_wdata(mmio_wdata),
        .mmio_wstrb(mmio_wstrb), .mmio_we(mmio_we), .mmio_re(mmio_re),
        .mmio_rdata(mmio_rdata)
    );

    dmem #(.WORDS(1024)) u_dmem (
        .clk(clk), .addr(dmem_addr), .wdata(dmem_wdata),
        .wstrb(dmem_wstrb), .we(dmem_we), .rdata(dmem_rdata)
    );

    // MMIO 从设备模型
    reg [31:0] mmio_reg [0:3];
    integer i;
    initial for (i = 0; i < 4; i = i + 1) mmio_reg[i] = 32'h0;

    always @(posedge clk) begin
        if (mmio_we) mmio_reg[mmio_addr[3:2]] <= mmio_wdata;
    end
    assign mmio_rdata = mmio_reg[mmio_addr[3:2]];

    integer errors = 0;

    task chk32(input [31:0] got, input [31:0] exp);
        begin
            if (got !== exp) begin
                errors = errors + 1;
                $display("    FAIL  got=%08h  exp=%08h", got, exp);
            end else
                $display("    ok    %08h", got);
        end
    endtask

    task chk1(input got, input exp);
        begin
            if (got !== exp) begin
                errors = errors + 1;
                $display("    FAIL  got=%b  exp=%b", got, exp);
            end else
                $display("    ok    %b", got);
        end
    endtask

    task wr(input [31:0] a, input [31:0] d);
        begin addr = a; wdata = d; wstrb = 4'hF; we = 1; re = 0; #1; end
    endtask

    task rd(input [31:0] a);
        begin addr = a; wdata = 0; wstrb = 0; we = 0; re = 1; #1; end
    endtask

    initial begin
        addr = 0; wdata = 0; wstrb = 0; we = 0; re = 0;
        $display("=== tb_bus start ===");

        //-----------------------------------------------------------------
        $display("case1: store 0xDEADBEEF @0x100 -> only DMEM");
        wr(32'h100, 32'hDEADBEEF);
        chk1(dmem_we, 1'b1);
        chk1(mmio_we, 1'b0);
        chk32(dmem_addr, 32'h100);
        @(posedge clk); #1;
        rd(32'h100);
        chk1(dmem_we, 1'b0);
        chk32(rdata, 32'hDEADBEEF);

        //-----------------------------------------------------------------
        $display("case2: store 0xA5A5_5A5A @0x8000_2008 -> only MMIO");
        wr(32'h8000_2008, 32'hA5A5_5A5A);
        chk1(mmio_we, 1'b1);
        chk1(dmem_we, 1'b0);
        chk32(mmio_addr, 32'h8000_2008);
        chk1(mmio_re, 1'b0);
        @(posedge clk); #1;
        rd(32'h8000_2008);
        chk1(mmio_re, 1'b1);
        chk32(rdata, 32'hA5A5_5A5A);

        //-----------------------------------------------------------------
        $display("case3: unmapped 0xC000_0000 -> rdata=0, no write strobe");
        wr(32'hC000_0000, 32'hFFFF_FFFF);
        chk1(dmem_we, 1'b0);
        chk1(mmio_we, 1'b0);
        rd(32'hC000_0000);
        chk32(rdata, 32'h0000_0000);

        //-----------------------------------------------------------------
        $display("case4: 4KB boundary 0x0FFC hits DMEM, 0x1000 does not");
        wr(32'h0FFC, 32'h1234_5678);
        chk1(dmem_we, 1'b1);
        @(posedge clk); #1;
        rd(32'h0FFC);
        chk32(rdata, 32'h1234_5678);

        wr(32'h1000, 32'h9999_9999);
        chk1(dmem_we, 1'b0);
        chk1(mmio_we, 1'b0);
        rd(32'h1000);
        chk32(rdata, 32'h0000_0000);

        //-----------------------------------------------------------------
        $display("case5: byte store to MMIO, wstrb must pass through");
        addr = 32'h8000_2004; wdata = 32'h0000_00AB; wstrb = 4'b0001; we = 1; re = 0; #1;
        chk1(mmio_we, 1'b1);
        chk32(mmio_wstrb, {28'b0, 4'b0001});
        chk32(mmio_wdata, 32'h0000_00AB);

        //-----------------------------------------------------------------
        $display("=== %0d errors ===", errors);
        if (errors == 0) begin
            $display("PASS tb_bus");
            $finish;
        end else begin
            $display("FAIL tb_bus");
            $fatal(1);
        end
    end

endmodule
