#!/bin/bash
set -e

echo "==> Setting up Flutter development environment..."

# 1. Install dependencies
sudo apt-get update -qq
sudo apt-get install -y -qq \
    curl git unzip xz-utils zip libglu1-mesa \
    openjdk-17-jdk wget libgtk-3-dev clang cmake ninja-build pkg-config

# 2. Install Flutter SDK (stable channel)
FLUTTER_VERSION="3.32.0"
if [ ! -d "$HOME/flutter" ]; then
    echo "==> Downloading Flutter $FLUTTER_VERSION..."
    cd $HOME
    wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
    tar xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
    rm flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
    echo "==> Flutter downloaded!"
fi

# 3. Add Flutter to PATH permanently
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
export PATH="$HOME/flutter/bin:$PATH"

# 4. Install Android SDK (command-line tools)
ANDROID_SDK="$HOME/android-sdk"
if [ ! -d "$ANDROID_SDK" ]; then
    echo "==> Installing Android SDK..."
    mkdir -p "$ANDROID_SDK/cmdline-tools"
    cd /tmp
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
    unzip -q commandlinetools-linux-11076708_latest.zip
    mv cmdline-tools "$ANDROID_SDK/cmdline-tools/latest"
    rm commandlinetools-linux-11076708_latest.zip
fi

# 5. Set Android env vars
export ANDROID_HOME="$ANDROID_SDK"
export ANDROID_SDK_ROOT="$ANDROID_SDK"
export PATH="$ANDROID_SDK/cmdline-tools/latest/bin:$ANDROID_SDK/platform-tools:$PATH"

echo 'export ANDROID_HOME="$HOME/android-sdk"' >> ~/.bashrc
echo 'export ANDROID_SDK_ROOT="$HOME/android-sdk"' >> ~/.bashrc
echo 'export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"' >> ~/.bashrc

# 6. Accept SDK licenses & install required packages
yes | sdkmanager --licenses > /dev/null 2>&1 || true
sdkmanager --install \
    "platform-tools" \
    "platforms;android-35" \
    "build-tools;35.0.0" \
    "ndk;27.0.12077973" 2>&1 | tail -5

# 7. Configure Flutter
flutter config --android-sdk "$ANDROID_SDK" --no-analytics
flutter doctor --android-licenses < /dev/null || true

echo ""
echo "================================================"
echo "  Flutter environment ready!"
echo "  Run: flutter pub get && flutter build apk"
echo "================================================"
