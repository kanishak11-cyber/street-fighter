@echo off
echo Submitting your AI agent to Diambra...

rem Get current directory (where the script is located)
set PROJECT_DIR=%~dp0
rem Remove trailing backslash
set PROJECT_DIR=%PROJECT_DIR:~0,-1%

echo Using project directory: %PROJECT_DIR%

REM Activate virtual environment
call "%PROJECT_DIR%\.venv\Scripts\activate.bat"

REM Check if model file exists
if not exist "%PROJECT_DIR%\results\sfiii3n\sr6_128x4_das_nc\model\1022.zip" (
    echo ERROR: Model file not found!
    echo Please make sure you have trained the agent first.
    echo Expected model path: %PROJECT_DIR%\results\sfiii3n\sr6_128x4_das_nc\model\1022.zip
    pause
    exit /b 1
)

REM Create output\models directory if it doesn't exist
if not exist "%PROJECT_DIR%\output\models" mkdir "%PROJECT_DIR%\output\models"

REM Copy model file to submission directory
echo Copying model file to submission directory...
copy "%PROJECT_DIR%\results\sfiii3n\sr6_128x4_das_nc\model\model.zip" "%PROJECT_DIR%\output\models\model.zip"

REM Change to models directory
cd "%PROJECT_DIR%\output\models"

REM Create requirements.txt
echo Creating requirements.txt...
echo stable-baselines3 > requirements.txt
echo torch >> requirements.txt
echo numpy==1.23 >> requirements.txt

REM Initialize agent
echo Initializing agent...
diambra agent init .
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Agent initialization failed.
    cd "%PROJECT_DIR%"
    pause
    exit /b 1
)

REM Create a unique version based on date and time
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%b%%a)
for /f "tokens=1-2 delims=: " %%a in ('time /t') do (set mytime=%%a%%b)
set VERSION=v%mydate%%mytime%
echo Using version tag: %VERSION%

REM Submit the agent (this will use WSL automatically if needed)
echo Submitting agent to Diambra...
diambra agent submit --submission.difficulty hard --version %VERSION% .

REM Return to project directory
cd "%PROJECT_DIR%"

echo Submission process complete!
pause