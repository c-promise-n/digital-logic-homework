#!/usr/bin/env python3

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BUILD = ROOT / "sim" / "build"
BUILD.mkdir(parents=True, exist_ok=True)

# 参与仿真的 RTL 目录
RTL_FILES = (
    sorted((ROOT / "rtl" / "core").glob("*.v"))
    + sorted((ROOT / "rtl" / "soc").glob("*.v"))
)

# 自动发现 tb 下所有 tb_*.v，支持子目录
TB_FILES = sorted((ROOT / "tb").rglob("tb_*.v"))

# include 搜索路径
INCLUDE_DIRS = [
    p for p in [
        ROOT / "rtl" / "core",
        ROOT / "rtl" / "soc",
        ROOT / "tb",
    ]
    if p.exists()
]

# 特例：某个 testbench 需要额外文件或 plusarg
SPECIAL = {
    # "tb_top": {
    #     "files": ["rtl/top/basys3_top.v"],
    #     "args": ["+UART_BAUD=115200"],
    # },
}


def include_args():
    args = []
    for d in INCLUDE_DIRS:
        args += ["-I", str(d)]
    return args


def run(cmd, timeout=120):
    print("+", " ".join(str(c) for c in cmd), flush=True)
    return subprocess.run(cmd, cwd=ROOT, text=True, timeout=timeout)


def sources_for(tb: Path):
    extra = SPECIAL.get(tb.stem, {}).get("files", [])
    return RTL_FILES + [tb] + [ROOT / f for f in extra]


def run_args_for(tb: Path):
    return SPECIAL.get(tb.stem, {}).get("args", [])


def main():
    if not TB_FILES:
        print("No tb/**/tb_*.v found")
        return 1

    failed = []

    for tb in TB_FILES:
        name = tb.stem
        vvp = BUILD / f"{name}.vvp"

        compile_cmd = [
            "iverilog",
            "-g2012",
            *include_args(),
            "-s", name,
            "-o", str(vvp),
        ]
        compile_cmd += [str(p) for p in sources_for(tb)]

        try:
            result = run(compile_cmd)
        except subprocess.TimeoutExpired:
            print(f"TIMEOUT compiling {name}", flush=True)
            failed.append(name)
            continue

        if result.returncode != 0:
            failed.append(name)
            continue

        run_cmd = ["vvp", str(vvp)] + run_args_for(tb)

        try:
            result = run(run_cmd)
        except subprocess.TimeoutExpired:
            print(f"TIMEOUT running {name}", flush=True)
            failed.append(name)
            continue

        if result.returncode != 0:
            failed.append(name)

    print()
    if failed:
        print("FAILED:", ", ".join(failed))
        return 1

    print(f"ALL {len(TB_FILES)} TESTS PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())