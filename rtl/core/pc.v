//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Pinfeng_Song
// 
// Create Date: 2026/11/18 22:23
// Design Name: pc module
// Module Name: pc
// Project Name: digital-logic-homework
// Target Devices: 
// Tool Versions: 
// Description: 
// a pc module for risc 32i pipline cpu 
//
// Dependencies: 
// 
// Revision:
// - Revision 0.0.1: 2026/11/18 
//      a pc module according to P284 of reference book.
//      包含pc模块前端的数据选择器与一个加法器，未复用ALU的加法器
//
//
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module pc (
    input clk,
    input pc_ctrl,      
    // control signal from controller
    //1'b0 for using +4 pc
    // 1'b1 for using input pc target

    input [4:0] pc_target,    
    // input target pc, in use when J-tpye instruction
    output [4:0] pc_o
    // 5 bits pc signal
);
    always @(posedge clk) begin
        if (pc_ctrl == 1'b1)
            pc_o <= pc_target;
        else 
        pc_o <= pc + 5'd4;
    end
endmodule