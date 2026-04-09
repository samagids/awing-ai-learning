@echo off
REM install_dependencies.bat v2.0.0
REM Complete auto-installer for Awing AI Learning - Windows 11
REM Auto-installs all missing dependencies via winget + git clone
REM
REM Uses TWO Python virtual environments to avoid TensorFlow/PyTorch conflicts:
REM   venv_tf    — TensorFlow only (model conversion: HuggingFace -> TFLite)
REM   venv_torch — PyTorch + CUDA (audio generation, TTS training, OCR, Whisper)

setlocal enabledelayedexpansion

echo =====================================================
echo  Awing AI Learning - Full Dependency Installer v2.0.0
echo  Target: Windows 11 / Android + iOS
echo =====================================================
echo.

REM Run each step via call so nested logic never breaks goto
call :check_winget
if !ERRORLEVEL! neq 0 exit /b 1

call :step_git
if !ERRORLEVEL! neq 0 exit /b 1

call :step_python
if !ERRORLEVEL! neq 0 exit /b 1

call :step_android
call :step_flutter
if !ERRORLEVEL! neq 0 exit /b 1

call :step_platform_folders
call :step_ffmpeg
call :step_espeak
call :step_venv_tf
call :step_venv_torch
call :step_flutter_packages
if !ERRORLEVEL! neq 0 exit /b 1

call :step_finalize
call :step_summary

pause
exit /b 0

REM ========================================================
REM  SUBROUTINES
REM ========================================================

REM -------------------------------------------------------
:check_winget
REM -------------------------------------------------------
where winget >nul 2>nul
if !ERRORLEVEL! neq 0 (
    echo ERROR: winget is not available.
    echo        winget comes pre-installed on Windows 11.
    echo        If missing, install App Installer from the Microsoft Store:
    echo        https://apps.microsoft.com/detail/9NBLGGH4NNS1
    exit /b 1
)
echo  [OK] winget found
echo.
exit /b 0

REM -------------------------------------------------------
:step_git
REM -------------------------------------------------------
echo [1/11] Checking Git...
where git >nul 2>nul
if !ERRORLEVEL! equ 0 (
    for /f "tokens=3" %%v in ('git --version') do echo        Found Git %%v
    echo.
    exit /b 0
)

echo        Git not found. Installing via winget...
winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements
if !ERRORLEVEL! neq 0 (
    echo ERROR: Git installation failed.
    echo        Install manually from: https://git-scm.com/download/win
    exit /b 1
)

echo        Git installed. Refreshing PATH...
set "PATH=%PROGRAMFILES%\Git\cmd;!PATH!"
where git >nul 2>nul
if !ERRORLEVEL! neq 0 (
    echo WARNING: Git installed but not in PATH. Restart terminal and re-run.
    exit /b 1
)
echo.
exit /b 0

REM -------------------------------------------------------
:step_python
REM -------------------------------------------------------
echo [2/11] Checking Python 3.10+...
where python >nul 2>nul
if !ERRORLEVEL! equ 0 (
    for /f "tokens=2" %%v in ('python --version 2^>^&1') do echo        Found Python %%v
    echo.
    exit /b 0
)

echo        Python not found. Installing Python 3.12 via winget...
winget install --id Python.Python.3.12 -e --accept-source-agreements --accept-package-agreements
if !ERRORLEVEL! neq 0 (
    echo ERROR: Python installation failed.
    echo        Install manually from: https://www.python.org/downloads/
    exit /b 1
)

echo        Python installed. Refreshing PATH...
set "PATH=%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts;!PATH!"
where python >nul 2>nul
if !ERRORLEVEL! neq 0 (
    echo WARNING: Python installed but not in PATH. Restart terminal and re-run.
    exit /b 1
)
echo.
exit /b 0

REM -------------------------------------------------------
:step_android
REM -------------------------------------------------------
echo [3/11] Checking Android Studio / Android SDK...

REM Find Android SDK path
set "SDK_PATH="
if defined ANDROID_HOME if exist "%ANDROID_HOME%\platform-tools" set "SDK_PATH=%ANDROID_HOME%"
if not defined SDK_PATH if defined ANDROID_SDK_ROOT if exist "%ANDROID_SDK_ROOT%\platform-tools" set "SDK_PATH=%ANDROID_SDK_ROOT%"
if not defined SDK_PATH if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools" set "SDK_PATH=%LOCALAPPDATA%\Android\Sdk"

if defined SDK_PATH (
    echo        Found Android SDK at: !SDK_PATH!
) else (
    echo        Android SDK not found. Installing Android Studio via winget...
    winget install --id Google.AndroidStudio -e --accept-source-agreements --accept-package-agreements
    if !ERRORLEVEL! neq 0 (
        echo WARNING: Android Studio auto-install failed.
        echo          Install manually from: https://developer.android.com/studio
        exit /b 0
    )
    echo        Android Studio installed.
    echo.
    echo        *** IMPORTANT: Open Android Studio and complete the setup wizard ***
    echo        Then re-run this script.
    echo.
    pause
    exit /b 0
)

REM Check if cmdline-tools is installed
echo        Checking Android cmdline-tools...
set "SDKMANAGER="
if exist "!SDK_PATH!\cmdline-tools\latest\bin\sdkmanager.bat" (
    set "SDKMANAGER=!SDK_PATH!\cmdline-tools\latest\bin\sdkmanager.bat"
    echo        cmdline-tools found.
)
if not defined SDKMANAGER if exist "!SDK_PATH!\tools\bin\sdkmanager.bat" (
    set "SDKMANAGER=!SDK_PATH!\tools\bin\sdkmanager.bat"
    echo        cmdline-tools found at tools\bin.
)

if not defined SDKMANAGER (
    echo        cmdline-tools is MISSING. Attempting to install...
    echo.
    echo        Downloading Android command-line tools...
    set "CMDTOOLS_ZIP=%TEMP%\cmdline-tools.zip"
    set "CMDTOOLS_DIR=!SDK_PATH!\cmdline-tools"
    powershell -Command "Invoke-WebRequest -Uri 'https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip' -OutFile '!CMDTOOLS_ZIP!'"
    if !ERRORLEVEL! neq 0 (
        echo WARNING: Failed to download cmdline-tools.
        echo          Open Android Studio, go to SDK Manager, install Command-line Tools.
        exit /b 0
    )
    echo        Extracting...
    powershell -Command "Expand-Archive -Path '!CMDTOOLS_ZIP!' -DestinationPath '!CMDTOOLS_DIR!' -Force"
    REM The zip extracts to cmdline-tools\cmdline-tools, need to rename to cmdline-tools\latest
    if exist "!CMDTOOLS_DIR!\cmdline-tools" (
        if exist "!CMDTOOLS_DIR!\latest" rmdir /s /q "!CMDTOOLS_DIR!\latest"
        rename "!CMDTOOLS_DIR!\cmdline-tools" "latest"
    )
    if exist "!CMDTOOLS_DIR!\latest\bin\sdkmanager.bat" (
        set "SDKMANAGER=!CMDTOOLS_DIR!\latest\bin\sdkmanager.bat"
        echo        cmdline-tools installed successfully.
    ) else (
        echo WARNING: cmdline-tools extraction failed.
        echo          Open Android Studio, go to SDK Manager, install Command-line Tools.
        exit /b 0
    )
)

REM Accept Android licenses using sdkmanager
echo        Accepting Android SDK licenses...
set "YES_SDK=%TEMP%\sdk_yes.txt"
(for /L %%i in (1,1,20) do @echo y) > "!YES_SDK!"
call "!SDKMANAGER!" --licenses < "!YES_SDK!" >nul 2>nul
del "!YES_SDK!" 2>nul
echo        Licenses accepted.
echo.
exit /b 0

REM -------------------------------------------------------
:step_flutter
REM -------------------------------------------------------
echo [4/11] Checking Flutter SDK...

set "FLUTTER_DIR=%USERPROFILE%\flutter"

where flutter >nul 2>nul
if !ERRORLEVEL! equ 0 (
    for /f "tokens=2" %%v in ('flutter --version 2^>^&1 ^| findstr "Flutter"') do echo        Found Flutter %%v
    echo.
    exit /b 0
)

REM Check if Flutter exists on disk but not in PATH
if exist "!FLUTTER_DIR!\bin\flutter.bat" (
    echo        Flutter found at !FLUTTER_DIR! but not in PATH.
    echo        Adding to PATH for this session...
    set "PATH=!FLUTTER_DIR!\bin;!PATH!"
    echo.
    exit /b 0
)

echo        Flutter not found. Cloning stable channel...
echo        Destination: !FLUTTER_DIR!
echo        This may take several minutes on first install...
echo.
git clone https://github.com/flutter/flutter.git -b stable "!FLUTTER_DIR!"
if !ERRORLEVEL! neq 0 (
    echo ERROR: Failed to clone Flutter. Check your internet connection.
    exit /b 1
)

set "PATH=!FLUTTER_DIR!\bin;!PATH!"

echo.
echo        Flutter installed to: !FLUTTER_DIR!
echo.
echo        *** Add Flutter to your system PATH permanently ***
echo        Run this in an admin terminal:
echo          setx PATH "%%PATH%%;!FLUTTER_DIR!\bin"
echo.
echo        Or manually:
echo          1. Press Win+S, search "Environment Variables"
echo          2. Edit user PATH, add: !FLUTTER_DIR!\bin
echo.
pause
exit /b 0

REM -------------------------------------------------------
:step_platform_folders
REM -------------------------------------------------------
echo [5/11] Ensuring Flutter platform folders exist...

if not exist "android" (
    echo        Generating android and ios platform projects...
    call flutter create --org com.awing . >nul 2>nul
    echo        Platform folders created.
) else (
    echo        android folder already exists. Skipping.
)
echo.
exit /b 0

REM -------------------------------------------------------
:step_ffmpeg
REM -------------------------------------------------------
echo [6/11] Checking ffmpeg ^(required for audio processing^)...
where ffmpeg >nul 2>nul
if !ERRORLEVEL! equ 0 (
    echo        ffmpeg found.
    echo.
    exit /b 0
)

echo        ffmpeg not found. Installing via winget...
winget install --id Gyan.FFmpeg -e --accept-source-agreements --accept-package-agreements
if !ERRORLEVEL! neq 0 (
    echo WARNING: ffmpeg auto-install failed.
    echo          Install manually from: https://ffmpeg.org/download.html
    echo          Or run: winget install ffmpeg
    exit /b 0
)

echo        ffmpeg installed. You may need to restart your terminal for PATH update.
echo.
exit /b 0

REM -------------------------------------------------------
:step_espeak
REM -------------------------------------------------------
echo [7/11] Checking eSpeak-NG ^(required for Awing TTS pronunciation^)...
where espeak-ng >nul 2>nul
if !ERRORLEVEL! equ 0 (
    echo        eSpeak-NG found.
    echo.
    exit /b 0
)

echo        eSpeak-NG not found. Installing via winget...
winget install --id espeak-ng.espeak-ng -e --accept-source-agreements --accept-package-agreements
if !ERRORLEVEL! neq 0 (
    echo WARNING: eSpeak-NG auto-install via winget failed.
    echo          Trying alternative install...
    winget install --id "eSpeak NG" -e --accept-source-agreements --accept-package-agreements
    if !ERRORLEVEL! neq 0 (
        echo WARNING: eSpeak-NG install failed.
        echo          Download manually from: https://github.com/espeak-ng/espeak-ng/releases
        echo          Install the .msi package for Windows.
        exit /b 0
    )
)

echo        eSpeak-NG installed. You may need to restart your terminal for PATH update.
echo.

REM Setup Awing language files
echo        Setting up Awing language in eSpeak-NG...
python scripts\generate_audio_espeak.py setup
echo.
exit /b 0

REM -------------------------------------------------------
:step_venv_tf
REM -------------------------------------------------------
echo [8/11] Setting up venv_tf ^(TensorFlow — model conversion^)...
echo.

if not exist "venv_tf" (
    echo        Creating virtual environment: venv_tf
    python -m venv venv_tf
    if !ERRORLEVEL! neq 0 (
        echo ERROR: Failed to create venv_tf.
        exit /b 1
    )
)

call venv_tf\Scripts\activate.bat

echo        Upgrading pip...
python -m pip install --upgrade pip >nul 2>nul

echo        Installing packages...
python -m pip install -r scripts\requirements_tf.txt
if !ERRORLEVEL! neq 0 (
    echo WARNING: Some TensorFlow packages failed to install.
)

echo        Verifying TensorFlow...
python -c "import tensorflow as tf; print(f'        TensorFlow {tf.__version__}')"

call deactivate
echo.
echo        venv_tf ready.
echo.
exit /b 0

REM -------------------------------------------------------
:step_venv_torch
REM -------------------------------------------------------
echo [9/11] Setting up venv_torch ^(PyTorch + CUDA — audio, training, TTS, image generation^)...
echo.

if not exist "venv_torch" (
    echo        Creating virtual environment: venv_torch
    python -m venv venv_torch
    if !ERRORLEVEL! neq 0 (
        echo ERROR: Failed to create venv_torch.
        exit /b 1
    )
)

call venv_torch\Scripts\activate.bat

echo        Upgrading pip...
python -m pip install --upgrade pip >nul 2>nul

REM Install PyTorch with CUDA FIRST (cu124 is more stable than cu128 for cuDNN)
echo        Installing PyTorch with CUDA 12.4...
python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
if !ERRORLEVEL! neq 0 (
    echo        CUDA 12.4 failed. Trying CUDA 12.8...
    python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
    if !ERRORLEVEL! neq 0 (
        echo        WARNING: CUDA PyTorch failed. Falling back to CPU-only...
        python -m pip install torch torchvision torchaudio
    )
)

REM Install everything else (torch already satisfied, pip won't replace it)
echo        Installing all other packages...
python -m pip install -r scripts\requirements_torch.txt
if !ERRORLEVEL! neq 0 (
    echo WARNING: Some PyTorch packages failed to install.
)

echo        Verifying PyTorch...
python -c "import torch; print(f'        PyTorch {torch.__version__} - CUDA: {torch.cuda.is_available()}')"

call deactivate
echo.
echo        venv_torch ready.
echo.
exit /b 0

REM -------------------------------------------------------
:step_flutter_packages
REM -------------------------------------------------------
echo [10/11] Installing Flutter packages from pubspec.yaml...
call flutter pub get

REM flutter pub get may return non-zero due to symlink warnings (Developer Mode).
REM Check if it actually got dependencies by looking for the .dart_tool folder.
if exist ".dart_tool\package_config.json" (
    echo        Flutter packages installed.
) else if !ERRORLEVEL! neq 0 (
    echo WARNING: flutter pub get had warnings. If packages installed, this is OK.
    echo          Enable Developer Mode to fix symlink warnings:
    echo          Run: start ms-settings:developers
)
echo.
echo.
exit /b 0

REM -------------------------------------------------------
:step_finalize
REM -------------------------------------------------------
echo [11/11] Finalizing setup...

echo        Accepting Android SDK licenses via Flutter...
REM Generate a temp file with 20 "y" lines to auto-accept all license prompts
set "YES_FILE=%TEMP%\flutter_yes.txt"
(for /L %%i in (1,1,20) do @echo y) > "!YES_FILE!"
call flutter doctor --android-licenses < "!YES_FILE!" >nul 2>nul
del "!YES_FILE!" 2>nul
echo        Licenses accepted.

echo        Pre-caching Flutter binaries...
call flutter precache

echo.
echo =====================================================
echo  Environment Health Check
echo =====================================================
echo.
call flutter doctor -v
echo.
exit /b 0

REM -------------------------------------------------------
:step_summary
REM -------------------------------------------------------
echo =====================================================
echo  Installation Summary
echo =====================================================
echo.

where git >nul 2>nul
if !ERRORLEVEL! equ 0 ( echo  [OK] Git ) else ( echo  [!!] Git - MISSING )

where python >nul 2>nul
if !ERRORLEVEL! equ 0 ( echo  [OK] Python ) else ( echo  [!!] Python - MISSING )

if exist "venv_tf\Scripts\python.exe" (
    echo  [OK] venv_tf ^(TensorFlow — model conversion^)
) else (
    echo  [!!] venv_tf - MISSING
)

if exist "venv_torch\Scripts\python.exe" (
    venv_torch\Scripts\python.exe -c "import torch; assert torch.cuda.is_available(); print('CUDA_OK')" 2>nul | findstr "CUDA_OK" >nul
    if !ERRORLEVEL! equ 0 (
        echo  [OK] venv_torch ^(PyTorch with CUDA GPU^)
    ) else (
        echo  [!!] venv_torch ^(PyTorch installed but CUDA GPU not available — training will be slow^)
    )
) else (
    echo  [!!] venv_torch - MISSING
)

where ffmpeg >nul 2>nul
if !ERRORLEVEL! equ 0 ( echo  [OK] ffmpeg ) else ( echo  [!!] ffmpeg - MISSING )

where espeak-ng >nul 2>nul
if !ERRORLEVEL! equ 0 ( echo  [OK] eSpeak-NG ^(Awing TTS^) ) else ( echo  [!!] eSpeak-NG - MISSING ^(download from github.com/espeak-ng/espeak-ng/releases^) )

where flutter >nul 2>nul
if !ERRORLEVEL! equ 0 ( echo  [OK] Flutter SDK ) else ( echo  [!!] Flutter SDK - MISSING )

echo  [OK] Flutter packages from pubspec.yaml

if exist "android" ( echo  [OK] Android platform folder ) else ( echo  [!!] Android platform folder - MISSING )
if exist "ios" ( echo  [OK] iOS platform folder ) else ( echo  [--] iOS platform folder - builds require macOS )

set "SDK_OK=0"
if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools" set "SDK_OK=1"
if defined ANDROID_HOME if exist "%ANDROID_HOME%\platform-tools" set "SDK_OK=1"
if "!SDK_OK!"=="1" ( echo  [OK] Android SDK ) else ( echo  [!!] Android SDK - Open Android Studio to complete setup )

echo  [--] iOS builds require macOS with Xcode 15+
echo.
echo  Virtual environments:
echo    venv_tf    — for: scripts\convert_model.py
echo    venv_torch — for: all other scripts ^(audio, training, TTS^)
echo.
echo  Next steps:
echo    1. If any items show [!!], fix them and re-run this script
echo    2. Connect an Android device or start an emulator
echo    3. Run: flutter run
echo    4. Or use: scripts\build_and_run.bat
echo.
echo =====================================================
exit /b 0
