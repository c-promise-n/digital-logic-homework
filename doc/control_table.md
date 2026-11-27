# RISC-V RV32I 控制表

本文档根据 [`control_unit.v`](/D:/Project/Vivado/digital-logic-homework/rtl/core/control_unit.v)、[`main_decoder.v`](/D:/Project/Vivado/digital-logic-homework/rtl/core/main_decoder.v)、[`alu_decoder.v`](/D:/Project/Vivado/digital-logic-homework/rtl/core/alu_decoder.v) 和 [`defines.vh`](/D:/Project/Vivado/digital-logic-homework/rtl/core/defines.vh) 整理。当前模块使用的主要控制信号及约定如下：

- `pc_src = (zero & branch) | jump`：`0` 选择 PC+4，`1` 选择 PC target。
- `result_src`：`00` ALU 结果，`01` LSU 读数据，`10` PC+4。
- `mem_write`：高电平有效。
- `alu_srcA`：按主译码器实际语义应为 `0` 选择 RD1，`1` 选择 PC。
- `alu_srcB`：按主译码器实际语义应为 `0` 选择 RD2，`1` 选择立即数扩展。
- `imm_src`：`000` I 型，`001` I 型移位，`010` S 型，`011` B 型，`100` U 型，`101` J 型，`xxx` 不需要立即数。
- `reg_write`、`lsu_read`、`lsu_write` 均为高电平有效。
- `pctarget_src`：`0` 选择 PC，`1` 选择 RD1（目标地址最低位置 0）。
- `lsu_func3` 应直接等于指令的 `func3`，用于 LSU 区分 LB/LBU/LH/LHU/LW/SB/SH/SW 等类型。

## 1. 主控制表

| 指令 | opcode `op[6:0]` | `pc_src` | `result_src` | `mem_write` | `alu_srcA` | `alu_srcB` | `imm_src` | `reg_write` | `alu_op` | `lsu_read` | `lsu_write` | `branch` | `jump` | `pctarget_src` |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| LB/LH/LW/LBU/LHU | `0000011` | `0` | `01` | `0` | `1` | `0` | `000` I | `1` | `00` | `1` | `0` | `0` | `0` | `0` |
| ADDI/SLTI/SLTIU/XORI/ORI/ANDI/SLLI/SRLI/SRAI | `0010011` | `0` | `00` | `0` | `0` | `1` | `000` I | `1` | `10` | `0` | `0` | `0` | `0` | `0` |
| AUIPC | `0010111` | `0` | `00` | `1`（模块值；应为 `0`） | `1` | `1` | `100` U | `1` | `00` | `0` | `0` | `0` | `0` | `0` |
| SB/SH/SW | `0100011` | `0` | `00` | `1` | `0` | `1` | `010` S | `0` | `00` | `0` | `1` | `0` | `0` | `0` |
| ADD/SUB/SLL/SLT/SLTU/XOR/SRL/SRA/OR/AND | `0110011` | `0` | `00` | `0` | `0` | `0` | `xxx` | `1` | `10` | `0` | `0` | `0` | `0` | `0` |
| LUI | `0110111` | `0` | `00` | `0` | `0` | `0`（模块值；应为 `1`） | `xxx`（模块值；应为 `100` U） | `1` | `11` | `0` | `0` | `0` | `0` | `0` |
| BEQ/BNE/BLT/BGE/BLTU/BGEU | `1100011` | `branch & zero`（再与 `jump` 相或） | `00` | `0` | `0` | `0` | `011` B | `0` | `10` | `0` | `0` | `1` | `0` | `0` |
| JALR | `1100111` | `1` | `10` | `0` | `0` | `0`（模块值；应为 `1`） | `000` I | `1` | `00` | `0` | `0` | `0` | `1` | `1` |
| JAL | `1101111` | `1` | `10` | `0` | `0` | `0` | `101` J | `1` | `00` | `0` | `0` | `0` | `1` | `0` |

表中标注“应为”的值是从当前模块注释、立即数类型和标准 RISC-V 数据通路语义推断出的修正值；括号前的值是源码实际输出。

## 2. ALU 控制表

`alu_op` 为译码器指示，`func3` 和 `func7[5]` 用于 `10` 类的运算。

| `alu_op` | 指令类型 / 条件 | `func3` | `func7[5]` | `alu_control` | ALU 功能 |
|---|---|---:|---:|---:|---|
| `00` | ADD 类：LOAD、STORE、AUIPC、JAL、JALR | 任意 | 任意 | `0000` `ALU_ADD` | A + B |
| `01` | SUB 类（保留） | 任意 | 任意 | `0001` `ALU_SUB` | A - B |
| `11` | LUI / PASS-B 类 | 任意 | 任意 | `1010` `ALU_PASS_B` | 结果 = B |
| `10` | ADD / ADDI、BEQ 等默认 | `000` | `0` 或 I 型 | `0000` `ALU_ADD` | A + B |
| `10` | SUB：RV32I R 型且 `op[5]=1`、`func7[5]=1` | `000` | `1` | `0001` `ALU_SUB` | A - B |
| `10` | SLL / SLLI | `001` | 任意 | `0010` `ALU_SLL` | A << B[4:0] |
| `10` | SLT / SLTI | `010` | 任意 | `0011` `ALU_SLT` | 有符号 A < B |
| `10` | SLTU / SLTIU | `011` | 任意 | `0100` `ALU_SLTU` | 无符号 A < B |
| `10` | XOR / XORI | `100` | 任意 | `0101` `ALU_XOR` | A XOR B |
| `10` | SRL / SRLI | `101` | `0` | `0110` `ALU_SRL` | 逻辑右移 |
| `10` | SRA / SRAI | `101` | `1` | `0111` `ALU_SRA` | 算术右移 |
| `10` | OR / ORI | `110` | 任意 | `1000` `ALU_OR` | A OR B |
| `10` | AND / ANDI | `111` | 任意 | `1001` `ALU_AND` | A AND B |

## 3. 分支控制说明

分支指令通过 `branch=1` 和 `zero` 参与取指选择：

- `BEQ` 需要比较相等。
- `BNE` 需要比较不相等。
- `BLT`/`BGE` 需要有符号比较。
- `BLTU`/`BGEU` 需要无符号比较。

当前源码只向控制单元提供一个 `zero` 信号，没有传递分支类型 `func3` 来做这五种分别的分支判断；同时分支目前也未形成统一的减法/比较控制。因此上述分支功能不能仅由现有 `ALU ADD/SUB/SLT/SLTU` 结果和 `zero` 完整实现。

## 4. LSU 控制表

`lsu_func3` 应等于指令的 `func3`：

| 指令 | `lsu_read` | `lsu_write` | `func3` / LSU 类型 |
|---|---:|---:|---:|
| LB | `1` | `0` | `000`：有符号字节加载 |
| LH | `1` | `0` | `001`：有符号半字加载 |
| LW | `1` | `0` | `010`：有符号字加载 |
| LBU | `1` | `0` | `100`：无符号字节加载 |
| LHU | `1` | `0` | `101`：无符号半字加载 |
| SB | `0` | `1` | `000`：写字节 |
| SH | `0` | `1` | `001`：写半字 |
| SW | `0` | `1` | `010`：写字 |

## 5. 模块检查发现的错误与风险

1. **`alu_decoder.v` 端口宽度错误**：源码声明 `input alu_op`，实际从主译码器传入的是 `alu_op [1:0]`，会发生端口位宽截断。应声明为 `input [1:0] alu_op`。
2. **`control_unit.v` 未驱动 `lsu_func3`**：该输出在模块中声明，但没有 `assign lsu_func3 = func3;`，应直接映射到输入。
3. **`main_decoder.v` 中 AUIPC 的 `mem_write` 为 `1`**：AUIPC 不写数据内存，应为 `0`。
4. **`main_decoder.v` 中 LOAD 的 A 源选择当前为 `1`**：按该模块的 PC/RD1 两选一设计，LOAD 地址应选择 RD1（`0`），再与立即数相加（`1`），否则会对 PC 做地址加法。
5. **LUI 控制不完整**：LUI 应使用 U 型立即数、`alu_srcB=1` 并由 ALU PASS-B 输出；源码当前 `imm_src=xxx` 且 `alu_srcB=0`，立即数会归零。
6. **JALR 控制不完整**：当前直接跳转地址通路应由 `RD1 + I 型立即数` 形成，源码未在表中的 ALU A/B 源上提供正确的立即数选择（应为 RD1 和立即数）。
7. **分支译码不完整**：仅传入 `zero`，未传入完整 `func3` 做 BEQ/BNE/BLT/BGE/BLTU/BGEU 判断，且现有主译码和 ALU译码不能覆盖所有分支类型。
8. **未实现指令**：源码注释明确暂未实现 `SYSTEM` 与 `MISC-MEM` 指令；默认情况下未列出的 opcode 不应保证输出有定义，最好在主译码器中加入默认赋值。
9. **注释存在语义歧义**：`control_unit.v` 和 `main_decoder.v` 对 `alu_srcA`/`alu_srcB` 的注释互有差异；本文档采用设计临时文档中“ALU srcA 在 RD1 与 PC 间选择、srcB 在 RD2 与立即数间选择”的语义。

以上为只读检查结论；本次仅完成控制表文档，未修改任何 RTL 源码。