@echo off
REM espeak_prepare_and_generate.bat v1.0.0
REM Complete Awing eSpeak-NG TTS pipeline — setup, compile, generate all audio
REM Replaces the old VITS training pipeline (prepare_and_train.bat)
REM Run this after install_dependencies.bat has been run at least once.

setlocal enabledelayedexpansion

echo =====================================================
echo  Awing AI Learning - eSpeak-NG TTS Pipeline v1.0.0
echo  Custom Awing language for eSpeak-NG
echo =====================================================
echo.

REM Run each step via call so nested logic never breaks goto
call :step_check_env
if !ERRORLEVEL! neq 0 goto :failed

call :step_setup
if !ERRORLEVEL! neq 0 goto :failed

call :step_generate
if !ERRORLEVEL! neq 0 goto :failed

call :step_generate_all
if !ERRORLEVEL! neq 0 goto :failed

call :step_summary
pause
exit /b 0

:failed
echo.
echo =====================================================
echo  Pipeline FAILED. Check errors above.
echo =====================================================
pause
exit /b 1

REM ========================================================
REM  SUBROUTINES
REM ========================================================

REM -------------------------------------------------------
:step_check_env
REM -------------------------------------------------------
echo [1/4] Checking environment...

REM Check eSpeak-NG is installed
where espeak-ng >nul 2>nul
if !ERRORLEVEL! neq 0 (
    REM Check Program Files directly
    if exist "C:\Program Files\eSpeak NG\espeak-ng.exe" (
        echo        eSpeak-NG found in Program Files.
    ) else (
        echo        ERROR: eSpeak-NG not found.
        echo        Install from: https://github.com/espeak-ng/espeak-ng/releases
        echo        Download: espeak-ng-X64.msi
        exit /b 1
    )
) else (
    echo        eSpeak-NG found.
)

REM Check Python
where python >nul 2>nul
if !ERRORLEVEL! neq 0 (
    echo        ERROR: Python not found.
    echo        Run scripts\install_dependencies.bat first.
    exit /b 1
)
echo        Python found.

REM Check ffmpeg
where ffmpeg >nul 2>nul
if !ERRORLEVEL! neq 0 (
    echo        WARNING: ffmpeg not found. Audio will be saved as WAV instead of MP3.
    echo        Install: winget install Gyan.FFmpeg
) else (
    echo        ffmpeg found.
)

REM Check git (needed for downloading phsource from GitHub)
where git >nul 2>nul
if !ERRORLEVEL! neq 0 (
    echo        ERROR: git not found. Required for first-time setup.
    echo        Install: winget install Git.Git
    exit /b 1
)
echo        git found.

echo        Environment OK.
echo.
exit /b 0

REM -------------------------------------------------------
:step_setup
REM -------------------------------------------------------
echo [2/4] SETUP — Checking eSpeak-NG and testing phonemizer...
echo        - Verifies eSpeak-NG installation
echo        - Python phonemizer converts Awing text to eSpeak phonemes
echo        - No dictionary compilation needed ^(all done in Python^)
echo.

python scripts\generate_audio_espeak.py setup
if !ERRORLEVEL! neq 0 (
    echo        ERROR: eSpeak-NG setup failed. Check output above.
    exit /b 1
)
echo.
exit /b 0

REM -------------------------------------------------------
:step_generate
REM -------------------------------------------------------
echo [3/4] GENERATE — Creating app audio clips...
echo        Generating alphabet ^(31^) + vocabulary ^(67^) + sentences + stories
echo        using the custom Awing eSpeak-NG voice.
echo.

python scripts\generate_audio_espeak.py generate
if !ERRORLEVEL! neq 0 (
    echo        ERROR: Audio generation failed. Check output above.
    exit /b 1
)
echo.
exit /b 0

REM -------------------------------------------------------
:step_generate_all
REM -------------------------------------------------------
echo [4/4] GENERATE-ALL — Creating dictionary audio clips...
echo        Generating audio for all Awing dictionary words.
echo        This makes the app speak any Awing text fluently.
echo.

python scripts\generate_audio_espeak.py generate-all
if !ERRORLEVEL! neq 0 (
    echo        WARNING: Full dictionary generation had issues.
    echo        The app will still work with TTS fallback for missing words.
)
echo.
exit /b 0

REM -------------------------------------------------------
:step_summary
REM -------------------------------------------------------
echo =====================================================
echo  eSpeak-NG TTS Pipeline Complete!
echo =====================================================
echo.

set "ALPHA_COUNT=0"
set "VOCAB_COUNT=0"
set "SENT_COUNT=0"
set "DICT_COUNT=0"
if exist "assets\audio\alphabet" (
    for %%f in (assets\audio\alphabet\*.mp3) do set /a ALPHA_COUNT+=1
    for %%f in (assets\audio\alphabet\*.wav) do set /a ALPHA_COUNT+=1
)
if exist "assets\audio\vocabulary" (
    for %%f in (assets\audio\vocabulary\*.mp3) do set /a VOCAB_COUNT+=1
    for %%f in (assets\audio\vocabulary\*.wav) do set /a VOCAB_COUNT+=1
)
if exist "assets\audio\sentences" (
    for %%f in (assets\audio\sentences\*.mp3) do set /a SENT_COUNT+=1
    for %%f in (assets\audio\sentences\*.wav) do set /a SENT_COUNT+=1
)
if exist "assets\audio\dictionary" (
    for %%f in (assets\audio\dictionary\*.mp3) do set /a DICT_COUNT+=1
    for %%f in (assets\audio\dictionary\*.wav) do set /a DICT_COUNT+=1
)

echo  Alphabet clips:    !ALPHA_COUNT! / 31
echo  Vocabulary clips:  !VOCAB_COUNT! / 67
echo  Sentence clips:    !SENT_COUNT!
echo  Dictionary clips:  !DICT_COUNT!
echo.
echo  Next steps:
echo    1. Test audio:  python scripts\generate_audio_espeak.py test
echo    2. Speak text:  python scripts\generate_audio_espeak.py speak "apô"
echo    3. Build app:   scripts\build_and_run.bat
echo    4. Or debug:    flutter run
echo.
echo  To tune pronunciation:
echo    - Edit awing_to_phonemes^(^) in scripts\generate_audio_espeak.py
echo    - Regenerate: python scripts\generate_audio_espeak.py generate
echo.
echo =====================================================
exit /b 0
