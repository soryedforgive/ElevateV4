@echo off
setlocal EnableExtensions

set "REPO_URL=https://github.com/soryedforgive/ElevateV4.git"
set "BRANCH=main"
set "PROJECT_DIR=%~dp0"
set "SOURCE=%~dp0"
REM Robocopy misparses a quoted source path ending in a backslash; strip it.
if "%SOURCE:~-1%"=="\" set "SOURCE=%SOURCE:~0,-1%"
set "WORK=%TEMP%\ElevateV4-github-upload"

where git >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Git for Windows is not installed or is not in PATH.
    echo Install Git, sign in to GitHub, then run this file again.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss') | Set-Content -NoNewline -Encoding ascii '%PROJECT_DIR%version.txt'"
if errorlevel 1 (
    echo [ERROR] Could not update version.txt.
    pause
    exit /b 1
)

if exist "%WORK%" rmdir /s /q "%WORK%"
echo [INFO] Cloning %REPO_URL% ...
git clone "%REPO_URL%" "%WORK%"
if errorlevel 1 (
    echo [ERROR] Clone failed. Check the repository name, network connection, and GitHub sign-in.
    pause
    exit /b 1
)

REM Use the existing main branch when it exists; otherwise create it for a new/empty repository.
git -C "%WORK%" show-ref --verify --quiet refs/remotes/origin/%BRANCH%
if not errorlevel 1 (
    git -C "%WORK%" checkout -B "%BRANCH%" "origin/%BRANCH%"
) else (
    git -C "%WORK%" checkout --orphan "%BRANCH%"
)
if errorlevel 1 (
    echo [ERROR] Could not prepare branch %BRANCH%.
    pause
    exit /b 1
)

REM Remove prior repository files while keeping .git and its history.
for /f "delims=" %%I in ('dir /b /a "%WORK%"') do (
    if /I not "%%I"==".git" (
        if exist "%WORK%\%%I\NUL" (
            rmdir /s /q "%WORK%\%%I"
        ) else (
            del /f /q "%WORK%\%%I" >nul 2>&1
        )
    )
)

REM Copy this complete project into the cloned repository.
echo [INFO] Source: "%SOURCE%"
echo [INFO] Destination: "%WORK%"
robocopy "%SOURCE%" "%WORK%" /E /R:2 /W:1 /XD ".git"
if errorlevel 8 (
    echo [ERROR] Robocopy failed while copying the project.
    pause
    exit /b 1
)

cd /d "%WORK%"
git add -A
if errorlevel 1 (
    echo [ERROR] Git could not stage the files.
    pause
    exit /b 1
)

git diff --cached --quiet
if not errorlevel 1 (
    echo [INFO] The remote repository already matches this build.
    pause
    exit /b 0
)

git commit -m "Update ElevateV4 GitHub build"
if errorlevel 1 (
    echo [ERROR] Commit failed. Check your Git name/email configuration.
    pause
    exit /b 1
)

git push -u origin "%BRANCH%"
if errorlevel 1 (
    echo [ERROR] Push failed. Check your GitHub permissions and branch protection settings.
    pause
    exit /b 1
)

echo.
echo [SUCCESS] ElevateV4 was uploaded to soryedforgive/ElevateV4 (%BRANCH%).
echo [INFO] The Roblox loader requires the repository to be public unless you configure an authenticated proxy.
pause
exit /b 0
