@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
if not exist "%~dp0config.env" goto :fail
for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%~dp0config.env") do set "%%A=%%B"
if not defined PROJECT_COUNT goto :fail
if not defined FORK_REMOTE goto :fail
if not defined SOURCE_BRANCH goto :fail
if not defined TARGET_BRANCH goto :fail
for /l %%N in (1,1,!PROJECT_COUNT!) do (
    call :check %%N
    if errorlevel 1 goto :fail
)
echo All projects checked. No remotes or branches changed.
pause
exit /b 0

:check
set "DIR="
set "URL="
call set "DIR=%%PROJECT_%1_PATH%%"
call set "URL=%%PROJECT_%1_URL%%"
echo [Check %1] !DIR!
if not defined DIR exit /b 1
if not defined URL exit /b 1
if not exist "!DIR!\.git" (echo ERROR: Not a Git project root.&exit /b 1)
git -C "!DIR!" remote get-url "!FORK_REMOTE!" >nul 2>&1 || (echo ERROR: Fork remote missing.&exit /b 1)
echo OK
exit /b 0

:fail
echo ERROR: Check config.env, paths and Fork remotes.
pause
exit /b 1
