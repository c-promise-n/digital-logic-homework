# RISC-V RV32I 控制表

本文档依据 [`control_unit.v`](../rtl/core/control_unit.v)、[`main_decoder.v`](../rtl/core/main_decoder.v)、[`alu_decoder.v`](../rtl/core/alu_decoder.v)、[`branch_unit.v`](../rtl/core/branch_unit.v) 和 [`defines.vh`](../rtl/core/defines.vh) 对照整理。

## 1. 控制信号约定

- `result_src`：`00` ALU 结果，`01` LSU 读数据，`10` PC+4。
- `mem_write`：高电平有效，表示写数据内存，同时作为 LSU 写使能。
- `alu_srcA`：`0` 选择 RD1，`1` 选择 PC。
- `alu_srcB`：`0` 选择 RD2，`1` 选择符号扩展后的立即数。
- `imm_src`：`000` I 型，`010` S 型，`011` B 型，`100` U 型，`101` J 型；不需要立即数时默认输出 `000`。
- `reg_write`、`lsu_read`：高电平有效。
- `jump`：高电平表示 JAL 或合法 JALR 跳转。
- `jalr`：高电平表示合法 JALR；`branch_unit` 据此选择寄存器目标地址。
- `is_branch`：高电平表示当前是合法条件分支。
- `branch_op`：直接等于指令 `func3`，由 `branch_unit` 判断分支类型。
- `lsu_func3`：直接等于指令 `func3`。
- `illegal_op`：主译码器无法识别 opcode 时为高。
- 主译码器的 `illegal_func`：LOAD、STORE、BRANCH 或 JALR 的 `func3` 不合法时为高。
- `illegal_inst`：`illegal_op`、主译码器的 `illegal_func` 或 ALU 译码器的 `illegal_func` 任一为高时置高。
- 控制单元接收完整的 `func7`，但 ALU 译码器目前只使用 `func7[5]` 区分 SUB/SRA 与 ADD/SRL；其他 `func7` 位没有合法性校验。

## 2. 主控制表

下表列出各指令正常编码时的控制信号。非法 `func3` 和未知 opcode 的安全控制值见表后说明。

| 指令 | opcode `op[6:0]` | `result_src` | `mem_write` | `alu_srcA` | `alu_srcB` | `imm_src` | `reg_write` | `alu_op` | `lsu_read` | `is_branch` | `jump` | `jalr` | `illegal_inst` |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| LB/LH/LW/LBU/LHU | `0000011` | `01` | `0` | `0` | `1` | `000` I | `1` | `01` ADD | `1` | `0` | `0` | `0` | `0` |
| ADDI/SLTI/SLTIU/XORI/ORI/ANDI/SLLI/SRLI/SRAI | `0010011` | `00` | `0` | `0` | `1` | `000` I | `1` | `10` OP | `0` | `0` | `0` | `0` | `0` |
| AUIPC | `0010111` | `00` | `0` | `1` | `1` | `100` U | `1` | `01` ADD | `0` | `0` | `0` | `0` | `0` |
| SB/SH/SW | `0100011` | `00` | `1` | `0` | `1` | `010` S | `0` | `01` ADD | `0` | `0` | `0` | `0` | `0` |
| ADD/SUB/SLL/SLT/SLTU/XOR/SRL/SRA/OR/AND | `0110011` | `00` | `0` | `0` | `0` | `xxx` | `1` | `10` OP | `0` | `0` | `0` | `0` | `0` |
| LUI | `0110111` | `00` | `0` | `0` | `1` | `100` U | `1` | `11` PASS-B | `0` | `0` | `0` | `0` | `0` |
| BEQ/BNE/BLT/BGE/BLTU/BGEU | `1100011` | `00` | `0` | `0` | `0` | `011` B | `0` | `11` PASS-B | `0` | `1` | `0` | `0` | `0` |
| JALR | `1100111` | `10` | `0` | `0` | `1` | `000` I | `1` | `11` PASS-B | `0` | `0` | `1` | `1` | `0` |
| JAL | `1101111` | `10` | `0` | `0` | `0` | `101` J | `1` | `11` PASS-B | `0` | `0` | `1` | `0` | `0` |
| 未知 opcode | 其他编码 | `00` | `0` | `0` | `0` | `000` 默认值 | `0` | `00` ERROR | `0` | `0` | `0` | `0` | `1` |

合法的 LOAD `func3` 为 `000/001/010/100/101`，STORE 为 `000/001/010`，BRANCH 为 `000/001/100/101/110/111`，JALR 仅允许 `000`。非法 `func3` 会关闭对应的读、写、分支或跳转控制信号，输出安全控制值，并将主译码器的 `illegal_func` 置高。对于这些非法功能码，`alu_op` 输出 `00`，ALU 译码器也会将其 `illegal_func` 置高。

未知 opcode 会将 `illegal_op` 置高，并将控制信号设为默认安全值。

## 3. ALU 控制表

`alu_op` 为译码器内部编码，见 [`defines.vh`](../rtl/core/defines.vh)：`00` ERROR、`01` ADD、`10` OP、`11` PASS-B。`func3` 和 `func7[5]` 用于 `10` 类的运算。

| `alu_op` | 指令类型 / 条件 | `func3` | `func7[5]` | `alu_control` | ALU 功能 |
|---|---|---:|---:|---:|---|
| `00` | ERROR：未知 opcode 或主译码器检测到非法 `func3` | 任意 | 任意 | `1010` `ALU_PASS_B`（当前默认） | 结果 = B；应配合 `illegal_inst` 阻止执行 |
| `01` | ADD 类：LOAD、STORE、AUIPC | 任意 | 任意 | `0000` `ALU_ADD` | A + B |
| `11` | LUI、JAL、JALR、分支的 PASS-B 类 | 任意 | 任意 | `1010` `ALU_PASS_B` | 结果 = B；分支及跳转本身由 `branch_unit` 决定 |
| `10` | ADD / ADDI | `000` | 任意 | `0000` `ALU_ADD` | A + B |
| `10` | SUB：`op[5]=1` 且 `func7[5]=1` | `000` | `1` | `0001` `ALU_SUB` | A - B |
| `10` | SLL / SLLI | `001` | 任意 | `0010` `ALU_SLL` | A << B[4:0] |
| `10` | SLT / SLTI | `010` | 任意 | `0011` `ALU_SLT` | 有符号 A < B |
| `10` | SLTU / SLTIU | `011` | 任意 | `0100` `ALU_SLTU` | 无符号 A < B |
| `10` | XOR / XORI | `100` | 任意 | `0101` `ALU_XOR` | A XOR B |
| `10` | SRL / SRLI | `101` | `0` | `0110` `ALU_SRL` | 逻辑右移 |
| `10` | SRA / SRAI | `101` | `1` | `0111` `ALU_SRA` | 算术右移 |
| `10` | OR / ORI | `110` | 任意 | `1000` `ALU_OR` | A OR B |
| `10` | AND / ANDI | `111` | 任意 | `1001` `ALU_AND` | A AND B |

当前 ALU 译码器的 `func3` 为完整 3 位宽，`alu_op=10` 时所有 8 种取值均有对应运算，因此没有未覆盖的 `func3` 编码可触发该模块的非法功能码分支。当前非法功能码输出主要用于 `alu_op=00` 等默认情况；这并不代表已完成 `func7` 合法性检查。

## 4. 分支与跳转控制

条件分支由 [`branch_unit.v`](../rtl/core/branch_unit.v) 独立执行：

| 指令 | `branch_op=func3` | 成立条件 |
|---|---:|---|
| BEQ | `000` | RS1 == RS2 |
| BNE | `001` | RS1 != RS2 |
| BLT | `100` | 有符号 RS1 < RS2 |
| BGE | `101` | 有符号 RS1 >= RS2 |
| BLTU | `110` | 无符号 RS1 < RS2 |
| BGEU | `111` | 无符号 RS1 >= RS2 |

跳转逻辑：

- JAL：`jump=1`，目标地址为 `PC + J 型立即数`。
- 合法 JALR：`jump=1`、`jalr=1`，目标地址为 `(RS1 + I 型立即数) & ~1`。
- 条件分支：仅在 `is_branch=1` 时，由 `branch_op` 和 RS1/RS2 的比较结果决定是否跳转。
- JAL/JALR 写回的返回地址为 `PC+4`，由 `result_src=10` 的写回通路选择。

## 5. LSU 控制表

`lsu_func3` 等于指令的 `func3`；写使能由 `mem_write` 提供：

| 指令 | `lsu_read` | `mem_write` | `func3` / LSU 类型 |
|---|---:|---:|---|
| LB | `1` | `0` | `000`：有符号字节加载 |
| LH | `1` | `0` | `001`：有符号半字加载 |
| LW | `1` | `0` | `010`：字加载 |
| LBU | `1` | `0` | `100`：无符号字节加载 |
| LHU | `1` | `0` | `101`：无符号半字加载 |
| SB | `0` | `1` | `000`：写字节 |
| SH | `0` | `1` | `001`：写半字 |
| SW | `0` | `1` | `010`：写字 |
