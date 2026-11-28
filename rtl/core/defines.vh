`ifndef DEFINES_VH
`define DEFINES_VH

//alu编码
`define ALU_ADD 4'b0000     // a + b                (add/addi)
`define ALU_SUB 4'b0001     // a - b                (sub)
`define ALU_SLL 4'b0010     // a << b[4:0]          (sll/slli)
`define ALU_SLT 4'b0011     // signed(a) < signed(b)  (slt/slti)
`define ALU_SLTU 4'b0100    // a < b  (unsigned)      (sltu/sltiu)
`define ALU_XOR 4'b0101     // a ^ b                (xor/xori)
`define ALU_SRL 4'b0110     // a >> b[4:0]          (srl/srli)
`define ALU_SRA 4'b0111     // $signed(a) >>> b[4:0] (sra/srai)
`define ALU_OR 4'b1000      // a | b                (or/ori)
`define ALU_AND 4'b1001     // a & b                (and/andi)
`define ALU_PASS_B 4'b1010  // result = b           (lui)
`define ALU_MULDIV 4'b1111

//branch_unit op
`define BR_BEQ 3'b000   // rs1 == rs2
`define BR_BNE 3'b001   // rs1 != rs2
`define BR_BLT 3'b100   // $signed(rs1) <  $signed(rs2)
`define BR_BGE 3'b101   // $signed(rs1) >= $signed(rs2)
`define BR_BLTU 3'b110   // rs1 <  rs2  (unsigned)
`define BR_BGEU 3'b111   // rs1 >= rs2  (unsigned)

`define FWD_NONE       2'b00    //id_ex_rs1_data / id_ex_rs2_data
`define FWD_EX_MEM     2'b01    //ex_mem_alu_result
`define FWD_MEM_WB     2'b10    //mem_wb_wdata


//immsrc编码
`define IMMSRC_I 3'b000     //I-type instruction
//`define IMMSRC_I_S 3'b001   //I-type shift instruction
//do not need, cause ALU only use least 5 bits
`define IMMSRC_S 3'b010     //S-type instruction
`define IMMSRC_B 3'b011     //B-type instruction
`define IMMSRC_U 3'b100     //U-type instruction
`define IMMSRC_J 3'b101     //J-type instruction
`define IMMSRC_0 3'b000     //default value

//指令类别编码
`define INST_LOAD 7'b0000011   //加载
`define INST_OP_IMM 7'b0010011 //立即数整数运算
`define INST_AUIPC 7'b0010111  //将高位立即数加到pc（Add Upper Immediate to PC）
`define INST_STORE 7'b0100011  //存储
`define INST_OP 7'b0110011     //整数运算
`define INST_LUI 7'b0110111    //加载高位立即数（Load Upper Immediate）
`define INST_BRANCH 7'b1100011 //条件分支
`define INST_JALR 7'b1100111   //间接跳转并链接（Jump and Link Register）
`define INST_JAL 7'b1101111    //直接跳转并链接（Jump and Link）

//译码器内部ALU_OP（与ALU单元无关）
`define ALU_OP_ERROR 2'b00
`define ALU_OP_ADD 2'b01
`define ALU_OP_OP 2'b10
`define ALU_OP_PASSB 2'b11


//错误的func3值
`define FUNC3_E_LOAD_1 3'b011
`define FUNC3_E_LOAD_2 3'b110
`define FUNC3_E_LOAD_3 3'b111

`define FUNC3_C_STORE_1 3'b000
`define FUNC3_C_STORE_2 3'b001
`define FUNC3_C_STORE_3 3'b010

`define FUNC3_E_BRANCH_1 3'b010
`define FUNC3_E_BRANCH_2 3'b011

`define FUNC3_C_JALR 3'b000
`endif
