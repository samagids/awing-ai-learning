@echo off
REM build_and_run.bat v10.0.0
REM 0. Auto-deploy webhooks + test connectivity (smart: skips re-auth if not needed)
REM 1. Apply approved contributions (modify Dart data files)
REM 2. Convert the TFLite model (skip if already exists) — uses venv_tf
REM 3. Extract native speaker audio clips from YouTube lesson videos (BEST quality)
REM 4. Generate Edge TTS 6 character voices (boy/girl + young_man/young_woman + man/woman)
REM 5. Install Flutter dependencies
REM 6. Build Flutter project for Android
REM 7. Install on device + launch

setlocal enabledelayedexpansion

echo ============================================
echo  Awing AI Learning - Build and Run (Windows)
echo ============================================
echo.

REM ---- Step 0: Auto-deploy webhooks + test ----
echo [0/7] Deploying webhooks and testing connectivity...
if exist "scripts\setup_and_deploy.py" (
    python scripts\setup_and_deploy.py --webhooks
    python scripts\setup_and_deploy.py --test
) else (
    echo        setup_and_deploy.py not found, skipping.
)
echo.

REM ---- Step 1: Download + Apply Approved Contributions ----
echo [1/7] Checking for approved contributions...
echo        Creating contributions folder if needed...
if not exist "contributions" mkdir contributions
if not exist "contributions\applied" mkdir "contributions\applied"
echo        Checking for approved contributions...
python scripts\apply_contributions.py
if !ERRORLEVEL! neq 0 (
    echo WARNING: Contribution application had errors. Check output above.
) else (
    echo        Contributions step completed.
)
echo.

REM ---- Step 2: TFLite Model ----
echo [2/7] Checking TFLite model...
if exist "assets\model.tflite" (
    echo        model.tflite already exists. Skipping conversion.
) else (
    echo        Model not found. Converting...
    REM Use venv_tf (TensorFlow) for model conversion, fall back to old venv
    if exist "venv_tf\Scripts\activate.bat" (
        call venv_tf\Scripts\activate.bat
    ) else if exist "venv\Scripts\activate.bat" (
        call venv\Scripts\activate.bat
    ) else (
        echo ERROR: venv_tf not found. Run install_dependencies.bat first.
        exit /b 1
    )
    python scripts\convert_model.py
    if !ERRORLEVEL! neq 0 (
        echo ERROR: Model conversion failed.
        exit /b 1
    )
    call deactivate 2>nul
)
echo.

REM ---- Step 3: Native Speaker Alphabet Audio (from YouTube lesson videos) ----
echo [3/7] Extracting native speaker alphabet audio from lesson videos...
echo        Alphabet clips are reliable (letters spoken in order).
echo        Vocabulary uses Edge TTS voices (video word order is unreliable).
call :clean_native_audio
python scripts\extract_audio_clips.py --alphabet-only
if !ERRORLEVEL! neq 0 (
    echo WARNING: Native audio extraction failed. Will use TTS voices only.
)
echo.

REM ---- Step 4: TTS Character Voices (6 voices) ----
echo [4/7] Generating TTS character voice clips...
echo        6 voices: boy/girl (Beginner) + young_man/young_woman (Medium) + man/woman (Expert)
echo        Trying: Google Cloud TTS -^> Edge TTS -^> eSpeak-NG
call :clean_tts_audio
REM Try Google Cloud TTS first (best quality, free tier)
pip install google-cloud-texttospeech --quiet 2>nul
python scripts\generate_audio_google.py generate
if !ERRORLEVEL! neq 0 (
    echo        Google Cloud TTS failed. Trying Edge TTS...
    pip install edge-tts --quiet 2>nul
    python scripts\generate_audio_edge.py generate
    if !ERRORLEVEL! neq 0 (
        echo        Edge TTS failed. Trying eSpeak-NG as last fallback...
        python scripts\generate_audio_espeak.py generate
        if !ERRORLEVEL! neq 0 (
            echo WARNING: All TTS generation failed. App will use built-in TTS fallback.
        )
    )
)
echo.

REM ---- Step 5: Flutter Deps ----
echo [5/7] Installing Flutter dependencies...
call flutter pub get
REM Ignore flutter pub get exit code — OneDrive file locking causes a spurious
REM symlink error even when packages resolve correctly.
echo.

REM ---- Step 6: Build APK ----
echo [6/7] Building Android APK (release)...
call flutter build apk --release
if !ERRORLEVEL! neq 0 (
    echo ERROR: Android build failed.
    exit /b 1
)

echo.
echo [7/7] Installing on connected device...
REM Use setup_and_deploy.py --install for smart device detection + launch
if exist "scripts\setup_and_deploy.py" (
    python scripts\setup_and_deploy.py --install
) else (
    echo        Trying flutter run...
    call flutter run
)

echo.
echo ============================================
echo  Build and run completed!
echo ============================================
pause
goto :eof

:clean_native_audio
REM Delete old native speaker clips from legacy flat directories
for %%C in (alphabet vocabulary) do (
    powershell -NoProfile -Command "if (Test-Path 'assets\audio\%%C\*.mp3') { Remove-Item 'assets\audio\%%C\*.mp3' -Force }"
    powershell -NoProfile -Command "if (Test-Path 'assets\audio\%%C\*.wav') { Remove-Item 'assets\audio\%%C\*.wav' -Force }"
)
goto :eof

:clean_tts_audio
REM Delete old TTS clips from voice directories only (don't touch native clips)
for %%V in (boy girl young_man young_woman man woman) do (
    for %%C in (alphabet vocabulary sentences stories) do (
        powershell -NoProfile -Command "if (Test-Path 'assets\audio\%%V\%%C\*.mp3') { Remove-Item 'assets\audio\%%V\%%C\*.mp3' -Force }"
        powershell -NoProfile -Command "if (Test-Path 'assets\audio\%%V\%%C\*.wav') { Remove-Item 'assets\audio\%%V\%%C\*.wav' -Force }"
    )
)
goto :eof
