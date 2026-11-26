//=============================================================================
//  File    : tb_mem_stage.v
//  Module  : tb_mem_stage
//  Brief   : mem_stage 指令级集成测试，模拟 EX 阶段输出驱动 MEM+WB
//  Author  : 边思源
//  Rev     : 1.0                                          2026-11-23
//-----------------------------------------------------------------------------
//  每个 case 对应一条真实指令在 EX 阶段的输出组合：
//    sw  : alu_result=地址, store_data=rs2, funct3=010, mem_write=1
//    lw  : alu_result=地址, funct3=010, mem_read=1, rd, wb_sel=01
//    jal : alu_result=跳转目标, pc_plus4=返回地址, wb_sel=10
//
//  本测试不依赖 A/B 组模块，可独立验证 MEM 与 WB 两级。
//  tb 中使用层次化引用（u_mem.dmem_we）观察内部信号，仅用于仿真。
//=============================================================================
`timescale 1ns/1ps

module tb_mem_stage;

    reg clk = 0;
    always #5 clk = ~clk;

    reg  [31:0] alu_result, store_data, pc_plus4;
    reg  [2:0]  funct3;
    reg         mem_read, mem_write, reg_write;
    reg  [4:0]  rd;
    reg  [1:0]  wb_sel;

    wire        wb_en;
    wire [4:0]  wb_rd;
    wire [31:0] wb_data;

    wire [31:0] mmio_addr, mmio_wdata, mmio_rdata;
    wire [3:0]  mmio_wstrb;
    wire        mmio_we, mmio_re;

    // MMIO 从设备模型，B 组外设到位后替换
    reg [31:0] mmio_reg;
    initial mmio_reg = 32'h0;
    always @(posedge clk) begin
        if (mmio_we && mmio_addr == 32'h8000_2008) mmio_reg <= mmio_wdata;
    end
    assign mmio_rdata = mmio_reg;

    mem_stage #(.DMEM_WORDS(1024)) u_mem (
        .clk        (clk),
        .alu_result (alu_result),
        .store_data (store_data),
        .funct3     (funct3),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .rd         (rd),
        .reg_write  (reg_write),
        .pc_plus4   (pc_plus4),
        .wb_sel     (wb_sel),
        .wb_en      (wb_en),
        .wb_rd      (wb_rd),
        .wb_data    (wb_data),
        .mmio_addr  (mmio_addr),
        .mmio_wdata (mmio_wdata),
        .mmio_wstrb (mmio_wstrb),
        .mmio_we    (mmio_we),
        .mmio_re    (mmio_re),
        .mmio_rdata (mmio_rdata)
    );

    integer errors = 0;

    task commit;
        begin @(posedge clk); #1; end
    endtask

    task store(input [31:0] a, input [31:0] d, input [2:0] f);
        begin
            alu_result = a; store_data = d; funct3 = f;
            mem_write = 1; mem_read = 0;
            rd = 5'd0; reg_write = 1'b0;
            pc_plus4 = 32'h0; wb_sel = 2'b00;
            #1;
        end
    endtask

    task load(input [31:0] a, input [2:0] f, input [4:0] r);
        begin
            alu_result = a; store_data = 32'h0; funct3 = f;
            mem_write = 0; mem_read = 1;
            rd = r; reg_write = 1'b1;
            pc_plus4 = 32'h0; wb_sel = 2'b01;
            #1;
        end
    endtask

    task wb_check(input en, input [4:0] r, input [31:0] d);
        begin
            if ((wb_en !== en) || (wb_rd !== r) || (wb_data !== d)) begin
                errors = errors + 1;
                $display("    FAIL  wb_en=%b wb_rd=x%0d wb_data=%08h   (exp %b x%0d %08h)",
                          wb_en, wb_rd, wb_data, en, r, d);
            end else
                $display("    ok    wb_en=%b wb_rd=x%0d wb_data=%08h", wb_en, wb_rd, wb_data);
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

    initial begin
        alu_result = 0; store_data = 0; pc_plus4 = 0;
        funct3 = 0; mem_read = 0; mem_write = 0;
        rd = 0; reg_write = 0; wb_sel = 0;

        $display("=== tb_mem_stage start ===");

        //-----------------------------------------------------------------
        $display("case1: sw 0xDEADBEEF @0x100");
        store(32'h100, 32'hDEADBEEF, 3'b010);
        chk1(wb_en, 1'b0);
        commit;

        //-----------------------------------------------------------------
        $display("case2: lw x5, 0(x6)");
        load(32'h100, 3'b010, 5'd5);
        wb_check(1'b1, 5'd5, 32'hDEADBEEF);

        //-----------------------------------------------------------------
        $display("case3: sb 0x80 @0x106, then lb / lbu");
        store(32'h106, 32'h0000_0080, 3'b000);
        chk1(wb_en, 1'b0);
        commit;

        load(32'h106, 3'b000, 5'd6);
        wb_check(1'b1, 5'd6, 32'hFFFF_FF80);

        load(32'h106, 3'b100, 5'd7);
        wb_check(1'b1, 5'd7, 32'h0000_0080);

        //-----------------------------------------------------------------
        $display("case4: sh 0xABCD @0x10C, then lh");
        store(32'h10C, 32'h0000_ABCD, 3'b001);
        commit;
        load(32'h10C, 3'b001, 5'd8);
        wb_check(1'b1, 5'd8, 32'hFFFF_ABCD);

        //-----------------------------------------------------------------
        $display("case5: sw 0xA5A5_5A5A @0x8000_2008 (MMIO)");
        store(32'h8000_2008, 32'hA5A5_5A5A, 3'b010);
        chk1(u_mem.mmio_we, 1'b1);
        chk1(u_mem.dmem_we, 1'b0);
        commit;

        $display("case6: lw @0x8000_2008");
        load(32'h8000_2008, 3'b010, 5'd9);
        wb_check(1'b1, 5'd9, 32'hA5A5_5A5A);

        //-----------------------------------------------------------------
        $display("case7: jal x1, 8 @0x100 -> wb_data must be 0x104");
        alu_result = 32'h0000_0108;
        store_data = 32'h0; funct3 = 3'b000;
        mem_write = 1'b0; mem_read = 1'b0;
        rd = 5'd1; reg_write = 1'b1;
        pc_plus4 = 32'h0000_0104;
        wb_sel = 2'b10; #1;
        wb_check(1'b1, 5'd1, 32'h0000_0104);
        chk1(u_mem.dmem_we, 1'b0);

        //-----------------------------------------------------------------
        $display("case8: addi x10, x0, 8 -> wb_data = 8");
        alu_result = 32'h0000_0008;
        mem_write = 1'b0; mem_read = 1'b0;
        rd = 5'd10; reg_write = 1'b1;
        pc_plus4 = 32'h0000_0204;
        wb_sel = 2'b00; #1;
        wb_check(1'b1, 5'd10, 32'h0000_0008);

        //-----------------------------------------------------------------
        $display("case9: lw @0xC000_0000 (unmapped) -> 0");
        load(32'hC000_0000, 3'b010, 5'd11);
        wb_check(1'b1, 5'd11, 32'h0000_0000);

        //-----------------------------------------------------------------
        $display("=== %0d errors ===", errors);
        if (errors == 0) begin
            $display("PASS tb_mem_stage");
            $finish;
        end else begin
            $display("FAIL tb_mem_stage");
            $fatal(1);
        end
    end

endmodule
