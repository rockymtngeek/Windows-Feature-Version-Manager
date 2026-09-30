@echo off
setlocal
title Windows Feature Version Manager

set "SCRIPT=%~dp0Windows-Feature-Version-Manager.ps1"

if not exist "%SCRIPT%" (
    echo.
    echo ERROR: Windows-Feature-Version-Manager.ps1 was not found.
    echo Keep this CMD file in the same folder as the PowerShell script.
    echo.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"

endlocal
