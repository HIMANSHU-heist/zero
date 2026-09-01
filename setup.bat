@echo off
setlocal EnableDelayedExpansion

:: ============================================================
::  BehaveGuard-UPI  —  Windows Setup Script
::  Run this ONCE after cloning the repo.
::  Installs: Chocolatey, Git, Java 17, Flutter SDK, Android SDK
::  Then fetches Flutter dependencies and verifies the environment.
:: ============================================================

echo.
echo  =====================================================
echo   BehaveGuard-UPI  ^|  Windows Setup Script
echo  =====================================================
echo.

:: ── 0. Must run as Administrator ─────────────────────────────
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo [ERROR] Please right-click this file and "Run as Administrator".
    pause
    exit /b 1
)

:: ── 1. Install Chocolatey (Windows package manager) ──────────
where choco >nul 2>&1
if %errorlevel% NEQ 0 (
    echo [INFO] Installing Chocolatey...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    set "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
    call refreshenv >nul 2>&1
) else (
    echo [OK] Chocolatey already installed.
)

:: ── 2. Install Git ───────────────────────────────────────────
where git >nul 2>&1
if %errorlevel% NEQ 0 (
    echo [INFO] Installing Git...
    choco install git -y --no-progress
    call refreshenv >nul 2>&1
) else (
    echo [OK] Git already installed.
)

:: ── 3. Install Java 17 (Eclipse Temurin) ─────────────────────
java -version >nul 2>&1
if %errorlevel% NEQ 0 (
    echo [INFO] Installing Java 17 ^(Temurin^)...
    choco install temurin17 -y --no-progress
    call refreshenv >nul 2>&1
) else (
    echo [OK] Java already installed.
)

:: ── 4. Install Flutter SDK ───────────────────────────────────
where flutter >nul 2>&1
if %errorlevel% NEQ 0 (
    echo [INFO] Installing Flutter...
    choco install flutter -y --no-progress
    call refreshenv >nul 2>&1
    set "PATH=%PATH%;%LOCALAPPDATA%\flutter\bin"
) else (
    echo [OK] Flutter already installed.
)

:: ── 5. Install Android SDK Command-line Tools ────────────────
where sdkmanager >nul 2>&1
if %errorlevel% NEQ 0 (
    echo [INFO] Installing Android SDK Command-line Tools...
    choco install android-sdk -y --no-progress
    call refreshenv >nul 2>&1
    if not defined ANDROID_HOME (
        set "ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk"
        setx ANDROID_HOME "%LOCALAPPDATA%\Android\Sdk" /M >nul 2>&1
    )
    set "PATH=%PATH%;%ANDROID_HOME%\cmdline-tools\latest\bin;%ANDROID_HOME%\platform-tools"
    setx PATH "%PATH%" /M >nul 2>&1
) else (
    echo [OK] Android SDK already present.
)

:: Accept Android SDK licenses
echo [INFO] Accepting Android SDK licenses ^(auto-yes^)...
echo y | sdkmanager --licenses >nul 2>&1

:: Configure Flutter to use Android SDK
if defined ANDROID_HOME (
    flutter config --android-sdk "%ANDROID_HOME%" >nul 2>&1
)

:: ── 6. flutter doctor (shows what is still missing) ──────────
echo.
echo [INFO] Running flutter doctor...
echo.
flutter doctor
echo.

:: ── 7. Install Flutter pub dependencies ──────────────────────
echo [INFO] Getting Flutter pub dependencies...
cd /d "%~dp0behave_guard_flutter"
flutter pub get
if %errorlevel% NEQ 0 (
    echo.
    echo [ERROR] flutter pub get failed. Check errors above.
    pause
    exit /b 1
)

:: ── 8. Done ──────────────────────────────────────────────────
echo.
echo  =====================================================
echo   [SUCCESS] Setup complete!
echo.
echo   NEXT STEPS:
echo   1. Connect an Android device with USB debugging ON
echo      OR launch an Android Emulator in Android Studio.
echo.
echo   2. Run the app:
echo        cd behave_guard_flutter
echo        flutter run
echo.
echo   3. Build a debug APK:
echo        flutter build apk --debug
echo.
echo   APK output:
echo        behave_guard_flutter\build\app\outputs\flutter-apk\app-debug.apk
echo  =====================================================
echo.
pause
