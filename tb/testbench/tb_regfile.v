`timescale 1ns / 1ps
// tb_regfile.v - self-checking testbench for regfile

module tb_regfile;

    reg         clk;
    reg         write_en;
    reg  [4:0]  ra;
    reg  [4:0]  rb;
    reg  [4:0]  wa;
    reg  [31:0] wd;
    wire [31:0] rd1;
    wire [31:0] rd2;

    reg  [5:0]  i;
    reg  [15:0] checks;
    reg  [15:0] errors;

    regfile u_regfile (
        .clk       (clk),
        .write_en  (write_en),
        .ReadReg1  (ra),
        .ReadReg2  (rb),
        .WriteReg  (wa),
        .WriteData (wd),
        .ReadData1 (rd1),
        .ReadData2 (rd2)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // write one register
    task automatic wr;
        input [4:0] a;
        input [31:0] d;
        begin
            @(negedge clk);
            write_en = 1'b1;
            wa = a;
            wd = d;
            @(negedge clk);
            write_en = 1'b0;
        end
    endtask

    // read both ports at address a and compare with expected
    task automatic chk;
        input [4:0] a;
        input [31:0] e;
        begin
            @(negedge clk);
            ra = a;
            rb = a;
            #1;
            checks = checks + 1;
            if ((rd1 !== e) || (rd2 !== e)) begin
                errors = errors + 1;
                $display("FAIL @%0t: r%0d rd1=%08h rd2=%08h exp=%08h", $time, a, rd1, rd2, e);
            end
        end
    endtask

    initial begin
        write_en = 1'b0;
        ra = 5'd0;
        rb = 5'd0;
        wa = 5'd0;
        wd = 32'd0;
        checks = 16'd0;
        errors = 16'd0;

        repeat (2) @(negedge clk);

        // no reset in DUT: write every entry before reading it
        for (i = 0; i < 32; i = i + 1) begin
            wr(i[4:0], 32'hA5A50000 + i[4:0]);
            if(i==0)
            chk(5'd0,32'd0);
            else
            chk(i[4:0], 32'hA5A50000 + i[4:0]);
        end

        wr(5'd0, 32'hFFFF_FFFF);
        wr(5'd0, 32'h0000_0001);
        chk(5'd0, 32'd0);

        // two ports, different addresses
        @(negedge clk);
        ra = 5'd5;
        rb = 5'd20;
        #1;
        checks = checks + 1;
        if ((rd1 !== 32'hA5A50005) || (rd2 !== 32'hA5A50014)) begin
            errors = errors + 1;
            $display("FAIL @%0t: dual read rd1=%08h rd2=%08h", $time, rd1, rd2);
        end

        // write_en=0 must not write
        @(negedge clk);
        write_en = 1'b0;
        wa = 5'd7;
        wd = 32'hDEADBEEF;
        repeat (2) @(negedge clk);
        ra = 5'd7;
        rb = 5'd7;
        #1;
        checks = checks + 1;
        if ((rd1 !== 32'hA5A50007) || (rd2 !== 32'hA5A50007)) begin
            errors = errors + 1;
            $display("FAIL @%0t: write_en=0 wrote r7 rd1=%08h", $time, rd1);
        end

        // last write wins
        wr(5'd3, 32'h11111111);
        wr(5'd3, 32'h22222222);
        chk(5'd3, 32'h22222222);


        wr(5'd9, 32'h0BADF00D);
        @(negedge clk);
        ra = 5'd9;
        rb = 5'd9;
        wa = 5'd9;
        wd = 32'h600DCAFE;
        write_en = 1'b1;
        #1;
        checks = checks + 1;
        if ((rd1 !== 32'h600DCAFE) || (rd2 !== 32'h600DCAFE)) begin
            errors = errors + 1;
            $display("FAIL @%0t: no write-first bypass rd1=%08h rd2=%08h", $time, rd1, rd2);
        end
        @(negedge clk);
        write_en = 1'b0;
        checks = checks + 1;
        if ((rd1 !== 32'h600DCAFE) || (rd2 !== 32'h600DCAFE)) begin
            errors = errors + 1;
            $display("FAIL @%0t: r9 not updated rd1=%08h", $time, rd1);
        end

        if (errors == 16'd0)
            $display("PASS: %0d checks, 0 errors", checks);
        else
            $display("FAIL: %0d checks, %0d errors", checks, errors);
        $finish;
    end

endmodule
