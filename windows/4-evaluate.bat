@echo off
echo Evaluating your trained AI agent...

rem Get current directory (where the script is located)
set PROJECT_DIR=%~dp0
rem Remove trailing backslash
set PROJECT_DIR=%PROJECT_DIR:~0,-1%

echo Using project directory: %PROJECT_DIR%

REM Activate virtual environment
call %PROJECT_DIR%\.venv\Scripts\activate.bat

REM Create evaluate.py if it doesn't exist
if not exist "%PROJECT_DIR%\evaluate.py" (
    echo Creating evaluate.py...
    (
        echo import os
        echo import sys
        echo import yaml
        echo import argparse
        echo import numpy as np
        echo from stable_baselines3 import PPO
        echo import gym
        echo import diambra.arena
        echo from diambra.arena.stable_baselines3.wrappers import SB3Wrapper
        echo.
        echo def parse_args^(^):
        echo     parser = argparse.ArgumentParser^(^)
        echo     parser.add_argument^("--cfgFile", type=str, required=True, help="Configuration file"^)
        echo     parser.add_argument^("--modelFile", type=str, required=True, help="Model file"^)
        echo     parser.add_argument^("--numEpisodes", type=int, default=10, help="Number of episodes"^)
        echo     return parser.parse_args^(^)
        echo.
        echo def main^(^):
        echo     # Parse arguments
        echo     args = parse_args^(^)
        echo.
        echo     # Load configuration
        echo     with open^(args.cfgFile, 'r'^) as f:
        echo         cfg = yaml.safe_load^(f^)
        echo.
        echo     # Create environment
        echo     env = SB3Wrapper^(
        echo         game=cfg["settings"]["game_id"],
        echo         characters=cfg["settings"]["characters"],
        echo         roles=["P1"],
        echo         frame_shape=cfg["settings"]["frame_shape"],
        echo         step_ratio=cfg["settings"]["step_ratio"],
        echo         difficulty=cfg["settings"]["difficulty"],
        echo         record=True,
        echo         render=True
        echo     ^)
        echo.
        echo     # Load model
        echo     model = PPO.load^(args.modelFile, env=env^)
        echo.
        echo     # Evaluation loop
        echo     episode_rewards = []
        echo     for episode in range^(args.numEpisodes^):
        echo         obs = env.reset^(^)
        echo         done = False
        echo         total_reward = 0
        echo.
        echo         while not done:
        echo             action, _ = model.predict^(obs, deterministic=True^)
        echo             obs, reward, done, info = env.step^(action^)
        echo             total_reward += reward
        echo.
        echo         episode_rewards.append^(total_reward^)
        echo         print^(f"Episode {episode+1}/{args.numEpisodes}, Reward: {total_reward}"^)
        echo.
        echo     # Print summary
        echo     print^(f"\nEvaluation Summary:"^)
        echo     print^(f"Average Reward: {np.mean^(episode_rewards^):.2f}"^)
        echo     print^(f"Minimum Reward: {np.min^(episode_rewards^):.2f}"^)
        echo     print^(f"Maximum Reward: {np.max^(episode_rewards^):.2f}"^)
        echo.
        echo     # Close environment
        echo     env.close^(^)
        echo.
        echo if __name__ == "__main__":
        echo     main^(^)
    ) > "%PROJECT_DIR%\evaluate.py"
)

REM Check if model file exists
if not exist "%PROJECT_DIR%\results\sfiii3n\sr6_128x4_das_nc\model\1022.zip" (
    echo ERROR: Model file not found!
    echo Please make sure you have trained the agent first.
    echo Expected model path: %PROJECT_DIR%\results\sfiii3n\sr6_128x4_das_nc\model\1022.zip
    pause
    exit /b 1
)

echo Running evaluation...
diambra run -r "%PROJECT_DIR%\roms" python evaluate.py --cfgFile "%PROJECT_DIR%\cfg_files\sfiii3n\sr6_128x4_das_nc.yaml" --modelFile "%PROJECT_DIR%\results\sfiii3n\sr6_128x4_das_nc\model\1022.zip"

echo Evaluation complete!
pause
