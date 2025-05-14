#!/usr/bin/env bash
# Universal Diambra Credential Reset Tool
# This script works on Windows, Linux, macOS, and WSL
# For Windows: Run this from Git Bash, WSL, or Cygwin

# Determine if we're using PowerShell
if command -v powershell.exe >/dev/null 2>&1 || command -v powershell >/dev/null 2>&1; then
    HAS_POWERSHELL=true
else
    HAS_POWERSHELL=false
fi

# Detect OS
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    OS_TYPE="Windows"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if grep -q Microsoft /proc/version 2>/dev/null; then
        OS_TYPE="WSL"
    else
        OS_TYPE="Linux"
    fi
else
    # Fallback detection method
    if command -v cmd.exe >/dev/null 2>&1; then
        OS_TYPE="Windows"
    elif [ -d "/mnt/c/Windows" ]; then
        OS_TYPE="WSL"
    elif [ -d "/System/Library/CoreServices" ]; then
        OS_TYPE="macOS"
    else
        OS_TYPE="Linux"
    fi
fi

# Initialize text formatting based on OS
if [[ "$OS_TYPE" == "Windows" && "$HAS_POWERSHELL" != "true" ]]; then
    # Windows without PowerShell - no color support
    bold=""
    normal=""
    green=""
    red=""
    yellow=""
    cyan=""
else
    # Unix or PowerShell environment
    bold=$(tput bold 2>/dev/null || echo "")
    normal=$(tput sgr0 2>/dev/null || echo "")
    green=$(tput setaf 2 2>/dev/null || echo "")
    red=$(tput setaf 1 2>/dev/null || echo "")
    yellow=$(tput setaf 3 2>/dev/null || echo "")
    cyan=$(tput setaf 6 2>/dev/null || echo "")
fi

# Header message
echo "${bold}${cyan}==================================================="
echo "Diambra Universal Credential Reset Tool"
echo "===================================================${normal}"
echo "${yellow}Detected OS: $OS_TYPE${normal}"

# Function for Windows-specific operations
perform_windows_operations() {
    echo "Performing Windows-specific operations..."
    
    # Get user profile path (more reliable than %USERPROFILE%)
    if [ "$HAS_POWERSHELL" = true ]; then
        # Use PowerShell to get paths
        USER_PROFILE=$(powershell -command 'Write-Output $env:USERPROFILE' | tr -d '\r')
        APP_DATA=$(powershell -command 'Write-Output $env:APPDATA' | tr -d '\r')
    else
        # Fallback method if PowerShell isn't available
        USER_PROFILE=$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r')
        APP_DATA=$(cmd.exe /c "echo %APPDATA%" 2>/dev/null | tr -d '\r')
    fi
    
    # Convert to proper paths
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        # Convert Windows path to MSYS/Cygwin format
        USER_PROFILE_DIAMBRA=$(cygpath -u "$USER_PROFILE")"/.diambra"
        APP_DATA_DIAMBRA=$(cygpath -u "$APP_DATA")"/diambra"
    else
        # Direct path
        USER_PROFILE_DIAMBRA="$USER_PROFILE/.diambra"
        APP_DATA_DIAMBRA="$APP_DATA/diambra"
    fi
    
    # Create directories
    mkdir -p "$USER_PROFILE_DIAMBRA"
    mkdir -p "$APP_DATA_DIAMBRA"
    
    # Remove credential files
    rm -f "$USER_PROFILE_DIAMBRA/credentials" 2>/dev/null
    echo "Removed: $USER_PROFILE_DIAMBRA/credentials"
    rm -f "$APP_DATA_DIAMBRA/credentials" 2>/dev/null
    echo "Removed: $APP_DATA_DIAMBRA/credentials"
    
    # Create empty credentials file
    touch "$USER_PROFILE_DIAMBRA/credentials"
    echo "Created: $USER_PROFILE_DIAMBRA/credentials"
    
    # For Docker path mapping
    if [ "$HAS_POWERSHELL" = true ]; then
        # Windows paths with PowerShell format for Docker
        CRED_PATH_FOR_DOCKER=$(powershell -command '$env:USERPROFILE + "\.diambra\credentials"' | tr -d '\r')
        ROMS_PATH_FOR_DOCKER=$(powershell -command '$env:USERPROFILE + "\.diambra\roms"' | tr -d '\r')
    else
        # Windows paths with CMD format for Docker
        CRED_PATH_FOR_DOCKER="$USER_PROFILE_DIAMBRA/credentials"
        ROMS_PATH_FOR_DOCKER="$USER_PROFILE_DIAMBRA/roms"
    fi
    
    return 0
}

# Function for Unix-based operations (Linux/macOS/WSL)
perform_unix_operations() {
    echo "Performing Unix-based operations..."
    
    # Create directory
    mkdir -p "$HOME/.diambra"
    
    # Remove credential file
    rm -f "$HOME/.diambra/credentials" 2>/dev/null
    echo "Removed: $HOME/.diambra/credentials"
    
    # Create empty credentials file
    touch "$HOME/.diambra/credentials"
    echo "Created: $HOME/.diambra/credentials"
    
    # For Docker path mapping
    CRED_PATH_FOR_DOCKER="$HOME/.diambra/credentials"
    ROMS_PATH_FOR_DOCKER="$HOME/.diambra/roms"
    
    return 0
}

# Function for WSL-specific operations
perform_wsl_operations() {
    echo "Performing WSL-specific operations..."
    
    # Perform regular Unix operations
    perform_unix_operations
    
    # Also check Windows locations via WSL path
    WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
    WIN_USER_PROFILE="/mnt/c/Users/$WIN_USER"
    WIN_APPDATA="/mnt/c/Users/$WIN_USER/AppData/Roaming"
    
    # Create Windows directories
    mkdir -p "$WIN_USER_PROFILE/.diambra"
    mkdir -p "$WIN_APPDATA/diambra"
    
    # Remove Windows credential files
    rm -f "$WIN_USER_PROFILE/.diambra/credentials" 2>/dev/null
    echo "Removed: $WIN_USER_PROFILE/.diambra/credentials"
    rm -f "$WIN_APPDATA/diambra/credentials" 2>/dev/null
    echo "Removed: $WIN_APPDATA/diambra/credentials"
    
    # Create empty Windows credentials file
    touch "$WIN_USER_PROFILE/.diambra/credentials"
    echo "Created: $WIN_USER_PROFILE/.diambra/credentials"
    
    return 0
}

# Function to handle Docker operations for all platforms
handle_docker_operations() {
    # Check if Docker is running
    echo "Checking if Docker is running..."
    docker info &>/dev/null
    if [ $? -ne 0 ]; then
        echo "${red}${bold}ERROR: Docker is not running or not installed.${normal}"
        
        if [[ "$OS_TYPE" == "WSL" ]]; then
            echo "Please start Docker Desktop in Windows and ensure WSL integration is enabled."
        elif [[ "$OS_TYPE" == "Windows" ]]; then
            echo "Please start Docker Desktop and try again."
        elif [[ "$OS_TYPE" == "macOS" ]]; then
            echo "Please start Docker Desktop and try again."
        else
            echo "Please start Docker service and try again."
        fi
        
        return 1
    fi
    
    # Check if engine container is running and stop it
    echo "Checking for running engine container..."
    if docker ps -q --filter "name=engine" | grep -q .; then
        echo "Stopping existing engine container..."
        docker stop engine &>/dev/null
        echo "Engine container stopped."
    else
        echo "No running engine container found."
    fi
    
    # Ensure roms directory exists
    if [[ "$OS_TYPE" == "Windows" ]]; then
        mkdir -p "$USER_PROFILE_DIAMBRA/roms"
    elif [[ "$OS_TYPE" == "WSL" ]]; then
        mkdir -p "$HOME/.diambra/roms"
        mkdir -p "$WIN_USER_PROFILE/.diambra/roms"
    else
        mkdir -p "$HOME/.diambra/roms"
    fi
    
    # Start a new engine container with proper path mapping based on OS
    echo "Starting new engine container..."
    
    if [[ "$OS_TYPE" == "Windows" ]]; then
        # Windows-specific docker run command
        if [ "$HAS_POWERSHELL" = true ]; then
            # Using PowerShell to run Docker with proper Windows paths
            powershell -command "
            docker run -d --rm --name engine ``
              -v \"$CRED_PATH_FOR_DOCKER:/tmp/.diambra/credentials\" ``
              -v \"$ROMS_PATH_FOR_DOCKER:/opt/diambraArena/roms\" ``
              -p 127.0.0.1:50051:50051 ``
              docker.io/diambra/engine:latest
            "
        else
            # Using bash syntax for Docker with Windows paths
            docker run -d --rm --name engine \
              -v "$CRED_PATH_FOR_DOCKER:/tmp/.diambra/credentials" \
              -v "$ROMS_PATH_FOR_DOCKER:/opt/diambraArena/roms" \
              -p 127.0.0.1:50051:50051 \
              docker.io/diambra/engine:latest
        fi
    else
        # Unix-based docker run command
        docker run -d --rm --name engine \
          -v "$CRED_PATH_FOR_DOCKER:/tmp/.diambra/credentials" \
          -v "$ROMS_PATH_FOR_DOCKER:/opt/diambraArena/roms" \
          -p 127.0.0.1:50051:50051 \
          docker.io/diambra/engine:latest
    fi
    
    if [ $? -ne 0 ]; then
        echo "${red}${bold}ERROR: Failed to start engine container.${normal}"
        return 1
    else
        echo "${green}Engine container started successfully.${normal}"
    fi
    
    return 0
}

# Perform OS-specific operations
case "$OS_TYPE" in
    "Windows")
        perform_windows_operations
        ;;
    "WSL")
        perform_wsl_operations
        ;;
    *)
        # Linux or macOS
        perform_unix_operations
        ;;
esac

# Handle Docker operations
handle_docker_operations
DOCKER_RESULT=$?

# Final message
if [ $DOCKER_RESULT -eq 0 ]; then
    echo
    echo "${green}${bold}==================================================="
    echo "Credentials reset complete!"
    echo
    echo "Next steps:"
    echo "1. Run 'diambra user login' to log in again"
    echo "2. Verify with 'diambra user info' to check status"
    echo "===================================================${normal}"
    
    # Additional instructions for Windows users
    if [[ "$OS_TYPE" == "Windows" ]]; then
        echo "${yellow}Note for Windows users: Make sure to run the diambra commands"
        echo "from the same command prompt type (CMD or PowerShell) that you"
        echo "typically use with Diambra.${normal}"
    fi
    
    exit 0
else
    echo
    echo "${red}${bold}==================================================="
    echo "Credential reset encountered issues with Docker."
    echo "Please fix Docker issues and try again."
    echo "===================================================${normal}"
    exit 1
fi