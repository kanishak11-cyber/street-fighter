
@echo off
echo Testing the setup with a random agent...

rem Get current directory (where the script is located)
set PROJECT_DIR=%~dp0
rem Remove trailing backslash
set PROJECT_DIR=%PROJECT_DIR:~0,-1%

echo Using project directory: %PROJECT_DIR%

REM Activate virtual environment
call %PROJECT_DIR%\.venv\Scripts\activate.bat

REM Create gist.py if it doesn't exist
if not exist "%PROJECT_DIR%\gist.py" (
    echo Creating gist.py...
    (
        echo import gym
        echo import diambra.arena
        echo from diambra.arena.stable_baselines3.utils import make_env
        echo.
        echo # Create the environment
        echo env = make_env^(game="sfiii3n", characters=["Ryu"], roles=["P1"], frame_shape=^(84, 84^)^)
        echo env = gym.wrappers.RecordVideo^(env, "videos/", step_trigger=lambda x: x %% 10000 == 0^)
        echo.
        echo # Initialize environment
        echo observation = env.reset^(^)
        echo done = False
        echo.
        echo # Run random agent for 5000 steps
        echo for _ in range^(5000^):
        echo     action = env.action_space.sample^(^)
        echo     observation, reward, done, info = env.step^(action^)
        echo     if done:
        echo         observation = env.reset^(^)
        echo.
        echo # Close environment
        echo env.close^(^)
    ) > "%PROJECT_DIR%\gist.py"
)

REM Create config file if it doesn't exist
if not exist "%PROJECT_DIR%\cfg_files\sfiii3n\sr6_128x4_das_nc.yaml" (
    echo Creating configuration file...
    (
        echo folders:
        echo   parent_dir: "./results/"
        echo   model_name: "sr6_128x4_das_nc"
        echo.
        echo settings:
        echo   game_id: "sfiii3n"
        echo   step_ratio: 6
        echo   frame_shape: [128, 128, 0]
        echo   continue_game: 0.0
        echo   action_space: "discrete"
        echo   characters: "Ryu"
        echo   difficulty: 4
        echo   outfits: 1
        echo.
        echo wrappers_settings:
        echo   normalize_reward: true
        echo   no_attack_buttons_combinations: true
        echo   stack_frames: 4
        echo   dilation: 1
        echo   add_last_action: true
        echo   stack_actions: 12
        echo   scale: true
        echo   exclude_image_scaling: true
        echo   role_relative: true
        echo   flatten: true
        echo   filter_keys: ["action", "own_health", "opp_health", "own_side", "opp_side", "opp_character", "stage", "timer"]
        echo.
        echo policy_kwargs:
        echo   net_arch: [64, 64]
        echo.
        echo ppo_settings:
        echo   gamma: 0.94
        echo   model_checkpoint: "0"
        echo   learning_rate: [2.5e-4, 2.5e-6]
        echo   clip_range: [0.15, 0.025]
        echo   batch_size: 256
        echo   n_epochs: 4
        echo   n_steps: 128
        echo   autosave_freq: 512
        echo   time_steps: 1024
    ) > "%PROJECT_DIR%\cfg_files\sfiii3n\sr6_128x4_das_nc.yaml"
)

REM Run random agent test
echo Running random agent test...
diambra run -r "%PROJECT_DIR%\roms" python gist.py

echo Testing complete!
pause
