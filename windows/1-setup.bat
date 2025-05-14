
@echo off
echo Creating and setting up virtual environment...

rem Get current directory (where the script is located)
set PROJECT_DIR=%~dp0
rem Remove trailing backslash
set PROJECT_DIR=%PROJECT_DIR:~0,-1%

echo Using project directory: %PROJECT_DIR%

REM Create directories
mkdir %PROJECT_DIR%\roms 2>nul
mkdir %PROJECT_DIR%\cfg_files\sfiii3n 2>nul
mkdir %PROJECT_DIR%\output\models 2>nul

REM Create virtual environment
cd %PROJECT_DIR%
python -m venv .venv

REM Activate virtual environment
call %PROJECT_DIR%\.venv\Scripts\activate.bat

REM Install dependencies
python -m pip install --upgrade pip
pip install numpy==1.23
python -m pip install diambra
python -m pip install diambra-arena
pip install diambra-arena[stable-baselines3]

echo Virtual environment setup complete!
echo.
echo Please make sure your ROM file (sfiii3n.zip) is in the roms folder.
echo Path: %PROJECT_DIR%\roms\sfiii3n.zip
echo.
pause
