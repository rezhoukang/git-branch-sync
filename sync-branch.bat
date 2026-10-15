@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
if not exist "%~dp0config.env" goto :fail
for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%~dp0config.env") do set "%%A=%%B"
if not defined PROJECT_COUNT goto :fail
if not defined FORK_REMOTE goto :fail
if not defined SOURCE_BRANCH goto :fail
if not defined TARGET_BRANCH goto :fail
if /i "!SOURCE_BRANCH!"=="!TARGET_BRANCH!" goto :fail

echo WARNING: This REPLACES local and Fork !TARGET_BRANCH! history.
echo Continue only after PRs are merged and changes are saved.
set /p "ANSWER=Type YES to continue: "
if not "!ANSWER!"=="YES" exit /b 1

for /l %%N in (1,1,!PROJECT_COUNT!) do (
    call :sync %%N
    if errorlevel 1 goto :fail
)
echo All projects synced. main branches were not changed.
pause
exit /b 0

:sync
set "DIR="
set "URL="
call set "DIR=%%PROJECT_%1_PATH%%"
call set "URL=%%PROJECT_%1_URL%%"
echo.
echo [Sync %1] !DIR!
if not defined DIR exit /b 1
if not defined URL exit /b 1
if not exist "!DIR!\.git" (echo ERROR: Not a Git project root.&exit /b 1)
git -C "!DIR!" remote get-url "!FORK_REMOTE!" >nul 2>&1 || exit /b 1

rem Do not overwrite working-tree edits or untracked files.
for /f "delims=" %%S in ('git -C "!DIR!" status --porcelain --untracked-files=all') do (echo ERROR: Working tree not clean.&exit /b 1)

rem Refresh Fork refs for --force-with-lease.
git -C "!DIR!" fetch "!FORK_REMOTE!" || exit /b 1

rem Fetch upstream main last; FETCH_HEAD holds the latest upstream commit.
git -C "!DIR!" fetch "!URL!" "!SOURCE_BRANCH!" || exit /b 1

rem Create dev if absent; otherwise overwrite it with FETCH_HEAD.
git -C "!DIR!" show-ref --verify --quiet "refs/heads/!TARGET_BRANCH!"
if errorlevel 1 (
    git -C "!DIR!" switch -c "!TARGET_BRANCH!" FETCH_HEAD || exit /b 1
) else (
    git -C "!DIR!" switch "!TARGET_BRANCH!" || exit /b 1
    git -C "!DIR!" reset --hard FETCH_HEAD || exit /b 1
)

git -C "!DIR!" push --force-with-lease "!FORK_REMOTE!" "!TARGET_BRANCH!:!TARGET_BRANCH!" || exit /b 1
echo OK
exit /b 0

:fail
echo ERROR: Sync stopped. Already synced projects are not rolled back.
pause
exit /b 1