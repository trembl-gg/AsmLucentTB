@echo off
chcp 65001 >nul
title AsmLucentTB ICO Builder

set "INPUT=%~dp0AsmLucentTB.png"
set "OUTPUT=%~dp0AsmLucentTB.ico"

if not "%~1"=="" set "INPUT=%~1"

if not exist "%INPUT%" (
    echo [ERROR] PNG not found!
    pause
    exit /b
)

echo Building multi-resolution ICO...

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; Add-Type -AssemblyName System.Drawing; $img=[Drawing.Image]::FromFile('%INPUT%'); $sizes=16,20,24,32,40,48,64,128; $entries=New-Object 'System.Collections.Generic.List[object]'; foreach($s in $sizes) { $b=New-Object Drawing.Bitmap($s,$s); $g=[Drawing.Graphics]::FromImage($b); $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic; $g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality; $g.DrawImage($img,0,0,$s,$s); $m=New-Object IO.MemoryStream; $b.Save($m,[Drawing.Imaging.ImageFormat]::Png); $entries.Add(@{Size=$s;Bytes=$m.ToArray()}); $m.Dispose(); $g.Dispose(); $b.Dispose() }; $img.Dispose(); $f=[IO.File]::Create('%OUTPUT%'); $w=New-Object IO.BinaryWriter($f); $w.Write([uint16]0); $w.Write([uint16]1); $w.Write([uint16]$entries.Count); $offset=6+16*$entries.Count; foreach($e in $entries) { $w.Write([byte]$e.Size); $w.Write([byte]$e.Size); $w.Write([byte]0); $w.Write([byte]0); $w.Write([uint16]1); $w.Write([uint16]32); $w.Write([uint32]$e.Bytes.Length); $w.Write([uint32]$offset); $offset+=$e.Bytes.Length }; foreach($e in $entries) { $w.Write([byte[]]$e.Bytes) }; $w.Close(); $f.Close(); Write-Host 'SUCCESS: 8 resolutions generated!' -ForegroundColor Green"

if errorlevel 1 (
    echo [ERROR] Conversion failed!
    pause
    exit /b 1
)

echo.
echo Created: %OUTPUT%
pause