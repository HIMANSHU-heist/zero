# BehaveGuard-UPI -- Complete Contributor Roadmap

> **For anyone who just found this repo.**
> Follow this guide top-to-bottom and you will go from zero to running the app on a real Android device, no prior setup needed.

---

## Table of Contents

1. [Prerequisites](#-1-prerequisites)
2. [Clone the Repo](#-2-clone-the-repo)
   - [Option A: VS Code](#option-a--vs-code)
   - [Option B: Antigravity IDE](#option-b--antigravity-ide)
   - [Option C: Terminal / Git CLI](#option-c--terminal--git-cli)
3. [Run the Setup Script](#-3-run-the-setup-script)
   - [Windows](#windows)
   - [macOS / Linux](#macos--linux)
4. [Verify the Environment](#-4-verify-the-environment)
5. [Understand the Project Structure](#-5-understand-the-project-structure)
6. [Edit the Code](#-6-edit-the-code)
7. [Build the APK](#-7-build-the-apk)
8. [Test on a Real Android Device via USB](#-8-test-on-a-real-android-device-via-usb)
9. [Test on an Android Emulator](#-9-test-on-an-android-emulator)
10. [Common Errors and Fixes](#-10-common-errors-and-fixes)
11. [GitHub Codespaces](#-11-github-codespaces-browser-no-install)

---

## 1. Prerequisites

You only need **two things** installed before you start:

| Tool | Download |
|---|---|
| Git | https://git-scm.com/downloads |
| VS Code **or** Antigravity IDE | https://code.visualstudio.com |

> Everything else (Flutter, Java, Android SDK) is installed **automatically** by the setup script in step 3.

---

## 2. Clone the Repo

Choose **one** of the three methods below.

---

### Option A -- VS Code

1. Open VS Code
2. Press `Ctrl+Shift+P` (Windows/Linux) or `Cmd+Shift+P` (Mac) to open the Command Palette
3. Type: **Git: Clone** and press Enter
4. Paste the repo URL:
   ```
   https://github.com/HIMANSHU-heist/zero.git
   ```
5. Choose a folder on your computer (e.g. `C:\Projects` or `~/Projects`)
6. Click **Open** when VS Code asks to open the cloned repo

> VS Code may prompt you to install the **Flutter** and **Dart** extensions. Click Install.

---

### Option B -- Antigravity IDE

1. Open Antigravity IDE
2. Open the integrated terminal (`Ctrl+backtick`)
3. Run:
   ```bash
   git clone https://github.com/HIMANSHU-heist/zero.git
   ```
4. Then: **File > Open Folder** and select the `zero` folder that was created

---

### Option C -- Terminal / Git CLI

```bash
# Go to where you want to keep the project
cd C:\Projects          # Windows
# or
cd ~/Projects           # Mac or Linux

# Clone the repo
git clone https://github.com/HIMANSHU-heist/zero.git

# Enter the folder
cd zero
```

Then open the `zero` folder in VS Code or Antigravity.

---

## 3. Run the Setup Script

> Run this from the **`zero` folder (repo root)**, not from inside `behave_guard_flutter`.

---

### Windows

**Method 1 (easiest):**
1. Open File Explorer and navigate to the `zero` folder
2. Find `setup.bat`
3. Right-click it -> **Run as administrator**

**Method 2 (from terminal):**
Open PowerShell or CMD **as Administrator** and run:
```bat
cd C:\Projects\zero
setup.bat
```

What the script installs automatically:

| Step | What gets installed |
|---|---|
| 1 | Chocolatey (Windows package manager) |
| 2 | Git |
| 3 | Java 17 (Eclipse Temurin) |
| 4 | Flutter SDK |
| 5 | Android SDK Command-line Tools |
| 6 | Android SDK licenses accepted automatically |
| 7 | `flutter pub get` (fetches all Dart packages) |

Expected output:
```
[OK]    Chocolatey already installed.
[INFO]  Installing Java 17 (Temurin)...
[INFO]  Installing Flutter...
[INFO]  Installing Android SDK Command-line Tools...
[INFO]  Accepting Android SDK licenses (auto-yes)...
[INFO]  Running flutter doctor...
[INFO]  Getting Flutter pub dependencies...
[SUCCESS] Setup complete!
```

The script takes **5-15 minutes** on first run.

---

### macOS / Linux

Open a terminal and run:
```bash
cd ~/Projects/zero

# Give execute permission (one time only)
chmod +x setup.sh

# Run it
./setup.sh
```

What gets installed:
- **macOS**: Homebrew > Java 17 (Temurin) > Flutter > Android cmdline-tools
- **Linux**: apt dependencies > Java 17 > Flutter SDK > Android cmdline-tools

> After the script finishes, **restart your terminal** so Flutter and Android SDK are on your PATH.

---

## 4. Verify the Environment

Run this after setup:
```bash
flutter doctor
```

Expected output:
```
Doctor summary (to see all details, run flutter doctor -v):
[v] Flutter (Channel stable, 3.32.0)
[v] Android toolchain - develop for Android devices (Android SDK version 36.0.0)
[v] Android Studio (version 2024.x)
[v] VS Code (version 1.x)
[!] Connected device (no devices -- plug in your phone or start emulator)
```

> The `[!] Connected device` warning is expected if no phone is plugged in yet. Everything else should show `[v]`.

---

## 5. Understand the Project Structure

```
zero/                               <- repo root
|
+-- setup.bat                       <- Windows: run this first
+-- setup.sh                        <- macOS/Linux: run this first
+-- firestore.rules                 <- Firebase Firestore security rules
+-- .devcontainer/                  <- GitHub Codespaces auto-setup
|   +-- devcontainer.json
|   +-- setup.sh
|
+-- behave_guard_flutter/           <- THE FLUTTER APP (edit code here)
    |
    +-- pubspec.yaml                <- dependencies (like package.json)
    +-- pubspec.lock                <- locked versions
    |
    +-- assets/models/              <- ONNX AI fraud detection models
    |   +-- model_a.onnx
    |   +-- model_b.onnx
    |   +-- model_c.onnx
    |
    +-- android/                    <- Android build config (rarely edited)
    |   +-- app/
    |       +-- build.gradle.kts    <- Android SDK / version settings
    |       +-- google-services.json  <- Firebase config
    |
    +-- lib/                        <- ALL DART SOURCE CODE
        |
        +-- main.dart               <- App entry point
        |
        +-- config/
        |   +-- constants.dart      <- App-wide constants
        |
        +-- models/
        |   +-- app_state.dart      <- Global state
        |
        +-- screens/                <- Every screen of the app
        |   +-- splash_screen.dart
        |   +-- login_screen.dart
        |   +-- landing_screen.dart
        |   +-- dashboard_screen.dart
        |   +-- send_screen.dart
        |   +-- amount_screen.dart
        |   +-- confirm_recipient_screen.dart
        |   +-- processing_screen.dart
        |   +-- result_screens.dart
        |   +-- history_screen.dart
        |   +-- pin_lock_screen.dart
        |   +-- profile_screen.dart
        |   +-- myqr_screen.dart
        |   +-- geo_explainer_screen.dart
        |   +-- provisioning_screen.dart
        |   +-- debug_screen.dart
        |
        +-- services/               <- Business logic and backend calls
        |   +-- firestore_service.dart  <- Firebase database operations
        |   +-- fraud_service.dart      <- ONNX model inference
        |   +-- device_service.dart     <- Device fingerprinting
        |
        +-- widgets/                <- Reusable UI components
            +-- pin_modal.dart
            +-- risk_tag.dart
```

---

## 6. Edit the Code

### Get dependencies after pulling new changes

Any time you `git pull`, run this:
```bash
cd behave_guard_flutter
flutter pub get
```

### Adding a new package

Edit `pubspec.yaml`:
```yaml
dependencies:
  your_new_package: ^1.0.0
```
Then run `flutter pub get`.

### Hot reload while the app is running

Once `flutter run` is active, in the terminal:

| Key | Action |
|---|---|
| `r` | Hot Reload (instant, keeps app state) |
| `R` | Hot Restart (full restart, clears state) |
| `q` | Quit |
| `d` | Detach (leave app running, exit terminal) |

### Recommended VS Code extensions

| Extension ID | Purpose |
|---|---|
| `Dart-Code.flutter` | Flutter support |
| `Dart-Code.dart-code` | Dart language |
| `usernamehw.errorlens` | Inline error highlighting |
| `Dart-Code.flutter` | Widget inspector |

---

## 7. Build the APK

```bash
cd behave_guard_flutter

# Debug build (fast, for testing during development)
flutter build apk --debug

# Release build (optimised, for sharing)
flutter build apk --release
```

APK output locations:
```
behave_guard_flutter/build/app/outputs/flutter-apk/app-debug.apk
behave_guard_flutter/build/app/outputs/flutter-apk/app-release.apk
```

To install directly to a connected device:
```bash
flutter install
```

---

## 8. Test on a Real Android Device via USB

This is the **recommended** way to test.

### Step 1 -- Enable Developer Options on your phone

1. Open **Settings** on your Android phone
2. Go to **About Phone**
3. Tap **Build Number** exactly **7 times** in a row
4. You will see: *"You are now a developer!"*

### Step 2 -- Enable USB Debugging

1. Go back to **Settings > Developer Options** (now visible)
2. Toggle **USB Debugging** to ON
3. Also toggle **Install via USB** to ON (if available on your phone)

### Step 3 -- Connect and authorize

1. Plug your phone into your PC with a USB cable
2. A dialog appears on your phone: **"Allow USB debugging?"**
3. Tap **Allow** (optionally check "Always allow from this computer")

> If no dialog appears, try: Settings > Developer Options > Revoke USB debugging authorizations, then reconnect.

### Step 4 -- Verify Flutter can see your device

```bash
flutter devices
```

Expected output:
```
Pixel 7 (mobile) . R5CN707XXXX . android-arm64 . Android 14 (API 34)
```

If your device is NOT listed:
- Check USB is not charge-only (try a different cable)
- Run `adb devices` -- if it shows `unauthorized`, unplug and re-plug and tap Allow again

### Step 5 -- Run the app

```bash
cd behave_guard_flutter
flutter run
```

Flutter will compile, install, and launch the app on your phone automatically.
The first build takes 1-3 minutes. Subsequent hot reloads are instant.

### Step 6 -- Live edit with Hot Reload

1. Keep `flutter run` running in the terminal
2. Open any `.dart` file in `lib/` and make a change
3. Save (`Ctrl+S`)
4. Press **`r`** in the terminal
5. The change appears on your phone in under 1 second

---

## 9. Test on an Android Emulator

Use this if you do not have a physical Android device.

### Create a Virtual Device

1. Install [Android Studio](https://developer.android.com/studio) (free)
2. Open Android Studio > click **Device Manager** (right panel icon)
3. Click **Create Device**
4. Select a phone model (e.g. Pixel 7)
5. Select a system image (e.g. API 34, x86_64) -- download if prompted
6. Click **Finish**

### Launch the emulator and run

```bash
# List available emulators
flutter emulators

# Launch one
flutter emulators --launch Pixel_7_API_34

# Once the emulator is booted, run the app
cd behave_guard_flutter
flutter run
```

Or just press the Play button in Android Studio Device Manager.

---

## 10. Common Errors and Fixes

### Error: `flutter: command not found`
**Fix:** Close and reopen your terminal after running the setup script. The PATH changes need a fresh shell.

---

### Error: `Android SDK not found` or `ANDROID_HOME not set`

**Windows fix:**
```bat
setx ANDROID_HOME "%LOCALAPPDATA%\Android\Sdk"
```

**Mac/Linux fix:**
```bash
export ANDROID_HOME="$HOME/Android/Sdk"
echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >> ~/.bashrc
source ~/.bashrc
```

---

### Error: `License for package Android SDK Build-Tools not accepted`

```bash
flutter doctor --android-licenses
# Press y to accept each license
```

---

### Error: `Gradle build failed`

```bash
cd behave_guard_flutter
flutter clean
flutter pub get
flutter run
```

---

### Error: `google-services.json not found`

The Firebase config file is needed to build. It is NOT committed to the repo for security.
Contact the repo owner to get it, then place it at:
```
behave_guard_flutter/android/app/google-services.json
```

---

### Device not appearing in `flutter devices`

Checklist:
- [ ] USB cable supports data (not charge-only)
- [ ] USB Debugging is ON
- [ ] You tapped Allow on the authorization popup
- [ ] Try a different USB port
- [ ] Run `adb kill-server && adb start-server && adb devices`

---

## 11. GitHub Codespaces (browser, no install)

Use this to edit and build without installing anything on your machine.

### How to open

1. Go to the GitHub repo page
2. Click the green **Code** button
3. Click the **Codespaces** tab
4. Click **Create codespace on main**

Codespaces will automatically:
- Start a Linux container
- Run `.devcontainer/setup.sh` (installs Flutter + Android SDK)
- Run `flutter pub get`
- Open VS Code in your browser with Flutter/Dart extensions installed

This takes about 3-5 minutes the first time.

### What you can do in Codespaces

```bash
# Edit any .dart file, then build:
cd behave_guard_flutter
flutter build apk --debug

# Download the APK:
# Right-click app-debug.apk in the file explorer -> Download
# Then install it on your phone via USB or send it to yourself
```

### What Codespaces CANNOT do

- `flutter run` -- no USB port, no emulator display
- Live hot-reload on a device

---

## Questions or Issues?

Open a GitHub Issue with:
1. Your OS and version
2. Full output of `flutter doctor -v`
3. The exact error message
