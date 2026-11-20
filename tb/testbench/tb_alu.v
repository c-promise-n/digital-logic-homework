`timescale 1ns/1ps
`include "defines.vh"

module tb_alu;
    reg [31:0]a,b;
    reg [3:0]op;
    wire [31:0]result;
    wire zero;
    reg [15:0] checks, errors;

    localparam [3:0] ADD=4'h0, SUB=4'h1, SLL=4'h2, SLT=4'h3, SLTU=4'h4,
                     XOR=4'h5, SRL=4'h6, SRA=4'h7, OR=4'h8, AND=4'h9, LUI=4'hA;

    alu u_dut (.src_a(a), .src_b(b), .alu_ctrl(op), .result(result), .zero(zero));

    task chk;
        input [3:0]  o;
        input [31:0] x;
        input [31:0] z;
        input [31:0] exp;
        begin
            op = o; a = x; b = z;
            #1;
            checks = checks + 1;
            if (y !== exp) begin
                errors = errors + 1;
                $display("FAIL @%0t: op=%h a=%08h b=%08h got=%08h exp=%08h",
                         $time, o, x, z, y, exp);
            end
        end
    endtask

    initial begin
        checks=16'd0;
        erros=16'd0;

        chk(ADD,  32'd10,         32'd20,         32'd30);
        chk(ADD,  32'h1234_5678,  32'h0000_FFFF,  32'h1235_5677);
        chk(SUB,  32'd10,         32'd20,         32'hFFFF_FFF6);
        chk(SUB,  32'h1234_5678,  32'h1234_5678,  32'd0);
        chk(SLL,  32'd1,          32'd4,          32'h0000_0010);
        chk(SLL,  32'hF0F0_F0F0,  32'd8,          32'hF0F0_F000);
        chk(SLT,  32'hFFFF_FFFB,  32'd3,          32'd1);
        chk(SLT,  32'd3,          32'hFFFF_FFFB,  32'd0);
        chk(SLTU, 32'hFFFF_FFFB,  32'd3,          32'd0);
        chk(SLTU, 32'd3,          32'hFFFF_FFFB,  32'd1);
        chk(XOR,  32'hF0F0_F0F0,  32'h0F0F_0F0F,  32'hFFFF_FFFF);
        chk(XOR,  32'hAAAA_AAAA,  32'hFFFF_FFFF,  32'h5555_5555);
        chk(SRL,  32'h8000_0000,  32'd4,          32'h0800_0000);
        chk(SRL,  32'hF0F0_F0F0,  32'd8,          32'h00F0_F0F0);
        chk(SRA,  32'h8000_0000,  32'd4,          32'hF800_0000);
        chk(SRA,  32'hF0F0_F0F0,  32'd8,          32'hFFF0_F0F0);
        chk(OR,   32'hF000_0000,  32'h0000_000F,  32'hF000_000F);
        chk(OR,   32'h00FF_00FF,  32'hFF00_FF00,  32'hFFFF_FFFF);
        chk(AND,  32'hF0F0_F0F0,  32'hFFFF_0000,  32'hF0F0_0000);
        chk(AND,  32'h1234_5678,  32'h0000_0000,  32'd0);

        chk(ADD,  32'h7FFF_FFFF,  32'd1,          32'h8000_0000);
        chk(ADD,  32'hFFFF_FFFF,  32'd1,          32'd0);
        chk(ADD,  32'hFFFF_FFFF,  32'hFFFF_FFFF,  32'hFFFF_FFFE);
        chk(SUB,  32'd0,          32'd1,          32'hFFFF_FFFF);
        chk(SUB,  32'h8000_0000,  32'd1,          32'h7FFF_FFFF);
        chk(SUB,  32'h8000_0000,  32'h8000_0000,  32'd0);


        chk(SLL,  32'hFFFF_FFFF,  32'd0,          32'hFFFF_FFFF);
        chk(SLL,  32'h0000_0001,  32'd31,         32'h8000_0000);
        chk(SLL,  32'h8000_0000,  32'd1,          32'd0);
        chk(SLL,  32'hFFFF_FFFF,  32'd32,         32'hFFFF_FFFF);
        chk(SLL,  32'hFFFF_FFFF,  32'd33,         32'hFFFF_FFFE);
        chk(SRL,  32'h8000_0000,  32'd31,         32'd1);
        chk(SRL,  32'hFFFF_FFFF,  32'd0,          32'hFFFF_FFFF);
        chk(SRL,  32'h8000_0000,  32'd32,         32'h8000_0000);
        chk(SRA,  32'h8000_0000,  32'd31,         32'hFFFF_FFFF);
        chk(SRA,  32'h7FFF_FFFF,  32'd31,         32'd0);
        chk(SRA,  32'h8000_0000,  32'd32,         32'h8000_0000);

        chk(SLT,  32'hFFFF_FFFF,  32'd0,          32'd1);
        chk(SLTU, 32'hFFFF_FFFF,  32'd0,          32'd0);
        chk(SLT,  32'd0,          32'hFFFF_FFFF,  32'd0);
        chk(SLTU, 32'd0,          32'hFFFF_FFFF,  32'd1);
        chk(SLT,  32'h8000_0000,  32'h7FFF_FFFF,  32'd1);
        chk(SLTU, 32'h8000_0000,  32'h7FFF_FFFF,  32'd0);
        chk(SLT,  32'h1234_5678,  32'h1234_5678,  32'd0);
        chk(SLTU, 32'h1234_5678,  32'h1234_5678,  32'd0);

        chk(LUI,  32'hDEAD_BEEF,  32'hFFFF_F000,  32'hFFFF_F000);
        chk(LUI,  32'd0,          32'h0000_1000,  32'h0000_1000);
        chk(4'hF, 32'h1111_1111,  32'h2222_2222,  32'd0);
        chk(4'hB, 32'h1111_1111,  32'h2222_2222,  32'd0);

        op = ADD; a = 32'd0;          b = 32'd0;          #1;
        checks = checks + 16'd1;
        if (zero !== 1'b1) begin
            errors = errors + 16'd1; $display("FAIL @%0t: zero=1 (0+0)", $time);
         end

        op = SUB; a = 32'd5;          b = 32'd5;          #1;
        checks = checks + 16'd1;
        if (zero !== 1'b1) begin
            errors = errors + 16'd1; $display("FAIL @%0t: zero=1 (5-5)", $time);
        end

        op = AND; a = 32'h1234_5678;  b = 32'h0000_0000;  #1;
        checks = checks + 16'd1;
        if (zero !== 1'b1) begin
            errors = errors + 16'd1; $display("FAIL @%0t: zero=1 (x&0)", $time);
         end

        op = SRA; a = 32'h7FFF_FFFF;  b = 32'd31;         #1;
        checks = checks + 16'd1;
        if (zero !== 1'b1) begin
            errors = errors + 16'd1; $display("FAIL @%0t: zero=1 (0x7fffffff>>>31)", $time);
        end

        op = ADD; a = 32'd1;          b = 32'd2;          #1;
        checks = checks + 16'd1;
        if (zero !== 1'b0) begin
            errors = errors + 16'd1; $display("FAIL @%0t: zero should be 0 (1+2)", $time);
        end

        if (errors == 16'd0)
            $display("PASS: alu, %0d checks, 0 errors", checks);
        else
            $display("FAIL: alu, %0d checks, %0d errors", checks, errors);
        $finish;
    end
endmodule
