@echo off
setlocal
cd /d "%~dp0"
echo.
echo ==============================================
echo THE CROCHET THEORY - Windows Dependency Repair
echo ==============================================
echo.
where node >nul 2>nul
if errorlevel 1 (
  echo ERROR: Node.js is not installed or is not available in PATH.
  pause
  exit /b 1
)
where npm >nul 2>nul
if errorlevel 1 (
  echo ERROR: npm is not installed or is not available in PATH.
  pause
  exit /b 1
)
node scripts\repair-dependencies.js
if errorlevel 1 (
  echo.
  echo Repair failed. Check the npm error shown above.
  pause
  exit /b 1
)
echo.
echo Repair finished. Starting the development server on port 3000...
npm run dev
pause
