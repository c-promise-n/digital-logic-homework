//=============================================================================
//  File    : tb_wb_mux.v
//  Module  : tb_wb_mux
//  Brief   : wb_mux 单元测试，覆盖三路选择、保留编码与通道隔离
//  Author  : 边思源
//  Rev     : 1.0                                          2026-11-23
//-----------------------------------------------------------------------------
//  通道隔离测试用于排除"多个数据源被逻辑合并"一类错误：
//  选中某一路时，其余两路的变化不得影响输出。
//=============================================================================
`timescale 1ns/1ps

module tb_wb_mux;

    reg  [31:0] alu_result, mem_data, pc_plus4;
    reg  [1:0]  wb_sel;
    wire [31:0] wb_data;

    wb_mux u_wb (
        .alu_result(alu_result),
        .mem_data  (mem_data),
        .pc_plus4  (pc_plus4),
        .wb_sel    (wb_sel),
        .wb_data   (wb_data)
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

    task set_src(input [31:0] a, input [31:0] m, input [31:0] p);
        begin alu_result = a; mem_data = m; pc_plus4 = p; #1; end
    endtask

    initial begin
        alu_result = 32'h0; mem_data = 32'h0; pc_plus4 = 32'h0; wb_sel = 2'b00;

        $display("=== tb_wb_mux start ===");

        //-----------------------------------------------------------------
        $display("case1: select each source");
        set_src(32'hAAAA_0001, 32'hBBBB_0002, 32'hCCCC_0003);

        wb_sel = 2'b00; #1;
        chk32(wb_data, 32'hAAAA_0001);

        wb_sel = 2'b01; #1;
        chk32(wb_data, 32'hBBBB_0002);

        wb_sel = 2'b10; #1;
        chk32(wb_data, 32'hCCCC_0003);

        //-----------------------------------------------------------------
        $display("case2: wb_sel=11 reserved, output must be 0");
        wb_sel = 2'b11; #1;
        chk32(wb_data, 32'h0000_0000);

        //-----------------------------------------------------------------
        $display("case3: isolation, ALU selected while others toggle");
        wb_sel = 2'b00;
        alu_result = 32'h1234_5678; mem_data = 32'hDEAD_BEEF; pc_plus4 = 32'hFFFF_FFFF; #1;
        chk32(wb_data, 32'h1234_5678);
        mem_data = 32'h0000_0000; pc_plus4 = 32'h0000_0000; #1;
        chk32(wb_data, 32'h1234_5678);

        $display("case4: isolation, MEM selected while others toggle");
        wb_sel = 2'b01;
        mem_data = 32'h0BAD_F00D; #1;
        chk32(wb_data, 32'h0BAD_F00D);
        alu_result = 32'h9999_9999; pc_plus4 = 32'h8888_8888; #1;
        chk32(wb_data, 32'h0BAD_F00D);

        //-----------------------------------------------------------------
        $display("case5: JAL scenario, return address must be pc+4");
        alu_result = 32'h0000_0108;      // 跳转目标
        pc_plus4   = 32'h0000_0104;      // 返回地址
        wb_sel     = 2'b10; #1;
        chk32(wb_data, 32'h0000_0104);

        //-----------------------------------------------------------------
        $display("=== %0d errors ===", errors);
        if (errors == 0) begin
            $display("PASS tb_wb_mux");
            $finish;
        end else begin
            $display("FAIL tb_wb_mux");
            $fatal(1);
        end
    end

endmodule
