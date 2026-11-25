//=============================================================================
//  File    : tb_lsu.v
//  Module  : tb_lsu
//  Brief   : lsu 单元测试，覆盖字/半字/字节读写、大小端、符号与零扩展
//  Author  : 边思源
//  Rev     : 1.0                                          2026-11-23
//-----------------------------------------------------------------------------
//  运行：scripts/sim.bat
//  判定：输出 "0 errors" 与 "PASS tb_lsu"
//  说明：wdata 仅校验 wstrb 选中的字节，其余字节为无关项。
//=============================================================================
`timescale 1ns/1ps

module tb_lsu;

    reg clk = 0;
    always #5 clk = ~clk;

    reg  [31:0] addr, store_data;
    reg  [2:0]  funct3;
    reg         mem_read, mem_write;

    wire [31:0] mem_addr, mem_wdata, mem_rdata, load_data;
    wire [3:0]  mem_wstrb;

    // 本测试中 LSU 直连 dmem，总线由 tb_bus 单独验证
    dmem #(.WORDS(256)) u_dmem (
        .clk(clk), .addr(mem_addr), .wdata(mem_wdata),
        .wstrb(mem_wstrb), .we(mem_write), .rdata(mem_rdata)
    );

    lsu u_lsu (
        .addr(addr), .store_data(store_data), .funct3(funct3),
        .mem_read(mem_read), .mem_write(mem_write),
        .mem_addr(mem_addr), .mem_wstrb(mem_wstrb),
        .mem_wdata(mem_wdata), .mem_rdata(mem_rdata),
        .load_data(load_data)
    );

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

    // 仅比较 mask 为 1 的字节
    task chkm(input [31:0] got, input [31:0] exp, input [31:0] mask);
        begin
            if ((got & mask) !== (exp & mask)) begin
                errors = errors + 1;
                $display("    FAIL  got=%08h  exp=%08h  mask=%08h", got, exp, mask);
            end else
                $display("    ok    %08h (mask %08h)", got, mask);
        end
    endtask

    task chk4(input [3:0] got, input [3:0] exp);
        begin
            if (got !== exp) begin
                errors = errors + 1;
                $display("    FAIL  got=%b  exp=%b", got, exp);
            end else
                $display("    ok    %b", got);
        end
    endtask

    task wr(input [31:0] a, input [31:0] d, input [2:0] f);
        begin addr = a; store_data = d; funct3 = f; mem_read = 0; mem_write = 1; #1; end
    endtask

    task rd(input [31:0] a, input [2:0] f);
        begin addr = a; store_data = 0; funct3 = f; mem_read = 1; mem_write = 0; #1; end
    endtask

    initial begin
        addr = 0; store_data = 0; funct3 = 0; mem_read = 0; mem_write = 0;
        $display("=== tb_lsu start ===");

        //-----------------------------------------------------------------
        $display("case1: sw 0xDEADBEEF @0x100, then lw");
        wr(32'h100, 32'hDEADBEEF, 3'b010);
        chk4 (mem_wstrb, 4'b1111);
        chk32(mem_wdata, 32'hDEADBEEF);
        @(posedge clk); #1;
        rd(32'h100, 3'b010);
        chk32(load_data, 32'hDEADBEEF);

        //-----------------------------------------------------------------
        $display("case2: sb 0x80 @0x104 (off=0), then lb / lbu");
        wr(32'h104, 32'h0000_0080, 3'b000);
        chk4 (mem_wstrb, 4'b0001);
        chkm (mem_wdata, 32'h0000_0080, 32'h0000_00FF);
        @(posedge clk); #1;
        rd(32'h104, 3'b000);
        chk32(load_data, 32'hFFFF_FF80);
        rd(32'h104, 3'b100);
        chk32(load_data, 32'h0000_0080);

        //-----------------------------------------------------------------
        $display("case3: sb 0x12 @0x106 (off=2), wstrb must be 0100");
        wr(32'h106, 32'h0000_0012, 3'b000);
        chk4 (mem_wstrb, 4'b0100);
        chkm (mem_wdata, 32'h0012_0000, 32'h00FF_0000);
        @(posedge clk); #1;
        rd(32'h106, 3'b001);
        chk32(load_data, 32'h0000_0012);
        rd(32'h106, 3'b101);
        chk32(load_data, 32'h0000_0012);

        //-----------------------------------------------------------------
        $display("case4: sh 0xABCD @0x108 (off=0), then lh / lhu");
        wr(32'h108, 32'h0000_ABCD, 3'b001);
        chk4 (mem_wstrb, 4'b0011);
        chkm (mem_wdata, 32'h0000_ABCD, 32'h0000_FFFF);
        @(posedge clk); #1;
        rd(32'h108, 3'b001);
        chk32(load_data, 32'hFFFF_ABCD);
        rd(32'h108, 3'b101);
        chk32(load_data, 32'h0000_ABCD);

        //-----------------------------------------------------------------
        $display("case5: 4x sb @0x10C..0x10F, then lw (little endian)");
        wr(32'h10C, 32'h0000_0011, 3'b000);
        chk4 (mem_wstrb, 4'b0001);
        chkm (mem_wdata, 32'h0000_0011, 32'h0000_00FF);
        @(posedge clk); #1;
        wr(32'h10D, 32'h0000_0022, 3'b000);
        chk4 (mem_wstrb, 4'b0010);
        chkm (mem_wdata, 32'h0000_2200, 32'h0000_FF00);
        @(posedge clk); #1;
        wr(32'h10E, 32'h0000_0033, 3'b000);
        chk4 (mem_wstrb, 4'b0100);
        chkm (mem_wdata, 32'h0033_0000, 32'h00FF_0000);
        @(posedge clk); #1;
        wr(32'h10F, 32'h0000_0044, 3'b000);
        chk4 (mem_wstrb, 4'b1000);
        chkm (mem_wdata, 32'h4400_0000, 32'hFF00_0000);
        @(posedge clk); #1;
        rd(32'h10C, 3'b010);
        chk32(load_data, 32'h4433_2211);

        //-----------------------------------------------------------------
        $display("=== %0d errors ===", errors);
        if (errors == 0) begin
            $display("PASS tb_lsu");
            $finish;
        end else begin
            $display("FAIL tb_lsu");
            $fatal(1);
        end
    end

endmodule
