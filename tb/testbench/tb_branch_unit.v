`timescale 1ns / 1ps
`default_nettype none

module tb_branch_unit;

    reg  [31:0] rs1_data;
    reg  [31:0] rs2_data;
    reg  [31:0] imm;
    reg  [31:0] pc;
    reg         branch;
    reg  [2:0]  branch_op;
    reg         jump;
    reg         jalr;
    wire        taken;
    wire [31:0] target;

    reg  [15:0] checks;
    reg  [15:0] errors;

    localparam [2:0] BR_BEQ  = 3'b000;
    localparam [2:0] BR_BNE  = 3'b001;
    localparam [2:0] BR_BLT  = 3'b010;
    localparam [2:0] BR_BGE  = 3'b011;
    localparam [2:0] BR_BLTU = 3'b100;
    localparam [2:0] BR_BGEU = 3'b101;

    branch_unit u_dut (
        .rs1_data  (rs1_data),
        .rs2_data  (rs2_data),
        .imm       (imm),
        .inst_pc        (pc),
        .is_branch (branch),
        .branch_op (branch_op),
        .jump      (jump),
        .jalr      (jalr),
        .taken     (taken),
        .target    (target)
    );

     task chk;
        input [31:0] a;
        input [31:0] b;
        input [31:0] im;
        input [31:0] p;
        input        br;
        input        jp;
        input        jr;
        input [2:0]  bop;
        input        et;     // expected taken
        input [31:0] etg;    // expected target（only check when et=1 ）
        input [8*32-1:0] nm;
        begin
            rs1_data  = a;
            rs2_data  = b;
            imm       = im;
            pc        = p;
            branch    = br;
            jump      = jp;
            jalr      = jr;
            branch_op = bop;
            #1;
            checks = checks + 16'd1;
            if (taken !== et) begin
                errors = errors + 16'd1;
                $display("FAIL @%0t [%0s] taken=%b exp=%b", $time, nm, taken, et);
            end else if ((et === 1'b1) && (target !== etg)) begin
                errors = errors + 16'd1;
                $display("FAIL @%0t [%0s] target=%08h exp=%08h", $time, nm, target, etg);
            end
        end
    endtask

    // condition branch：imm=0，pc=0x1000
    task chk_cond;
        input [31:0] a, b;
        input [2:0]  bop;
        input        et;
        input [8*32-1:0] nm;
        begin
            chk(a, b, 32'd0, 32'h1000, 1'b1, 1'b0, 1'b0, bop, et, 32'h1000, nm);
        end
    endtask

    // JAL：jump=1, jalr=0，taken 恒 1
    task chk_jal;
        input [31:0] p, im, etg;
        input [8*32-1:0] nm;
        begin
            chk(32'd0, 32'd0, im, p, 1'b0, 1'b1, 1'b0, BR_BEQ, 1'b1, etg, nm);
        end
    endtask

    // JALR：jump=1, jalr=1
    task chk_jalr;
        input [31:0] a, im, etg;
        input [8*32-1:0] nm;
        begin
            chk(a, 32'd0, im, 32'h1000, 1'b0, 1'b1, 1'b1, BR_BEQ, 1'b1, etg, nm);
        end
    endtask

    // no jump nor branch：taken must be 0
    task chk_none;
        input [31:0] a, b;
        input [2:0]  bop;
        input [8*32-1:0] nm;
        begin
            chk(a, b, 32'd0, 32'h1000, 1'b0, 1'b0, 1'b0, bop, 1'b0, 32'h1000, nm);
        end
    endtask

    initial begin
        rs1_data = 32'd0; rs2_data = 32'd0; imm = 32'd0; pc = 32'd0;
        branch = 1'b0; branch_op = 3'd0; jump = 1'b0; jalr = 1'b0;
        checks = 16'd0; errors = 16'd0;
        //1.six conditions * six oprands
        // A: rs1=-5 (0xFFFFFFFB), rs2=3
        chk_cond(32'hFFFF_FFFB, 32'd3, BR_BEQ,  1'b0, "A:BEQ  -5==3");
        chk_cond(32'hFFFF_FFFB, 32'd3, BR_BNE,  1'b1, "A:BNE  -5!=3");
        chk_cond(32'hFFFF_FFFB, 32'd3, BR_BLT,  1'b1, "A:BLT  -5<3");
        chk_cond(32'hFFFF_FFFB, 32'd3, BR_BGE,  1'b0, "A:BGE  -5>=3");
        chk_cond(32'hFFFF_FFFB, 32'd3, BR_BLTU, 1'b0, "A:BLTU 4.29e9<3");
        chk_cond(32'hFFFF_FFFB, 32'd3, BR_BGEU, 1'b1, "A:BGEU 4.29e9>=3");

        //  B: rs1=3, rs2=-5
        chk_cond(32'd3, 32'hFFFF_FFFB, BR_BEQ,  1'b0, "B:BEQ  3==-5");
        chk_cond(32'd3, 32'hFFFF_FFFB, BR_BNE,  1'b1, "B:BNE  3!=-5");
        chk_cond(32'd3, 32'hFFFF_FFFB, BR_BLT,  1'b0, "B:BLT  3<-5");
        chk_cond(32'd3, 32'hFFFF_FFFB, BR_BGE,  1'b1, "B:BGE  3>=-5");
        chk_cond(32'd3, 32'hFFFF_FFFB, BR_BLTU, 1'b1, "B:BLTU 3<4.29e9");
        chk_cond(32'd3, 32'hFFFF_FFFB, BR_BGEU, 1'b0, "B:BGEU 3>=4.29e9");

        //C: equal
        chk_cond(32'h1234_5678, 32'h1234_5678, BR_BEQ,  1'b1, "C:BEQ  equal");
        chk_cond(32'h1234_5678, 32'h1234_5678, BR_BNE,  1'b0, "C:BNE  equal");
        chk_cond(32'h1234_5678, 32'h1234_5678, BR_BLT,  1'b0, "C:BLT  equal");
        chk_cond(32'h1234_5678, 32'h1234_5678, BR_BGE,  1'b1, "C:BGE  equal");
        chk_cond(32'h1234_5678, 32'h1234_5678, BR_BLTU, 1'b0, "C:BLTU equal");
        chk_cond(32'h1234_5678, 32'h1234_5678, BR_BGEU, 1'b1, "C:BGEU equal");

        // D: INT_MIN vs INT_MAX
        chk_cond(32'h8000_0000, 32'h7FFF_FFFF, BR_BEQ,  1'b0, "D:BEQ  min==max");
        chk_cond(32'h8000_0000, 32'h7FFF_FFFF, BR_BNE,  1'b1, "D:BNE  min!=max");
        chk_cond(32'h8000_0000, 32'h7FFF_FFFF, BR_BLT,  1'b1, "D:BLT  min<max");
        chk_cond(32'h8000_0000, 32'h7FFF_FFFF, BR_BGE,  1'b0, "D:BGE  min>=max");
        chk_cond(32'h8000_0000, 32'h7FFF_FFFF, BR_BLTU, 1'b0, "D:BLTU 2^31<2^31-1");
        chk_cond(32'h8000_0000, 32'h7FFF_FFFF, BR_BGEU, 1'b1, "D:BGEU 2^31>2^31-1");

        // E: INT_MAX vs INT_MIN（D 反过来）
        chk_cond(32'h7FFF_FFFF, 32'h8000_0000, BR_BEQ,  1'b0, "E:BEQ  max==min");
        chk_cond(32'h7FFF_FFFF, 32'h8000_0000, BR_BNE,  1'b1, "E:BNE  max!=min");
        chk_cond(32'h7FFF_FFFF, 32'h8000_0000, BR_BLT,  1'b0, "E:BLT  max<min");
        chk_cond(32'h7FFF_FFFF, 32'h8000_0000, BR_BGE,  1'b1, "E:BGE  max>=min");
        chk_cond(32'h7FFF_FFFF, 32'h8000_0000, BR_BLTU, 1'b1, "E:BLTU 2^31-1<2^31");
        chk_cond(32'h7FFF_FFFF, 32'h8000_0000, BR_BGEU, 1'b0, "E:BGEU 2^31-1>=2^31");

        // F: 0 vs -1
        chk_cond(32'd0, 32'hFFFF_FFFF, BR_BEQ,  1'b0, "F:BEQ  0==-1");
        chk_cond(32'd0, 32'hFFFF_FFFF, BR_BNE,  1'b1, "F:BNE  0!=-1");
        chk_cond(32'd0, 32'hFFFF_FFFF, BR_BLT,  1'b0, "F:BLT  0<-1");
        chk_cond(32'd0, 32'hFFFF_FFFF, BR_BGE,  1'b1, "F:BGE  0>=-1");
        chk_cond(32'd0, 32'hFFFF_FFFF, BR_BLTU, 1'b1, "F:BLTU 0<4.29e9");
        chk_cond(32'd0, 32'hFFFF_FFFF, BR_BGEU, 1'b0, "F:BGEU 0>=4.29e9");


        // 2. un_defined branch_op（110/111)
        chk_cond(32'd5, 32'd5, 3'b110, 1'b0, "bop110 no take");
        chk_cond(32'd5, 32'd5, 3'b111, 1'b0, "bop111 no take");

        // 3. branch=0 , taken= 0
        chk_none(32'd5,          32'd5,          BR_BEQ, "none 5==5 beq");
        chk_none(32'd5,          32'd5,          BR_BNE, "none 5==5 bne");
        chk_none(32'h8000_0000,  32'h7FFF_FFFF,  BR_BLT, "none min<max");

        // 4. target = pc + imm
        chk(32'h1234, 32'h1234, 32'h40,         32'h1000, 1'b1, 1'b0, 1'b0, BR_BEQ, 1'b1, 32'h1040, "BEQ taken +0x40");
        chk(32'h1234, 32'h1234, 32'hFFFF_FFF0,  32'h1000, 1'b1, 1'b0, 1'b0, BR_BEQ, 1'b1, 32'h0FF0, "BEQ taken -0x10");
        chk(32'h1234, 32'h1000, 32'h40,         32'h1000, 1'b1, 1'b0, 1'b0, BR_BEQ, 1'b0, 32'd0,    "BEQ not taken");
        chk(32'h1234, 32'h1000, 32'h40,         32'h1000, 1'b1, 1'b0, 1'b0, BR_BNE, 1'b1, 32'h1040, "BNE taken +0x40");

        // 5. JAL：target = pc + imm，taken = 1
        chk_jal(32'h1000, 32'h0000_0020, 32'h1020,       "JAL +0x20");
        chk_jal(32'h1000, 32'hFFFF_FFF8, 32'h0FF8,       "JAL -8");
        chk_jal(32'h1004, 32'd4,         32'h1008,       "JAL +4");
        chk_jal(32'h1000, 32'h0007_FFFE, 32'h0008_0FFE,  "JAL max +1MiB");
        chk_jal(32'h1000, 32'hFFF8_0000, 32'hFFF8_1000,  "JAL max -1MiB");
        chk_jal(32'd0,    32'h0000_0020, 32'h0000_0020,  "JAL from 0");

        // 6. JALR：target = (rs1 + imm) & ~1
        chk_jalr(32'h0000_0200, 32'd0,          32'h0000_0200, "JALR even");
        chk_jalr(32'h0000_0201, 32'd0,          32'h0000_0200, "JALR odd->even");
        chk_jalr(32'h0000_01FF, 32'd2,          32'h0000_0200, "JALR carry odd");
        chk_jalr(32'h0000_0200, 32'hFFFF_FFFC,  32'h0000_01FC, "JALR -4");
        chk_jalr(32'h0000_0200, 32'hFFFF_FFFE,  32'h0000_01FE, "JALR -2");
        chk_jalr(32'h8000_0000, 32'h0000_0100,  32'h8000_0100, "JALR high bit");
        chk_jalr(32'hFFFF_FFFF, 32'd0,          32'hFFFF_FFFE, "JALR only bit0");


       if (errors == 16'd0)
            $display("PASS: branch_unit, %0d checks, 0 errors", checks);
        else
            $display("FAIL: branch_unit, %0d checks, %0d errors", checks, errors);

        $finish;
    end

endmodule

`default_nettype wire
