@echo off
REM deploy_apps_script.bat v2.0.0
REM Automated deployment of Google Apps Script webhooks using clasp CLI.
REM
REM Prerequisites:
REM   - Node.js installed (winget install OpenJS.NodeJS.LTS)
REM   - npm install -g @google/clasp
REM   - clasp login (one-time Google auth)
REM   - Apps Script API enabled: https://script.google.com/home/usersettings
REM
REM What this does:
REM   1. Checks clasp is installed (installs if needed)
REM   2. Creates/updates Analytics web app
REM   3. Creates/updates Contributions web app
REM   4. Extracts DEPLOYMENT IDs (not script IDs) from clasp
REM   5. Writes webhook URLs to config/webhooks.json for the Flutter app
REM
REM v2.0.0 FIX: Previous version used script IDs instead of deployment IDs
REM   in the webhook URLs, causing 404 errors. Now correctly extracts
REM   deployment IDs from "clasp deploy" and "clasp deployments" output.

setlocal enabledelayedexpansion

echo =====================================================
echo  Awing AI Learning - Google Apps Script Deployer v2.0.0
echo =====================================================
echo.

REM ---- Step 0: Check Node.js ----
call :step_check_node
if !ERRORLEVEL! neq 0 exit /b 1

REM ---- Step 1: Check clasp ----
call :step_check_clasp
if !ERRORLEVEL! neq 0 exit /b 1

REM ---- Step 2: Check login ----
call :step_check_login
if !ERRORLEVEL! neq 0 exit /b 1

REM Initialize URL variables
set "ANALYTICS_URL="
set "CONTRIBUTIONS_URL="

REM ---- Step 3: Deploy Analytics ----
call :step_deploy_analytics
set ANALYTICS_RESULT=!ERRORLEVEL!

REM ---- Step 4: Deploy Contributions ----
call :step_deploy_contributions
set CONTRIBUTIONS_RESULT=!ERRORLEVEL!

REM ---- Step 5: Write config ----
call :step_write_config

echo.
echo =====================================================
echo  Deployment Complete!
echo =====================================================
if defined ANALYTICS_URL (
    echo  [OK] Analytics:     !ANALYTICS_URL!
) else (
    echo  [!!] Analytics web app had errors - URL not captured
)
if defined CONTRIBUTIONS_URL (
    echo  [OK] Contributions: !CONTRIBUTIONS_URL!
) else (
    echo  [!!] Contributions web app had errors - URL not captured
)
echo.
echo  Webhook URLs saved to: config\webhooks.json
echo  The Flutter app reads these URLs automatically.
echo.
echo  IMPORTANT: If URLs show as empty, run these commands manually:
echo    cd scripts\clasp_analytics
echo    clasp deployments
echo    cd ..\clasp_contributions
echo    clasp deployments
echo  Then copy the deployment IDs (AKfycb...) into config\webhooks.json
echo =====================================================

exit /b 0

REM ============================================================
REM  SUBROUTINES
REM ============================================================

:step_check_node
echo [1/5] Checking Node.js...
where node >nul 2>&1
if !ERRORLEVEL! neq 0 (
    echo   Node.js not found. Installing via winget...
    winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
    if !ERRORLEVEL! neq 0 (
        echo   ERROR: Could not install Node.js. Please install manually.
        exit /b 1
    )
    echo   Node.js installed. You may need to restart your terminal.
)
echo   Node.js: OK
exit /b 0

:step_check_clasp
echo [2/5] Checking Google clasp CLI...
where clasp >nul 2>&1
if !ERRORLEVEL! neq 0 (
    call npm list -g @google/clasp >nul 2>&1
    if !ERRORLEVEL! neq 0 (
        echo   Installing clasp...
        call npm install -g @google/clasp
        if !ERRORLEVEL! neq 0 (
            echo   ERROR: Could not install clasp. Try: npm install -g @google/clasp
            exit /b 1
        )
    )
)
echo   clasp: OK
exit /b 0

:step_check_login
echo [3/5] Checking clasp login...
if exist "%USERPROFILE%\.clasprc.json" (
    echo   Already logged in.
) else (
    echo   Not logged in. Opening browser for Google authentication...
    echo   Please authorize clasp to manage your Apps Script projects.
    call clasp login
    if !ERRORLEVEL! neq 0 (
        echo   ERROR: Login failed. Try: clasp login
        exit /b 1
    )
)
exit /b 0

:step_deploy_analytics
echo [4/5] Deploying Analytics web app...

set "ANALYTICS_DIR=scripts\clasp_analytics"

if not exist "%ANALYTICS_DIR%" mkdir "%ANALYTICS_DIR%"

if exist "%ANALYTICS_DIR%\.clasp.json" (
    echo   Project exists, pushing updates...
) else (
    echo   Creating new Apps Script project: Awing Analytics...
    pushd "%ANALYTICS_DIR%"
    call clasp create --title "Awing Analytics" --type standalone
    popd
    if !ERRORLEVEL! neq 0 (
        echo   ERROR: Could not create project. Check clasp login.
        exit /b 1
    )
)

REM Copy the .gs file as Code.js
copy /Y "scripts\analytics_webapp.gs" "%ANALYTICS_DIR%\Code.js" >nul

REM Create appsscript.json manifest if it doesn't exist
if not exist "%ANALYTICS_DIR%\appsscript.json" (
    (
        echo {
        echo   "timeZone": "Africa/Douala",
        echo   "dependencies": {},
        echo   "webapp": {
        echo     "executeAs": "USER_DEPLOYING",
        echo     "access": "ANYONE_ANONYMOUS"
        echo   },
        echo   "exceptionLogging": "STACKDRIVER",
        echo   "runtimeVersion": "V8"
        echo }
    ) > "%ANALYTICS_DIR%\appsscript.json"
)

REM Push code to Apps Script
pushd "%ANALYTICS_DIR%"
call clasp push --force
if !ERRORLEVEL! neq 0 (
    echo   ERROR: Push failed.
    popd
    exit /b 1
)

REM Deploy and capture the DEPLOYMENT ID from output
REM clasp deploy output format: "Created version N."  then "- DEPLOYMENT_ID @N."
echo   Creating new deployment...
call clasp deploy --description "Awing Analytics v2" > "%TEMP%\clasp_analytics_deploy.txt" 2>&1
type "%TEMP%\clasp_analytics_deploy.txt"

REM Extract deployment ID: find the line with "- " and get the ID
for /f "tokens=2 delims=- " %%A in ('type "%TEMP%\clasp_analytics_deploy.txt" ^| findstr /C:"- "') do (
    set "ANALYTICS_DEPLOY_ID=%%A"
)

REM If we got a deploy ID, great. Otherwise fall back to clasp deployments.
if not defined ANALYTICS_DEPLOY_ID (
    echo   Extracting deployment ID from clasp deployments...
    call clasp deployments > "%TEMP%\clasp_analytics_deployments.txt" 2>&1
    type "%TEMP%\clasp_analytics_deployments.txt"
    REM Get the LAST deployment line (most recent, skip @HEAD)
    for /f "tokens=2 delims=- " %%A in ('type "%TEMP%\clasp_analytics_deployments.txt" ^| findstr /C:"@" ^| findstr /V /C:"@HEAD"') do (
        set "ANALYTICS_DEPLOY_ID=%%A"
    )
)

popd

if defined ANALYTICS_DEPLOY_ID (
    set "ANALYTICS_URL=https://script.google.com/macros/s/!ANALYTICS_DEPLOY_ID!/exec"
    echo   SUCCESS: Deployment ID = !ANALYTICS_DEPLOY_ID!
    echo   URL: !ANALYTICS_URL!
) else (
    echo   WARNING: Could not extract deployment ID.
    echo   Run this manually to get the ID:
    echo     cd scripts\clasp_analytics
    echo     clasp deployments
    echo   Then look for the line with @1 or @2 etc. and copy the ID.
)

exit /b 0

:step_deploy_contributions
echo [5/5] Deploying Contributions web app...

set "CONTRIBUTIONS_DIR=scripts\clasp_contributions"

if not exist "%CONTRIBUTIONS_DIR%" mkdir "%CONTRIBUTIONS_DIR%"

if exist "%CONTRIBUTIONS_DIR%\.clasp.json" (
    echo   Project exists, pushing updates...
) else (
    echo   Creating new Apps Script project: Awing Contributions...
    pushd "%CONTRIBUTIONS_DIR%"
    call clasp create --title "Awing Contributions" --type standalone
    popd
    if !ERRORLEVEL! neq 0 (
        echo   ERROR: Could not create project. Check clasp login.
        exit /b 1
    )
)

copy /Y "scripts\contributions_webapp.gs" "%CONTRIBUTIONS_DIR%\Code.js" >nul

if not exist "%CONTRIBUTIONS_DIR%\appsscript.json" (
    (
        echo {
        echo   "timeZone": "Africa/Douala",
        echo   "dependencies": {},
        echo   "webapp": {
        echo     "executeAs": "USER_DEPLOYING",
        echo     "access": "ANYONE_ANONYMOUS"
        echo   },
        echo   "oauthScopes": [
        echo     "https://www.googleapis.com/auth/spreadsheets",
        echo     "https://www.googleapis.com/auth/drive",
        echo     "https://www.googleapis.com/auth/script.send_mail"
        echo   ],
        echo   "exceptionLogging": "STACKDRIVER",
        echo   "runtimeVersion": "V8"
        echo }
    ) > "%CONTRIBUTIONS_DIR%\appsscript.json"
)

pushd "%CONTRIBUTIONS_DIR%"
call clasp push --force
if !ERRORLEVEL! neq 0 (
    echo   ERROR: Push failed.
    popd
    exit /b 1
)

echo   Creating new deployment...
call clasp deploy --description "Awing Contributions v2" > "%TEMP%\clasp_contributions_deploy.txt" 2>&1
type "%TEMP%\clasp_contributions_deploy.txt"

REM Extract deployment ID
for /f "tokens=2 delims=- " %%A in ('type "%TEMP%\clasp_contributions_deploy.txt" ^| findstr /C:"- "') do (
    set "CONTRIBUTIONS_DEPLOY_ID=%%A"
)

if not defined CONTRIBUTIONS_DEPLOY_ID (
    echo   Extracting deployment ID from clasp deployments...
    call clasp deployments > "%TEMP%\clasp_contributions_deployments.txt" 2>&1
    type "%TEMP%\clasp_contributions_deployments.txt"
    for /f "tokens=2 delims=- " %%A in ('type "%TEMP%\clasp_contributions_deployments.txt" ^| findstr /C:"@" ^| findstr /V /C:"@HEAD"') do (
        set "CONTRIBUTIONS_DEPLOY_ID=%%A"
    )
)

popd

if defined CONTRIBUTIONS_DEPLOY_ID (
    set "CONTRIBUTIONS_URL=https://script.google.com/macros/s/!CONTRIBUTIONS_DEPLOY_ID!/exec"
    echo   SUCCESS: Deployment ID = !CONTRIBUTIONS_DEPLOY_ID!
    echo   URL: !CONTRIBUTIONS_URL!
) else (
    echo   WARNING: Could not extract deployment ID.
    echo   Run this manually to get the ID:
    echo     cd scripts\clasp_contributions
    echo     clasp deployments
    echo   Then look for the line with @1 or @2 etc. and copy the ID.
)

exit /b 0

:step_write_config
echo.
echo Writing webhook URLs to config\webhooks.json...

if not exist "config" mkdir "config"

REM Use Python to write the JSON file to avoid batch echo truncation issues
python -c "import json; json.dump({'analytics_url': r'!ANALYTICS_URL!', 'contributions_url': r'!CONTRIBUTIONS_URL!', 'deployed_at': '!DATE! !TIME!'}, open('config/webhooks.json', 'w'), indent=2)" 2>nul

if !ERRORLEVEL! neq 0 (
    REM Fallback: write manually if Python isn't available
    (
        echo {
        echo   "analytics_url": "!ANALYTICS_URL!",
        echo   "contributions_url": "!CONTRIBUTIONS_URL!",
        echo   "deployed_at": "!DATE! !TIME!"
        echo }
    ) > "config\webhooks.json"
)

echo   Saved to config\webhooks.json
type "config\webhooks.json"
exit /b 0
