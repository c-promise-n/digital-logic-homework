`ifndef DEFINES_VH
`define DEFINES_VH

`define ALU_ADD 4'b0000   // a + b                (add/addi)
`define ALU_SUB 4'b0001   // a - b                (sub)
`define ALU_SLL 4'b0010   // a << b[4:0]          (sll/slli)
`define ALU_SLT 4'b0011   // signed(a) < signed(b)  (slt/slti)
`define ALU_SLTU 4'b0100   // a < b  (unsigned)      (sltu/sltiu)
`define ALU_XOR 4'b0101   // a ^ b                (xor/xori)
`define ALU_SRL 4'b0110   // a >> b[4:0]          (srl/srli)
`define ALU_SRA 4'b0111   // $signed(a) >>> b[4:0] (sra/srai)
`define ALU_OR 4'b1000   // a | b                (or/ori)
`define ALU_AND 4'b1001   // a & b                (and/andi)
`define ALU_PASS_B 4'b1010   // result = b           (lui)
`define ALU_MULDIV 4'b1111
`define BR_BEQ 3'b000   // rs1 == rs2
`define BR_BNE 3'b001   // rs1 != rs2
`define BR_BLT 3'b010   // $signed(rs1) <  $signed(rs2)
`define BR_BGE 3'b011   // $signed(rs1) >= $signed(rs2)
`define BR_BLTU 3'b100   // rs1 <  rs2  (unsigned)
`define BR_BGEU 3'b101   // rs1 >= rs2  (unsigned)
`endif
