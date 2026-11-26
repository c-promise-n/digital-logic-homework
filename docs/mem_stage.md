# MEM / WB 阶段（C 组）

## 模块

| 文件 | 模块 | 说明 |
|---|---|---|
| `rtl/core/lsu.v` | `lsu` | 地址对齐、字节写选通、写数据对齐、读数据符号/零扩展 |
| `rtl/core/dmem.v` | `dmem` | 4 KB 数据存储器，异步读 / 同步写，字节粒度写使能 |
| `rtl/core/bus.v` | `bus` | 地址译码，DMEM / MMIO 请求分发与读数据汇总 |
| `rtl/core/wb_mux.v` | `wb_mux` | 写回数据选择：ALU / MEM / PC+4 |
| `rtl/core/mem_stage.v` | `mem_stage` | MEM+WB 子系统，C 组对外接口 |

`mem_stage` 内部例化上述四个模块，对外只暴露三组端口。

## `mem_stage` 端口

### 输入（EX 阶段）

| 端口 | 位宽 | 说明 |
|---|---|---|
| `clk` | 1 | 时钟 |
| `alu_result` | 32 | 访存地址，或运算结果 |
| `store_data` | 32 | `rs2` 数据 |
| `funct3` | 3 | 指令 `funct3` |
| `mem_read` | 1 | load 指示 |
| `mem_write` | 1 | store 指示 |
| `rd` | 5 | 目标寄存器 |
| `reg_write` | 1 | 寄存器写使能 |
| `pc_plus4` | 32 | PC + 4 |
| `wb_sel` | 2 | `00`=ALU，`01`=MEM，`10`=PC+4 |

### 输出（写回寄存器堆）

| 端口 | 位宽 | 接到 `regfile` 的 |
|---|---|---|
| `wb_en` | 1 | `write_en` |
| `wb_rd` | 5 | `WriteReg` |
| `wb_data` | 32 | `WriteData` |

`x0` 的写保护由 `regfile` 内部完成（`write_en & (WriteReg != 0)`），`mem_stage` 不做处理。

### 输出（MMIO）

| 端口 | 位宽 | 方向 |
|---|---|---|
| `mmio_addr` | 32 | out |
| `mmio_wdata` | 32 | out |
| `mmio_wstrb` | 4 | out |
| `mmio_we` | 1 | out |
| `mmio_re` | 1 | out |
| `mmio_rdata` | 32 | in |

## 地址映射

| 区域 | 范围 | 窗口 |
|---|---|---|
| DMEM | `0x0000_0000 – 0x0000_0FFF` | 4 KB |
| MMIO | `0x8000_0000 – 0x8000_FFFF` | 64 KB |

未映射地址：读回 0，写丢弃。

## 约束

- 仅支持对齐访问：`LW/SW` 要求 `addr[1:0]==0`，`LH/SH` 要求 `addr[1:0]` 为 0 或 2
- 数据存储器为异步读（LUTRAM），保证单周期内取数；改为同步读 BRAM 会引入一拍延迟
- `funct3` 直接透传 `inst[14:12]`，控制单元不需要额外产生 `mem_width` / `is_signed`

## 验证

```bash
make test        # CI 使用 iverilog，需本地安装
```

本机没有 iverilog 时可用 Vivado xsim：

```bat
scripts\sim_xsim.bat
```

四个 testbench：

| tb | 覆盖 |
|---|---|
| `tb_lsu.v` | 字/半字/字节读写、大小端、符号与零扩展 |
| `tb_bus.v` | 地址译码、写使能门控、未映射地址、窗口边界 |
| `tb_wb_mux.v` | 三路写回选择、保留编码、通道隔离 |
| `tb_mem_stage.v` | 指令级集成（`sw`/`lw`/`lb`/`sh`/`jal`/`addi`） |
