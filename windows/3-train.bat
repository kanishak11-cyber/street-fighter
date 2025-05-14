@echo off
echo Training your AI agent...

rem Get current directory (where the script is located)
set PROJECT_DIR=%~dp0
rem Remove trailing backslash
set PROJECT_DIR=%PROJECT_DIR:~0,-1%

echo Using project directory: %PROJECT_DIR%

REM Activate virtual environment
call %PROJECT_DIR%\.venv\Scripts\activate.bat

REM Create training.py if it doesn't exist
if not exist "%PROJECT_DIR%\training.py" (
    echo Creating training.py...
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
        echo         difficulty=cfg["settings"]["difficulty"]
        echo     ^)
        echo.
        echo     # Create model
        echo     if cfg["ppo_settings"].get^("model_checkpoint", "0"^) != "0":
        echo         model = PPO.load^(cfg["ppo_settings"]["model_checkpoint"], env=env^)
        echo         print^(f"Loaded model from {cfg['ppo_settings']['model_checkpoint']}"^)
        echo     else:
        echo         model = PPO^(
        echo             "CnnPolicy",
        echo             env,
        echo             verbose=1,
        echo             batch_size=cfg["ppo_settings"]["batch_size"],
        echo             n_steps=cfg["ppo_settings"]["n_steps"],
        echo             learning_rate=cfg["ppo_settings"]["learning_rate"][0],
        echo             gamma=cfg["ppo_settings"]["gamma"],
        echo             ent_coef=0.01,
        echo             clip_range=cfg["ppo_settings"]["clip_range"][0],
        echo             n_epochs=cfg["ppo_settings"]["n_epochs"],
        echo             gae_lambda=0.95,
        echo             max_grad_norm=0.5,
        echo             vf_coef=0.5,
        echo             device="auto"
        echo         ^)
        echo.
        echo     # Create output directory
        echo     output_dir = os.path.join^(
        echo         cfg["folders"]["parent_dir"],
        echo         cfg["settings"]["game_id"],
        echo         cfg["folders"]["model_name"],
        echo         "model"
        echo     ^)
        echo     os.makedirs^(output_dir, exist_ok=True^)
        echo.
        echo     # Define callback for model saving
        echo     autosave_freq = cfg["ppo_settings"].get^("autosave_freq", 0^)
        echo     if autosave_freq > 0:
        echo         from stable_baselines3.common.callbacks import CheckpointCallback
        echo         checkpoint_callback = CheckpointCallback^(
        echo             save_freq=autosave_freq,
        echo             save_path=output_dir,
        echo             name_prefix="checkpoint"
        echo         ^)
        echo         callbacks = [checkpoint_callback]
        echo     else:
        echo         callbacks = []
        echo.
        echo     # Train model
        echo     model.learn^(
        echo         total_timesteps=cfg["ppo_settings"]["time_steps"],
        echo         callback=callbacks
        echo     ^)
        echo.
        echo     # Save final model
        echo     model.save^(os.path.join^(output_dir, "model"^)^)
        echo.
        echo     # Close environment
        echo     env.close^(^)
        echo.
        echo if __name__ == "__main__":
        echo     main^(^)
    ) > "%PROJECT_DIR%\training.py"
)

REM Ask for parallel environments
echo.
echo How many parallel environments do you want to use for training?
echo - Higher numbers = faster training but more system resources
echo - Recommended: 1-4 for most systems, up to 8 for high-end systems
echo.
set /p parallelEnvs=Enter number of parallel environments (1-8): 

REM Validate input
set /a parallelEnvs=%parallelEnvs%
if %parallelEnvs% LSS 1 set parallelEnvs=1
if %parallelEnvs% GTR 8 set parallelEnvs=8

echo.
echo Starting training with %parallelEnvs% parallel environments...
echo This may take several hours. Progress will be displayed...
echo.

if %parallelEnvs% LEQ 1 (
    diambra run -r "%PROJECT_DIR%\roms" python training.py --cfgFile "%PROJECT_DIR%\cfg_files\sfiii3n\sr6_128x4_das_nc.yaml"
) else (
    diambra run -s %parallelEnvs% -r "%PROJECT_DIR%\roms" python training.py --cfgFile "%PROJECT_DIR%\cfg_files\sfiii3n\sr6_128x4_das_nc.yaml"
)

echo Training complete!
pause
