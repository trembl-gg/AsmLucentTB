@echo off
setlocal

title AsmLucentTB - FASM x64 Builder

set "FASM_DIR=C:\Tools\FASM"
set "FASM=%FASM_DIR%\fasm.exe"

if not exist "%FASM%" (
    echo [ERROR] FASM not found.
    pause
    exit /b 1
)

if not exist "%FASM_DIR%\INCLUDE\win64a.inc" (
    echo [ERROR] win64a.inc not found.
    pause
    exit /b 1
)

if not exist build mkdir build

echo ==========================================
echo          AsmLucentTB x64 Builder
echo ==========================================

echo.
echo [1/1] Compiling...

"%FASM%" src\AsmLucentTB.asm build\AsmLucentTB.exe

if errorlevel 1 (
    echo.
    echo [ERROR] Compilation failed.
    pause
    exit /b 1
)

echo.
echo [SUCCESS] build\AsmLucentTB.exe

pause
