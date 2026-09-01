# BehaveGuard-UPI

**Mock UPI payment simulator with real-time AI-powered fraud detection.**

Built with Flutter · Firebase · ONNX Runtime · Android

---

## ⚡ Quick Setup (clone → run in one step)

Just clone the repo and run **one script** — it installs everything automatically.

### Windows

> **Right-click** `setup.bat` (in the repo root) → **"Run as Administrator"**

```bat
# Or from an elevated Command Prompt / PowerShell:
setup.bat
```

What it installs automatically:
- Chocolatey (Windows package manager)
- Git
- Java 17 (Eclipse Temurin)
- Flutter SDK
- Android SDK Command-line Tools
- Accepts SDK licenses
- Runs `flutter pub get`

---

### macOS / Linux

```bash
chmod +x setup.sh
./setup.sh
```

What it installs automatically:
- **macOS**: Homebrew, Java 17 (Temurin cask), Flutter (cask), Android cmdline-tools
- **Linux**: apt dependencies, Java 17 (Temurin), Flutter SDK, Android cmdline-tools
- Accepts SDK licenses
- Runs `flutter pub get`

---

## 🚀 Run the App

After setup completes, connect an Android device (**USB debugging ON**) or start an emulator, then:

```bash
cd behave_guard_flutter
flutter run
```

## 📦 Build Debug APK

```bash
cd behave_guard_flutter
flutter build apk --debug
```

Output: `behave_guard_flutter/build/app/outputs/flutter-apk/app-debug.apk`

---

## 🔍 Check Your Environment

```bash
flutter doctor
```

All items under **Flutter**, **Android toolchain**, and **Android Studio / Connected device** should show ✓.

---

## 📁 Project Structure

```
zero/
├── setup.bat                      ← Windows setup script
├── setup.sh                       ← macOS/Linux setup script
├── firestore.rules                ← Firestore security rules
└── behave_guard_flutter/
    ├── pubspec.yaml               ← Flutter dependencies
    ├── assets/models/             ← ONNX fraud detection models
    ├── android/                   ← Android-specific config
    └── lib/
        ├── main.dart
        ├── screens/               ← All UI screens
        ├── services/              ← Firebase, fraud, device services
        ├── models/                ← App state
        ├── widgets/               ← Reusable widgets
        └── config/constants.dart  ← App-wide constants
```

---

## 🛠️ Manual Setup (if scripts fail)

1. Install [Flutter](https://docs.flutter.dev/get-started/install) (v3.32.0+)
2. Install [Java 17](https://adoptium.net/)
3. Install [Android SDK](https://developer.android.com/studio) (or cmdline-tools)
4. Run `flutter doctor` and fix any issues
5. Run `cd behave_guard_flutter && flutter pub get`

---

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [ONNX Runtime](https://onnxruntime.ai/)
