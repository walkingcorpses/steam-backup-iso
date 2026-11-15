@echo off
rem install.cmd - copies the game folder from this ISO to a folder you pick.
rem Usage: double-click (asks for a folder) or: install.cmd "D:\Games"
setlocal
rem The ISO holds one top-level folder: the game.
for /d %%D in ("%~dp0*") do set "SRC=%%~fD" & set "NAME=%%~nxD"
set "DEST=%~1"
if "%DEST%"=="" set /p "DEST=Install to which folder (e.g. D:\Games)? "
if "%DEST%"=="" exit /b 1
rem /E copies all subfolders; /J unbuffered I/O suits big files.
robocopy "%SRC%" "%DEST%\%NAME%" /E /J /NP /R:2 /W:2
rem robocopy exit codes below 8 mean success.
if %ERRORLEVEL% GEQ 8 (echo Copy failed. & pause & exit /b 1)
echo Installed to "%DEST%\%NAME%".
pause