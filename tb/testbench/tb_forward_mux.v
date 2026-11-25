`timescale 1ns / 1ps
`default_nettype none
`include "defines.vh"

module tb_forward_mux;

    reg  [31:0] id_ex_rs1_data;
    reg  [31:0] id_ex_rs2_data;
    reg  [31:0] ex_mem_alu_result;
    reg  [31:0] mem_wb_wdata;
    reg  [1:0]  forward_rs1;
    reg  [1:0]  forward_rs2;
    reg  [1:0]  forward_store;
    reg         ctrl_alu_sel_pc;
    reg  [31:0] id_ex_pc;
    reg         ctrl_alu_sel_imm;
    reg  [31:0] id_ex_imm;


    wire [31:0] ex_rs1_fwd;
    wire [31:0] ex_rs2_fwd;
    wire [31:0] ex_alu_a;
    wire [31:0] ex_alu_b;
    wire [31:0] ex_store_data;

    reg  [15:0] checks;
    reg  [15:0] errors;


    localparam [31:0] D_RS1 = 32'h1111_0001;
    localparam [31:0] D_RS2 = 32'h2222_0002;
    localparam [31:0] D_EXM = 32'h3333_0003;
    localparam [31:0] D_WB  = 32'h4444_0004;
    localparam [31:0] D_PC  = 32'h8888_0008;
    localparam [31:0] D_IMM = 32'h9999_0009;

    forward_mux u_dut (
        .id_ex_rs1_data    (id_ex_rs1_data),
        .id_ex_rs2_data    (id_ex_rs2_data),
        .ex_mem_alu_result (ex_mem_alu_result),
        .mem_wb_wdata      (mem_wb_wdata),
        .forward_rs1       (forward_rs1),
        .forward_rs2       (forward_rs2),
        .forward_store     (forward_store),
        .ctrl_alu_sel_pc   (ctrl_alu_sel_pc),
        .id_ex_pc          (id_ex_pc),
        .ctrl_alu_sel_imm  (ctrl_alu_sel_imm),
        .id_ex_imm         (id_ex_imm),
        .ex_rs1_fwd        (ex_rs1_fwd),
        .ex_rs2_fwd        (ex_rs2_fwd),
        .ex_alu_a          (ex_alu_a),
        .ex_alu_b          (ex_alu_b),
        .ex_store_data     (ex_store_data)
    );

    task chk;
        input [31:0]      got;
        input [31:0]      exp;
        input [8*40-1:0]  name;
        begin
            checks = checks + 16'd1;
            if (got !== exp) begin
                errors = errors + 16'd1;
                $display("FAIL @%0t [%0s] got=%08h exp=%08h", $time, name, got, exp);
            end
        end
    endtask

    task apply;
        input [1:0] fa;
        input [1:0] fb;
        input [1:0] fs;
        input       spc;
        input       simm;
        begin
            forward_rs1   = fa;
            forward_rs2   = fb;
            forward_store = fs;
            ctrl_alu_sel_pc  = spc;
            ctrl_alu_sel_imm = simm;
            #1;
        end
    endtask

    function [31:0] pick;
        input [1:0]  f;
        input [31:0] d0;
        input [31:0] d1;
        input [31:0] d2;
        begin
            case (f)
                2'd1:    pick = d1;      // EX/MEM
                2'd2:    pick = d2;      // MEM/WB
                default: pick = d0;      // forward none
            endcase
        end
    endfunction

    reg [2:0] ia;
    reg [2:0] ib;

    initial begin
        id_ex_rs1_data    = D_RS1;
        id_ex_rs2_data    = D_RS2;
        ex_mem_alu_result = D_EXM;
        mem_wb_wdata      = D_WB;
        id_ex_pc          = D_PC;
        id_ex_imm         = D_IMM;
        forward_rs1       = `FWD_NONE;
        forward_rs2       = `FWD_NONE;
        forward_store     = `FWD_NONE;
        ctrl_alu_sel_pc   = 1'b0;
        ctrl_alu_sel_imm  = 1'b0;
        checks = 16'd0;
        errors = 16'd0;

        if ((`FWD_NONE !== 2'b00) || (`FWD_EX_MEM !== 2'b01) || (`FWD_MEM_WB !== 2'b10)) begin
            errors = errors + 16'd1;
            $display("FAIL @%0t [encoding] FWD_NONE/EX_MEM/MEM_WB 必须是 00/01/10，实际 %b/%b/%b",
                     $time, `FWD_NONE, `FWD_EX_MEM, `FWD_MEM_WB);
        end
        checks = checks + 16'd1;

        apply(`FWD_NONE, `FWD_NONE, `FWD_NONE, 1'b0, 1'b0);
        chk(ex_rs1_fwd,    D_RS1, "T1 rs1_fwd");
        chk(ex_rs2_fwd,    D_RS2, "T1 rs2_fwd");
        chk(ex_alu_a,      D_RS1, "T1 alu_a");
        chk(ex_alu_b,      D_RS2, "T1 alu_b");
        chk(ex_store_data, D_RS2, "T1 store_data");


        apply(`FWD_EX_MEM, `FWD_NONE, `FWD_NONE, 1'b0, 1'b0);
        chk(ex_rs1_fwd,    D_EXM, "T2 rs1_fwd = EX/MEM");
        chk(ex_alu_a,      D_EXM, "T2 alu_a  = EX/MEM");
        chk(ex_rs2_fwd,    D_RS2, "T2 rs2_fwd 不受影响");

        apply(`FWD_MEM_WB, `FWD_NONE, `FWD_NONE, 1'b0, 1'b0);
        chk(ex_rs1_fwd,    D_WB,  "T2 rs1_fwd = MEM/WB");
        chk(ex_alu_a,      D_WB,  "T2 alu_a  = MEM/WB");

        apply(`FWD_NONE, `FWD_EX_MEM, `FWD_NONE, 1'b0, 1'b0);
        chk(ex_rs2_fwd,    D_EXM, "T2 rs2_fwd = EX/MEM");
        chk(ex_alu_b,      D_EXM, "T2 alu_b  = EX/MEM");
        chk(ex_rs1_fwd,    D_RS1, "T2 rs1_fwd 不受影响");

        apply(`FWD_NONE, `FWD_MEM_WB, `FWD_NONE, 1'b0, 1'b0);
        chk(ex_rs2_fwd,    D_WB,  "T2 rs2_fwd = MEM/WB");
        chk(ex_alu_b,      D_WB,  "T2 alu_b  = MEM/WB");


        apply(`FWD_NONE, `FWD_NONE, `FWD_EX_MEM, 1'b0, 1'b0);
        chk(ex_store_data, D_EXM, "T3 store = EX/MEM");
        chk(ex_rs2_fwd,    D_RS2, "T3 store 不影响 rs2_fwd");
        chk(ex_alu_b,      D_RS2, "T3 store 不影响 alu_b");

        apply(`FWD_NONE, `FWD_NONE, `FWD_MEM_WB, 1'b0, 1'b0);
        chk(ex_store_data, D_WB,  "T3 store = MEM/WB");

        apply(`FWD_EX_MEM, `FWD_MEM_WB, `FWD_EX_MEM, 1'b0, 1'b0);
        chk(ex_rs1_fwd,    D_EXM, "T3 三路独立 rs1");
        chk(ex_rs2_fwd,    D_WB,  "T3 三路独立 rs2");
        chk(ex_store_data, D_EXM, "T3 三路独立 store");


        apply(`FWD_NONE, `FWD_NONE, `FWD_NONE, 1'b1, 1'b0);
        chk(ex_alu_a,      D_PC,  "T4 sel_pc -> alu_a = pc");
        chk(ex_rs1_fwd,    D_RS1, "T4 sel_pc 不改 rs1_fwd");

        apply(`FWD_NONE, `FWD_NONE, `FWD_NONE, 1'b0, 1'b1);
        chk(ex_alu_b,      D_IMM, "T4 sel_imm -> alu_b = imm");
        chk(ex_rs2_fwd,    D_RS2, "T4 sel_imm 不改 rs2_fwd");


        apply(`FWD_EX_MEM, `FWD_MEM_WB, `FWD_NONE, 1'b1, 1'b1);
        chk(ex_alu_a,      D_PC,  "T5 sel_pc 覆盖转发（auipc）");
        chk(ex_alu_b,      D_IMM, "T5 sel_imm 覆盖转发（I 型）");
        chk(ex_rs1_fwd,    D_EXM, "T5 rs1_fwd 仍是转发值");
        chk(ex_rs2_fwd,    D_WB,  "T5 rs2_fwd 仍是转发值");


        apply(2'b11, 2'b11, 2'b11, 1'b0, 1'b0);
        chk(ex_rs1_fwd,    D_RS1, "T6 保留码 rs1 退化为不转发");
        chk(ex_rs2_fwd,    D_RS2, "T6 保留码 rs2 退化为不转发");
        chk(ex_store_data, D_RS2, "T6 保留码 store 退化为不转发");
        chk(ex_alu_a,      D_RS1, "T6 保留码 alu_a 不为 X");
        chk(ex_alu_b,      D_RS2, "T6 保留码 alu_b 不为 X");


        for (ia = 3'd0; ia < 3'd4; ia = ia + 3'd1) begin
            for (ib = 3'd0; ib < 3'd4; ib = ib + 3'd1) begin
                apply(ia[1:0], ib[1:0], `FWD_NONE, 1'b0, 1'b0);
                chk(ex_rs1_fwd, pick(ia[1:0], D_RS1, D_EXM, D_WB), "T8 sweep rs1_fwd");
                chk(ex_rs2_fwd, pick(ib[1:0], D_RS2, D_EXM, D_WB), "T8 sweep rs2_fwd");
                chk(ex_alu_a,   pick(ia[1:0], D_RS1, D_EXM, D_WB), "T8 sweep alu_a");
                chk(ex_alu_b,   pick(ib[1:0], D_RS2, D_EXM, D_WB), "T8 sweep alu_b");
                chk(ex_store_data, D_RS2, "T8 sweep store 不受 rs1/rs2 影响");
            end
        end


        if (errors == 16'd0)
            $display("PASS: forward_mux, %0d checks, 0 errors", checks);
        else
            $display("FAIL: forward_mux, %0d checks, %0d errors", checks, errors);

        $finish;
    end

endmodule

`default_nettype wire
