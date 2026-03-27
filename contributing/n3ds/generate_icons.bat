@echo off
setlocal disabledelayedexpansion

set "TOOL_3DS=%~dp0tools\windows\ctrtool.exe"
set "ICON_CONVERTER=%~dp0_icon_to_png.py"
set "SANITIZER=%~dp0_sanitize.py"

echo -------------------------------------------------------
echo 3DS Icon Extractor (Batch Mode)
echo -------------------------------------------------------

if not exist "%ICON_CONVERTER%" (
    echo [Error] _icon_to_png.py not found. Place it in the same folder as this script.
    pause
    exit /b 1
)
if not exist "%SANITIZER%" (
    echo [Error] _sanitize.py not found. Place it in the same folder as this script.
    pause
    exit /b 1
)
if not exist "%~dp0tools\windows\ctrtool.exe" (
    echo [Error] ctrtool.exe not found. Expected at: Contributing\n3ds\tools\windows\ctrtool.exe
    pause
    exit /b 1
)
:: Prefer the project venv if present, otherwise fall back to PATH python
set "VENV_PYTHON=%~dp0..\..\venv\Scripts\python.exe"
set "DOTENV_PYTHON=%~dp0..\..\.venv\Scripts\python.exe"
if exist "%DOTENV_PYTHON%" (
    set "PYTHON=%DOTENV_PYTHON%"
) else if exist "%VENV_PYTHON%" (
    set "PYTHON=%VENV_PYTHON%"
) else (
    where python >nul 2>&1
    if errorlevel 1 (
        echo [Error] Python not found in PATH. Install Python and retry.
        pause
        exit /b 1
    )
    set "PYTHON=python"
)

:: Resolve paths relative to the script location (Contributing\n3ds\)
:: The repo root is two levels up.
pushd "%~dp0"
set "SCRIPT_DIR=%CD%"
cd ..\..
set "REPO_ROOT=%CD%"
popd

set "OUTPUT_DIR=%REPO_ROOT%\icons\n3ds"
set "GAMES_DIR=%SCRIPT_DIR%\games"

if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
if not exist "%GAMES_DIR%" mkdir "%GAMES_DIR%"

if not exist "%GAMES_DIR%\*.3ds" if not exist "%GAMES_DIR%\*.cci" (
    echo [Info] No .3ds or .cci files found in: %GAMES_DIR%
    echo Add ROM files to the games folder, then run this script again.
    pause
    exit /b 0
)

set /a PROCESSED=0
set /a SUCCESS=0

for /f "delims=" %%f in ('dir /b /a-d "%GAMES_DIR%\*.3ds" "%GAMES_DIR%\*.cci" 2^>nul') do (
    set /a PROCESSED+=1
    call :ProcessGame "%GAMES_DIR%\%%f"
)

echo.
echo -------------------------------------------------------
echo Finished. Processed: %PROCESSED%  Success: %SUCCESS%
echo Output folder: %OUTPUT_DIR%
echo -------------------------------------------------------
pause
exit /b 0

:ProcessGame
setlocal
set "GAME_FILE=%~1"
set "EXEFS_DIR=%TEMP%\n3ds_exefs_%RANDOM%%RANDOM%"
set "ICON_RAW=%EXEFS_DIR%\icon"
set "ICON_BIN=%EXEFS_DIR%\icon.bin"
set "SANITIZED_NAME="

"%PYTHON%" "%SANITIZER%" "%~nx1" > "%EXEFS_DIR%_name.txt" 2>nul
set /p SANITIZED_NAME= < "%EXEFS_DIR%_name.txt"
del "%EXEFS_DIR%_name.txt" >nul 2>&1
if not defined SANITIZED_NAME set "SANITIZED_NAME=%~n1"
set "OUTPUT_PNG=%OUTPUT_DIR%\%SANITIZED_NAME%.png"

echo [Processing] %~nx1...

if exist "%EXEFS_DIR%" rmdir /s /q "%EXEFS_DIR%" >nul 2>&1
mkdir "%EXEFS_DIR%" >nul 2>&1

"%TOOL_3DS%" --exefsdir="%EXEFS_DIR%" "%GAME_FILE%" >nul 2>&1
if errorlevel 1 (
    echo [Warning] ctrtool failed.
    rmdir /s /q "%EXEFS_DIR%" >nul 2>&1
    endlocal & goto :eof
)

if exist "%ICON_RAW%" (
    copy /y "%ICON_RAW%" "%ICON_BIN%" >nul
) else if not exist "%ICON_BIN%" (
    echo [Warning] icon file not found in ExeFS.
    rmdir /s /q "%EXEFS_DIR%" >nul 2>&1
    endlocal & goto :eof
)

"%PYTHON%" "%ICON_CONVERTER%" "%ICON_BIN%" "%OUTPUT_PNG%"
if errorlevel 1 (
    echo [Warning] Python conversion failed. Ensure pyctr is installed: pip install pyctr
    rmdir /s /q "%EXEFS_DIR%" >nul 2>&1
    endlocal & goto :eof
)

if not exist "%OUTPUT_PNG%" (
    echo [Warning] Conversion reported success but no output file was found.
    rmdir /s /q "%EXEFS_DIR%" >nul 2>&1
    endlocal & goto :eof
)

echo [Saved] %OUTPUT_PNG%
rmdir /s /q "%EXEFS_DIR%" >nul 2>&1
endlocal & set /a SUCCESS+=1 & goto :eof