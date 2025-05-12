#!/bin/bash

# Text formatting
bold=$(tput bold)
normal=$(tput sgr0)
green=$(tput setaf 2)
red=$(tput setaf 1)
yellow=$(tput setaf 3)

echo "${bold}==================================================="
echo "Diambra Street Fighter III AI Agent - Complete Setup"
echo "===================================================${normal}"

# Get current directory
PROJECT_DIR=$(pwd)
echo "Using project directory: $PROJECT_DIR"

# Function to check command success
check_command() {
    if [ $? -ne 0 ]; then
        echo "${red}${bold}Error: $1${normal}"
        exit 1
    fi
}

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if grep -q Microsoft /proc/version 2>/dev/null; then
        OS_TYPE="WSL"
    else
        OS_TYPE="Linux"
    fi
else
    echo "${red}${bold}Unsupported OS detected. This script supports macOS, Linux, and WSL.${normal}"
    exit 1
fi

echo "${yellow}Detected OS: $OS_TYPE${normal}"

# Step 1: Install Python 3.9 and dependencies
echo
echo "${bold}STEP 1: Installing Python 3.9 and dependencies${normal}"
echo "==================================================="

if [[ "$OS_TYPE" == "macOS" ]]; then
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo "${yellow}Homebrew is not installed. Installing Homebrew...${normal}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for this session if it's not already
        if [[ "$(uname -m)" == "arm64" ]]; then
            # Apple Silicon
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            # Intel
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    else
        echo "${green}Homebrew is already installed.${normal}"
    fi

    # Update Homebrew
    echo "Updating Homebrew..."
    brew update

    # Install Python 3.9
    echo "Installing Python 3.9..."
    brew install python@3.9

    # Check if Python 3.9 was installed
    if ! command -v python3.9 &> /dev/null; then
        echo "${red}${bold}ERROR: Python 3.9 installation failed.${normal}"
        exit 1
    else
        echo "${green}Python 3.9 installed successfully: $(python3.9 --version)${normal}"
    fi
    
    # Check if Docker is installed and running
    echo "Checking if Docker is installed and running..."
    if ! command -v docker &> /dev/null; then
        echo "${yellow}Docker is not installed. Installing Docker...${normal}"
        brew install --cask docker
        
        echo "${yellow}Please open Docker Desktop and complete the setup process.${normal}"
        echo "Once Docker is running, press Enter to continue..."
        open -a Docker
        read -p ""
    else
        # Check if Docker is running
        if ! docker info &> /dev/null; then
            echo "${yellow}Docker is installed but not running.${normal}"
            echo "Starting Docker..."
            open -a Docker
            
            # Wait for Docker to start
            echo "Waiting for Docker to start..."
            while ! docker info &> /dev/null; do
                echo -n "."
                sleep 2
            done
            echo
            echo "${green}Docker is now running.${normal}"
        else
            echo "${green}Docker is installed and running.${normal}"
        fi
    fi
    
    # Define Python command
    PYTHON_CMD="python3.9"
    
elif [[ "$OS_TYPE" == "Linux" || "$OS_TYPE" == "WSL" ]]; then
    # Ensure apt repositories are up to date
    echo "Updating apt repositories..."
    sudo apt update

    # Install required system packages
    echo "Installing required system packages..."
    sudo apt install -y software-properties-common build-essential curl wget

    # Add deadsnakes PPA for Python 3.9
    echo "Adding PPA for Python 3.9..."
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt update

    # Install Python 3.9 and development tools
    echo "Installing Python 3.9 and development tools..."
    sudo apt install -y python3.9 python3.9-venv python3.9-dev

    # Verify Python 3.9 installation
    if ! command -v python3.9 &> /dev/null; then
        echo "${red}${bold}ERROR: Python 3.9 installation failed.${normal}"
        exit 1
    else
        echo "${green}Python 3.9 installed successfully: $(python3.9 --version)${normal}"
    fi

    # Install pip for Python 3.9
    echo "Installing pip for Python 3.9..."
    curl -sS https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    python3.9 get-pip.py
    rm get-pip.py

    # Verify pip installation
    if ! python3.9 -m pip --version &> /dev/null; then
        echo "${red}${bold}ERROR: pip installation for Python 3.9 failed.${normal}"
        exit 1
    else
        echo "${green}pip installed successfully: $(python3.9 -m pip --version)${normal}"
    fi

    # Check if Docker is available
    echo "Checking Docker availability..."
    if ! command -v docker &> /dev/null; then
        echo "${yellow}Docker is not installed.${normal}"
        
        if [[ "$OS_TYPE" == "WSL" ]]; then
            echo "Docker should be available through Docker Desktop for Windows."
            echo "Make sure Docker Desktop is running with WSL integration enabled."
            
            # Check if docker can be accessed
            docker info &> /dev/null
            if [ $? -ne 0 ]; then
                echo "${red}${bold}ERROR: Cannot access Docker.${normal}"
                echo "Please ensure Docker Desktop is running with WSL integration enabled."
                echo "In Docker Desktop settings, go to Resources > WSL Integration and enable it for this WSL distro."
                exit 1
            else
                echo "${green}Docker is accessible through Windows Docker Desktop.${normal}"
            fi
        else
            echo "Installing Docker..."
            sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
            sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
            sudo apt update
            sudo apt install -y docker-ce
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
            
            # Check if docker was installed successfully
            if ! command -v docker &> /dev/null; then
                echo "${red}${bold}ERROR: Docker installation failed.${normal}"
                exit 1
            else
                echo "${green}Docker installed successfully: $(docker --version)${normal}"
                echo "${yellow}NOTE: You may need to log out and log back in for Docker permissions to take effect.${normal}"
            fi
        fi
    else
        echo "${green}Docker is installed: $(docker --version)${normal}"
    fi
    
    # Define Python command
    PYTHON_CMD="python3.9"
fi

# Step 2: Create and activate virtual environment
echo
echo "${bold}STEP 2: Creating Python 3.9 virtual environment${normal}"
echo "==================================================="

# Create virtual environment if it doesn't exist
if [ ! -d "$PROJECT_DIR/venv" ]; then
    echo "Creating virtual environment with Python 3.9..."
    $PYTHON_CMD -m venv venv
    if [ $? -ne 0 ]; then
        echo "${red}${bold}ERROR: Failed to create virtual environment.${normal}"
        echo "Trying to create with system packages..."
        $PYTHON_CMD -m venv venv --system-site-packages
        if [ $? -ne 0 ]; then
            echo "${red}${bold}ERROR: Virtual environment creation failed. Cannot continue.${normal}"
            exit 1
        fi
    fi
else
    echo "Virtual environment already exists."
    
    # Check if it was created with Python 3.9
    if [ -f "$PROJECT_DIR/venv/pyvenv.cfg" ]; then
        VENV_PYTHON_VERSION=$(grep "version" "$PROJECT_DIR/venv/pyvenv.cfg" | cut -d "=" -f 2 | tr -d " ")
        if [[ ! "$VENV_PYTHON_VERSION" =~ ^3\.9\. ]]; then
            echo "${yellow}${bold}WARNING: Existing virtual environment uses Python $VENV_PYTHON_VERSION, not 3.9.${normal}"
            echo "Recreating virtual environment with Python 3.9..."
            rm -rf "$PROJECT_DIR/venv"
            $PYTHON_CMD -m venv venv
            if [ $? -ne 0 ]; then
                echo "${red}${bold}ERROR: Failed to recreate virtual environment with Python 3.9.${normal}"
                exit 1
            fi
        fi
    fi
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate
if [ $? -ne 0 ]; then
    echo "${red}${bold}ERROR: Failed to activate virtual environment.${normal}"
    exit 1
fi

# Verify virtual environment is active and using Python 3.9
if [ -z "$VIRTUAL_ENV" ]; then
    echo "${red}${bold}ERROR: Virtual environment is not active.${normal}"
    exit 1
else
    echo "${green}Virtual environment is active: $VIRTUAL_ENV${normal}"
fi

# Check Python version in virtual environment
VENV_PYTHON_VERSION=$(python --version 2>&1)
if [[ ! "$VENV_PYTHON_VERSION" =~ Python\ 3\.9\. ]]; then
    echo "${red}${bold}ERROR: Virtual environment is not using Python 3.9.${normal}"
    echo "Current version: $VENV_PYTHON_VERSION"
    exit 1
else
    echo "${green}Virtual environment is using $VENV_PYTHON_VERSION${normal}"
fi

# Install Python dependencies
echo "Installing required Python packages..."
python -m pip install --upgrade pip
python -m pip install wheel setuptools
python -m pip install numpy==1.23
python -m pip install "gym<0.27.0,>=0.21.0"
python -m pip install torch pyyaml
python -m pip install diambra
python -m pip install diambra-arena
python -m pip install "diambra-arena[stable-baselines3]"

# Verify critical packages are installed
echo "Verifying key packages..."
python -c "import numpy; print(f'NumPy version: {numpy.__version__}')" || { echo "${red}${bold}ERROR: NumPy installation failed.${normal}"; exit 1; }
python -c "import gym; print(f'Gym version: {gym.__version__}')" || { echo "${red}${bold}ERROR: Gym installation failed.${normal}"; exit 1; }
python -c "import diambra.arena; print('Diambra Arena installed')" || { echo "${red}${bold}ERROR: Diambra Arena installation failed.${normal}"; exit 1; }
python -c "import stable_baselines3; print(f'Stable Baselines 3 version: {stable_baselines3.__version__}')" || { echo "${red}${bold}ERROR: Stable Baselines 3 installation failed.${normal}"; exit 1; }

# Determine how to call diambra
if command -v diambra &> /dev/null; then
    DIAMBRA_CLI="diambra"
else
    DIAMBRA_CLI="$VIRTUAL_ENV/bin/diambra"
    if [ ! -f "$DIAMBRA_CLI" ]; then
        echo "${red}${bold}ERROR: Diambra CLI not found at expected location.${normal}"
        exit 1
    fi
fi

echo "${green}${bold}Diambra CLI is installed: $($DIAMBRA_CLI --version 2>&1 || echo 'version info not available')${normal}"
echo "${green}${bold}Dependencies installed successfully!${normal}"

# Step 3: Prepare project files
echo
echo "${bold}STEP 3: Preparing project files${normal}"
echo "==================================================="

# Create necessary directories
mkdir -p "$PROJECT_DIR/roms"
mkdir -p "$PROJECT_DIR/cfg_files/sfiii3n"
mkdir -p "$PROJECT_DIR/output/models"

# Check if ROM file exists
if [ ! -f "$PROJECT_DIR/roms/sfiii3n.zip" ]; then
    echo "${yellow}${bold}ROM file not found: $PROJECT_DIR/roms/sfiii3n.zip${normal}"
    echo "Please copy the Street Fighter III ROM (sfiii3n.zip) to the roms folder."
    
    if [[ "$OS_TYPE" == "WSL" ]]; then
        echo "In Windows Explorer, you can access the WSL file system by typing: \\\\wsl$"
    fi
    
    echo
    read -p "Press Enter once you've added the ROM file..."
    
    # Check again after user input
    if [ ! -f "$PROJECT_DIR/roms/sfiii3n.zip" ]; then
        echo "${red}${bold}ROM file still not found. Cannot continue.${normal}"
        exit 1
    fi
else
    echo "${green}ROM file found!${normal}"
fi

# Create configuration file
echo "Creating configuration file..."
cat > "$PROJECT_DIR/cfg_files/sfiii3n/sr6_128x4_das_nc.yaml" << EOF
folders:
  parent_dir: "./results/"
  model_name: "sr6_128x4_das_nc"

#'Alex', 'Twelve', 'Hugo', 'Sean', 'Makoto', 'Elena', 'Ibuki', 'Chun-Li', 'Dudley', 'Necro', 'Q', 'Oro', 'Urien', 'Remy', 'Ryu', 'Gouki', 'Yun', 'Yang', 'Ken', 'Gill'
settings:
  game_id: "sfiii3n"
  step_ratio: 6
  frame_shape: !!python/tuple [128, 128, 0]
  continue_game: 0.0
  action_space: "discrete"
  characters: "Ryu"
  difficulty: 4
  outfits: 1

wrappers_settings:
  normalize_reward: true
  no_attack_buttons_combinations: true
  stack_frames: 4
  dilation: 1
  add_last_action: true
  stack_actions: 12
  scale: true
  exclude_image_scaling: true
  role_relative: true
  flatten: true
  filter_keys: ["action", "own_health", "opp_health", "own_side", "opp_side", "opp_character", "stage", "timer"]

policy_kwargs:
  #net_arch: [{ pi: [64, 64], vf: [32, 32] }]
  net_arch: [64, 64]

ppo_settings:
  gamma: 0.94
  model_checkpoint: "0"
  learning_rate: [2.5e-4, 2.5e-6] # To start
  clip_range: [0.15, 0.025] # To start
  #learning_rate: [5.0e-5, 2.5e-6] # Fine Tuning
  #clip_range: [0.075, 0.025] # Fine Tuning
  batch_size: 256 #8 #nminibatches gave different batch size depending on the number of environments: batch_size = (n_steps * n_envs) // nminibatches
  n_epochs: 4
  n_steps: 128
  autosave_freq: 512
  time_steps: 1022
EOF

# Create gist.py
echo "Creating gist.py..."
cat > "$PROJECT_DIR/gist.py" << 'EOF'
#!/usr/bin/env python3
import diambra.arena

def main():
    # Environment creation
    env = diambra.arena.make("sfiii3n", render_mode="human")

    # Environment reset
    observation, info = env.reset(seed=42)

    # Agent-Environment interaction loop
    while True:
        # (Optional) Environment rendering
        env.render()

        # Action random sampling
        actions = env.action_space.sample()

        # Environment stepping
        observation, reward, terminated, truncated, info = env.step(actions)

        # Episode end (Done condition) check
        if terminated or truncated:
            observation, info = env.reset()
            break

    # Environment shutdown
    env.close()

    # Return success
    return 0

if __name__ == '__main__':
    main()
EOF

# Create training.py
echo "Creating training.py..."
cat > "$PROJECT_DIR/training.py" << 'EOF'
import os
import yaml
import json
import argparse
from diambra.arena import load_settings_flat_dict, SpaceTypes
from diambra.arena.stable_baselines3.make_sb3_env import make_sb3_env, EnvironmentSettings, WrappersSettings
from diambra.arena.stable_baselines3.sb3_utils import linear_schedule, AutoSave
from stable_baselines3 import PPO

# diambra run -s 8 python stable_baselines3/training.py --cfgFile $PWD/stable_baselines3/cfg_files/sfiii3n/sr6_128x4_das_nc.yaml

def main(cfg_file):
    # Read the cfg file
    yaml_file = open(cfg_file)
    params = yaml.load(yaml_file, Loader=yaml.FullLoader)
    print("Config parameters = ", json.dumps(params, sort_keys=True, indent=4))
    yaml_file.close()

    base_path = os.path.dirname(os.path.abspath(__file__))
    model_folder = os.path.join(base_path, params["folders"]["parent_dir"], params["settings"]["game_id"],
                                params["folders"]["model_name"], "model")
    tensor_board_folder = os.path.join(base_path, params["folders"]["parent_dir"], params["settings"]["game_id"],
                                        params["folders"]["model_name"], "tb")

    os.makedirs(model_folder, exist_ok=True)

    # Settings
    params["settings"]["action_space"] = SpaceTypes.DISCRETE if params["settings"]["action_space"] == "discrete" else SpaceTypes.MULTI_DISCRETE
    settings = load_settings_flat_dict(EnvironmentSettings, params["settings"])

    # Wrappers Settings
    wrappers_settings = load_settings_flat_dict(WrappersSettings, params["wrappers_settings"])

    # Create environment
    env, num_envs = make_sb3_env(settings.game_id, settings, wrappers_settings,render_mode="human")
    print("Activated {} environment(s)".format(num_envs))

    # Policy param
    policy_kwargs = params["policy_kwargs"]

    # PPO settings
    ppo_settings = params["ppo_settings"]
    gamma = ppo_settings["gamma"]
    model_checkpoint = ppo_settings["model_checkpoint"]

    learning_rate = linear_schedule(ppo_settings["learning_rate"][0], ppo_settings["learning_rate"][1])
    clip_range = linear_schedule(ppo_settings["clip_range"][0], ppo_settings["clip_range"][1])
    clip_range_vf = clip_range
    batch_size = ppo_settings["batch_size"]
    n_epochs = ppo_settings["n_epochs"]
    n_steps = ppo_settings["n_steps"]

    if model_checkpoint == "0":
        # Initialize the agent
        agent = PPO("MultiInputPolicy", env, verbose=1,
                    gamma=gamma, batch_size=batch_size,
                    n_epochs=n_epochs, n_steps=n_steps,
                    learning_rate=learning_rate, clip_range=clip_range,
                    clip_range_vf=clip_range_vf, policy_kwargs=policy_kwargs,
                    tensorboard_log=tensor_board_folder)
    else:
        # Load the trained agent
        agent = PPO.load(os.path.join(model_folder, model_checkpoint), env=env,
                         gamma=gamma, learning_rate=learning_rate, clip_range=clip_range,
                         clip_range_vf=clip_range_vf, policy_kwargs=policy_kwargs,
                         tensorboard_log=tensor_board_folder)


    # Print policy network architecture
    print("Policy architecture:")
    print(agent.policy)

    # Create the callback: autosave every USER DEF steps
    autosave_freq = ppo_settings["autosave_freq"]
    auto_save_callback = AutoSave(check_freq=autosave_freq, num_envs=num_envs,
                                  save_path=model_folder, filename_prefix=model_checkpoint + "_")

    # Train the agent
    time_steps = ppo_settings["time_steps"]
    agent.learn(total_timesteps=time_steps, callback=auto_save_callback)

    # Save the agent
    new_model_checkpoint = str(int(model_checkpoint) + time_steps)
    model_path = os.path.join(model_folder, new_model_checkpoint)
    agent.save(model_path)

    # Close the environment
    env.close()

    # Return success
    return 0

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--cfgFile", type=str, required=True, help="Configuration file")
    opt = parser.parse_args()
    print(opt)

    main(opt.cfgFile)
EOF

# Create evaluate.py
echo "Creating evaluate.py..."
cat > "$PROJECT_DIR/evaluate.py" << 'EOF'
import os
import yaml
import json
import argparse
from diambra.arena import load_settings_flat_dict, SpaceTypes
from diambra.arena.stable_baselines3.make_sb3_env import make_sb3_env, EnvironmentSettings, WrappersSettings
from stable_baselines3.common.evaluation import evaluate_policy
from stable_baselines3 import PPO

# diambra run -s 8 python stable_baselines3/training.py --cfgFile $PWD/stable_baselines3/cfg_files/sfiii3n/sr6_128x4_das_nc.yaml

def main(cfg_file, model_file):
    # Read the cfg file
    yaml_file = open(cfg_file)
    params = yaml.load(yaml_file, Loader=yaml.FullLoader)
    print("Config parameters = ", json.dumps(params, sort_keys=True, indent=4))
    yaml_file.close()

    # Settings
    params["settings"]["action_space"] = SpaceTypes.DISCRETE if params["settings"]["action_space"] == "discrete" else SpaceTypes.MULTI_DISCRETE
    settings = load_settings_flat_dict(EnvironmentSettings, params["settings"])

    # Wrappers Settings
    wrappers_settings = load_settings_flat_dict(WrappersSettings, params["wrappers_settings"])

    # Create environment
    env, num_envs = make_sb3_env(settings.game_id, settings, wrappers_settings,render_mode="human")

    env.render_mode="human"
    
    print("Activated {} environment(s)".format(num_envs))

    agent = PPO.load(model_file)

    # Evaluate the agent
    # NOTE: If you use wrappers with your environment that modify rewards,
    #       this will be reflected here. To evaluate with original rewards,
    #       wrap environment in a "Monitor" wrapper before other wrappers.
    mean_reward, std_reward = evaluate_policy(agent, env, deterministic=False, n_eval_episodes=10)
    print("Reward: {} (avg) ± {} (std)".format(mean_reward, std_reward))

    # Run trained agent
    observation = env.reset()
    cumulative_reward = 0
    while True:
        env.render()

        action, _state = agent.predict(observation, deterministic=False)
        observation, reward, done, info = env.step(action)

        cumulative_reward += reward
        if (reward != 0):
            print("Cumulative reward =", cumulative_reward)

        if done:
            observation = env.reset()
            break

    # Close the environment
    env.close()

    # Return success
    return 0

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--cfgFile", type=str, required=True, help="Configuration file")
    parser.add_argument("--modelFile", type=str, required=True, help="Model file")
    opt = parser.parse_args()
    print(opt)

    main(opt.cfgFile, opt.modelFile)
EOF

echo "${green}${bold}All necessary files created!${normal}"

# Step 4: Check Diambra login status
echo
echo "${bold}STEP 4: Checking Diambra login status${normal}"
echo "==================================================="

# Check if user is logged in
echo "Checking Diambra login status..."
$DIAMBRA_CLI user info &> /dev/null
if [ $? -ne 0 ]; then
    echo "Please log in to your Diambra account:"
    $DIAMBRA_CLI user login
else
    echo "${green}Already logged in to Diambra account.${normal}"
fi

# Step 5: Menu for actions
echo
echo "${bold}STEP 5: Choose an action${normal}"
echo "==================================================="
echo "1. Test setup with random agent (quick)"
echo "2. Train agent (takes time)"
echo "3. Evaluate trained agent"
echo "4. Submit agent"
echo "5. Do everything in sequence"
echo "6. Exit"
echo

read -p "Enter your choice (1-6): " ACTION_CHOICE

case $ACTION_CHOICE in
    1)
        echo
        echo "${bold}Testing setup with random agent...${normal}"
        $DIAMBRA_CLI run -r "$PROJECT_DIR/roms" python gist.py
        ;;
    2)
        echo
        echo "${bold}Starting agent training...${normal}"
        echo "How many parallel environments do you want to use for training?"
        echo "Higher numbers = faster training but more system resources"
        echo "Recommended: 1-4 for most systems, up to 8 for high-end systems"
        read -p "Enter number of parallel environments (1-8): " parallelEnvs
        
        # Validate input
        if ! [[ "$parallelEnvs" =~ ^[0-9]+$ ]]; then
            parallelEnvs=1
        fi
        
        if [ "$parallelEnvs" -lt 1 ]; then
            parallelEnvs=1
        fi
        
        if [ "$parallelEnvs" -gt 8 ]; then
            parallelEnvs=8
        fi
        
        echo "Starting training with $parallelEnvs parallel environments..."
        echo "This may take several hours. Progress will be displayed..."
        
        if [ "$parallelEnvs" -le 1 ]; then
            $DIAMBRA_CLI run -r "$PROJECT_DIR/roms" python training.py --cfgFile "$PROJECT_DIR/cfg_files/sfiii3n/sr6_128x4_das_nc.yaml"
        else
            $DIAMBRA_CLI run -s "$parallelEnvs" -r "$PROJECT_DIR/roms" python training.py --cfgFile "$PROJECT_DIR/cfg_files/sfiii3n/sr6_128x4_das_nc.yaml"
        fi
        ;;
    3)
        echo
        echo "${bold}Evaluating trained agent...${normal}"
        
        if [ ! -f "$PROJECT_DIR/results/sfiii3n/sr6_128x4_das_nc/model/1022.zip" ]; then
            echo "${red}ERROR: Model file not found!${normal}"
            echo "Please make sure you have trained the agent first."
            echo "Expected model path: $PROJECT_DIR/results/sfiii3n/sr6_128x4_das_nc/model/1022.zip"
        else
            $DIAMBRA_CLI run -r "$PROJECT_DIR/roms" python evaluate.py --cfgFile "$PROJECT_DIR/cfg_files/sfiii3n/sr6_128x4_das_nc.yaml" --modelFile "$PROJECT_DIR/results/sfiii3n/sr6_128x4_das_nc/model/1022.zip"
        fi
        ;;
    4)
        echo
        echo "${bold}Submitting agent to Diambra...${normal}"
        
        if [ ! -f "$PROJECT_DIR/results/sfiii3n/sr6_128x4_das_nc/model/1022.zip" ]; then
            echo "${red}ERROR: Model file not found!${normal}"
            echo "Please make sure you have trained the agent first."
            echo "Expected model path: $PROJECT_DIR/results/sfiii3n/sr6_128x4_das_nc/model/1022.zip"
        else
            # Copy model file to submission directory
            echo "Copying model file to submission directory..."
            cp "$PROJECT_DIR/results/sfiii3n/sr6_128x4_das_nc/model/1022.zip" "$PROJECT_DIR/output/models/1022.zip"
            
            # Change to models directory
            cd "$PROJECT_DIR/output/models"
            
            # Create requirements.txt
            echo "Creating requirements.txt..."
            echo "stable-baselines3" > requirements.txt
            echo "torch" >> requirements.txt
            echo "numpy==1.23" >> requirements.txt
            
            # Initialize agent
            echo "Initializing agent..."
            $DIAMBRA_CLI agent init .
            
            # Create unique version
            VERSION="v$(date +%Y%m%d%H%M)"
            echo "Using version tag: $VERSION"
            
            # Submit agent
            echo "Submitting agent to Diambra..."
            $DIAMBRA_CLI agent submit --submission.difficulty hard --version "$VERSION" .
            
            # Return to project directory
            cd "$PROJECT_DIR"
        fi
        ;;
    5)
        echo
        echo "${bold}Starting complete process (test, train, evaluate, submit)...${normal}"
        
        # Test with random agent
        echo
        echo "${bold}Step 1: Testing setup with random agent...${normal}"
        $DIAMBRA_CLI run -r "$PROJECT_DIR/roms" python gist.py
        
        # Train agent
        echo
        echo "${bold}Step 2: Training agent...${normal}"
        echo "How many parallel environments do you want to use for training?"
        echo "Higher numbers = faster training but more system resources"
        echo "Recommended: 1-4 for most systems, up to 8 for high-end systems"
        read -p "Enter number of parallel environments (1-8): " parallelEnvs
        
        # Validate input
        if ! [[ "$parallelEnvs" =~ ^[0-9]+$ ]]; then
            parallelEnvs=1
        fi
        
        if [ "$parallelEnvs" -lt 1 ]; then
            parallelEnvs=1
        fi
        
        if [ "$parallelEnvs" -gt 8 ]; then
            parallelEnvs=8
        fi
        
        echo "Starting training with $parallelEnvs parallel environments..."
        echo "This may take several hours. Progress will be displayed..."
        
       if [ "$parallelEnvs" -le 1 ]; then
            $DIAMBRA_CLI run -r "$PROJECT_DIR/roms" python training.py --cfgFile "$PROJECT_DIR/cfg_files/sfiii3n/sr6_128x4_das_nc.yaml"
        else
            $DIAMBRA_CLI run -s "$parallelEnvs" -r "$PROJECT_DIR/roms" python training.py --cfgFile "$PROJECT_DIR/cfg_files/sfiii3n/sr6_128x4_das_nc.yaml"
        fi
        
        # Check if training was successful
        if [ ! -f "$PROJECT_DIR/results/sfiii3n/sr6_128x4_das_nc/model/1022.zip" ]; then
            echo "${red}ERROR: Training failed. Model file not created.${normal}"
            exit 1
        fi
        
        # Evaluate agent
        echo
        echo "${bold}Step 3: Evaluating trained agent...${normal}"
        $DIAMBRA_CLI run -r "$PROJECT_DIR/roms" python evaluate.py --cfgFile "$PROJECT_DIR/cfg_files/sfiii3n/sr6_128x4_das_nc.yaml" --modelFile "$PROJECT_DIR/results/sfiii3n/sr6_128x4_das_nc/model/1022.zip"
        
        # Submit agent
        echo
        echo "${bold}Step 4: Submitting agent to Diambra...${normal}"
        
        # Copy model file to submission directory
        echo "Copying model file to submission directory..."
        cp "$PROJECT_DIR/results/sfiii3n/sr6_128x4_das_nc/model/1022.zip" "$PROJECT_DIR/output/models/1022.zip"
        
        # Change to models directory
        cd "$PROJECT_DIR/output/models"
        
        # Create requirements.txt
        echo "Creating requirements.txt..."
        echo "stable-baselines3" > requirements.txt
        echo "torch" >> requirements.txt
        echo "numpy==1.23" >> requirements.txt
        
        # Initialize agent
        echo "Initializing agent..."
        $DIAMBRA_CLI agent init .
        
        # Create unique version
        VERSION="v$(date +%Y%m%d%H%M)"
        echo "Using version tag: $VERSION"
        
        # Submit agent
        echo "Submitting agent to Diambra..."
        $DIAMBRA_CLI agent submit --submission.difficulty hard --version "$VERSION" .
        
        # Return to project directory
        cd "$PROJECT_DIR"
        ;;
    6)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "${red}Invalid choice. Please run the script again and select a valid option.${normal}"
        exit 1
        ;;
esac

echo
echo "${green}${bold}Process completed!${normal}"
echo "You can view your submission status on the Diambra website."