@echo off
REM ============================================================
REM  Local simulation with Vivado xsim (fallback when iverilog
REM  is not installed). CI uses `make test` with iverilog.
REM
REM  Usage: run from repo root ->  scripts\sim_xsim.bat
REM  Pass criteria: four "PASS" lines, exit code 0
REM
REM  NOTE: keep this file ASCII-only. cmd.exe parses .bat with
REM        the system code page (936 on zh-CN Windows), UTF-8
REM        Chinese comments would be executed as garbage.
REM ============================================================
setlocal

set VB=
if exist "D:\Xilinx\Vivado\2019.2\bin\xvlog.bat" set VB=D:\Xilinx\Vivado\2019.2\bin
if not defined VB if exist "D:\Xilinx\Vivado\2019.1\bin\xvlog.bat" set VB=D:\Xilinx\Vivado\2019.1\bin
if not defined VB if exist "D:\Xilinx\Vivado\2020.2\bin\xvlog.bat" set VB=D:\Xilinx\Vivado\2020.2\bin
if not defined VB if exist "D:\Xilinx\Vivado\2020.1\bin\xvlog.bat" set VB=D:\Xilinx\Vivado\2020.1\bin

if not defined VB (
    echo *** Vivado not found. Edit VB= in this file. ***
    exit /b 1
)

echo Using %VB%
set PATH=%VB%;%PATH%
cd /d "%~dp0.."

if not exist rtl\core\mem_stage.v (
    echo *** Cannot find rtl\core\mem_stage.v. Run from the repo root. ***
    exit /b 1
)

call xvlog.bat rtl\core\dmem.v rtl\core\lsu.v rtl\core\bus.v rtl\core\wb_mux.v rtl\core\mem_stage.v tb\testbench\tb_lsu.v tb\testbench\tb_bus.v tb\testbench\tb_wb_mux.v tb\testbench\tb_mem_stage.v
if errorlevel 1 goto :err

echo.
echo ############ tb_lsu ############
call xelab.bat -debug typical tb_lsu -s sim_lsu >nul
if errorlevel 1 goto :err
call xsim.bat sim_lsu -R
if errorlevel 1 goto :err

echo.
echo ############ tb_bus ############
call xelab.bat -debug typical tb_bus -s sim_bus >nul
if errorlevel 1 goto :err
call xsim.bat sim_bus -R
if errorlevel 1 goto :err

echo.
echo ############ tb_wb_mux ############
call xelab.bat -debug typical tb_wb_mux -s sim_wb >nul
if errorlevel 1 goto :err
call xsim.bat sim_wb -R
if errorlevel 1 goto :err

echo.
echo ############ tb_mem_stage ############
call xelab.bat -debug typical tb_mem_stage -s sim_mem >nul
if errorlevel 1 goto :err
call xsim.bat sim_mem -R
if errorlevel 1 goto :err

exit /b 0

:err
echo.
echo *** FAILED ***
exit /b 1
