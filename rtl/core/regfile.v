`timescale 1ns / 1ps
module regfile(
    input clk,
    input write_en,
    input [4:0]ReadReg1,
    input [4:0]ReadReg2,
    input [4:0]WriteReg,
    input [31:0]WriteData,

    output [31:0]ReadData1,
    output [31:0]ReadData2
    );
    wire do_write = write_en & (WriteReg!=5'd0);
    reg [31:0] regs[32];
    always@(posedge clk)begin
        if(do_write)begin
            regs[WriteReg]<=WriteData;
        end
    end
    assign ReadData1=(ReadReg1 == 5'd0)? 32'd0 :
                    (do_write && (WriteReg==ReadReg1))?WriteData:regs[ReadReg1];
    assign ReadData2=(ReadReg2 == 5'd0)? 32'd0 :
                    (do_write && (WriteReg==ReadReg2))?WriteData:regs[ReadReg2];
endmodule
