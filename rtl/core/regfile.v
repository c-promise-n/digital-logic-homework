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

    reg [31:0] regfile[31:0];
    always@(posedge clk)begin
        if(write_en)begin
            regfile[WriteReg]<=WriteData;
        end
    end
    assign ReadData1=regfile[ReadReg1];
    assign ReadData2=regfile[ReadReg2];
endmodule
