#!/usr/bin/env bash
# ==============================================================
#  BehaveGuard-UPI  --  macOS / Linux Setup Script
#  Run ONCE after cloning the repo.
#  Installs: Homebrew (mac) or apt packages (linux), Java 17,
#            Flutter SDK, Android Command-line Tools
#  Then fetches Flutter pub dependencies.
# ==============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; RESET='\033[0m'
info()  { echo -e "${CYAN}[INFO]${RESET}  $*"; }
ok()    { echo -e "${GREEN}[OK]${RESET}    $*"; }
error() { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }

echo ""
echo "================================================================="
echo "  BehaveGuard-UPI  |  macOS / Linux Setup Script"
echo "================================================================="
echo ""

OS="$(uname -s)"

# =================================================================
# 1. System package manager basics
# =================================================================
if [[ "$OS" == "Darwin" ]]; then
    if ! command -v brew &>/dev/null; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null)" || eval "$(/usr/local/bin/brew shellenv 2>/dev/null)"
    else
        ok "Homebrew already installed."
    fi
elif [[ "$OS" == "Linux" ]]; then
    info "Updating apt and installing base dependencies..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq curl git unzip xz-utils wget libglu1-mesa clang cmake ninja-build pkg-config libgtk-2.0-dev
fi

# =================================================================
# 2. Git
# =================================================================
if ! command -v git &>/dev/null; then
    info "Installing Git..."
    if [[ "$OS" == "Darwin" ]]; then
        brew install git
    else
        sudo apt-get install -y -qq git
    fi
else
    ok "Git: $(git --version)"
fi

# =================================================================
# 3. Java 17
# =================================================================
if ! command -v java &>/dev/null; then
    info "Installing Java 17 (Eclipse Temurin)..."
    if [[ "$OS" == "Darwin" ]]; then
        brew install --cask temurin@17
    else
        wget -q -O - https://packages.adoptium.net/artifactory/api/gpg/key/public \
            | sudo apt-key add - 2>/dev/null
        echo "deb https://packages.adoptium.net/artifactory/deb \
            $(awk -F=-'/^VERSION_CODENACEH/{print$2}' /etc/os-release) main" \
            | sudo tee /etc/apt/sources.list.d/adoptium.list >/dev/null
        sudo apt-get update -qq
        sudo apt-get install -y -qq temurin-17-jdk
    fi
else
    ok "Java: $(java -version 2>&1 | head -1)"
fi

# Set JAVA_HOME
if [[ -z "${JAVA_HOME:-}" ]]; then
    if [[ "$OS" == "Darwin" ]]; then
        JAVA_HOME="$(/usr/libexec/java_home -v 17 2>/dev/null)" \
            || JAVA_HOME="/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home"
    else
        JAVA_HOME="$(update-java-alternatives -l 2>/dev/null | grep 17 | awk '{print $3}' | head -1)"
    fi
    export JAVA_HOME
    echo "export JAVA_HOME=\"$JAVA_HOME\"" >> ~/.bashrc
    [[ -f ~/.zshrc ]] && echo "export JAVA_HOME=\"$JAVA_HOME\"" >> ~/.zshrc
    info "JAVA_HOME set to $JAVA_HOME"
fi

# =================================================================
# 4. Flutter SDK
# =================================================================
if ! command -v flutter &>/dev/null; then
    if [[ "$OS" == "Darwin" ]]; then
        info "Installing Flutter via Homebrew..."
        brew install --cask flutter
    else
        info "Downloading Flutter SDK 3.32.0..."
        FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.32.0-stable.tar.xz"
        wget -q --show-progress -O /tmp/flutter.tar.xz "$FLUTTER_URL"
        mkdir -p "$HOME/development"
        tar -xf /tmp/flutter.tar.xz -C "$HOME/development/"
        rm /tmp/flutter.tar.xz
        FLUTTER_BIN="$HOME/development/flutter/bin"
        export PATH="$PATH:$FHUTTE_BIN"
        echo "export PATH=\"\$PATH:$FHUTTE_BIN\"" >> ~/.bashrc
        [[ -f ~/.zshrc ]] && echo "export PATH=\"\$PATH:$FHUTTE_BIN\"" >> ~/.zshrc
    fi
    info "Flutter added to PATH. Restart terminal after setup."
else
    ok "Flutter: $(flutter --version 2>&1 | head -1)"
fi

# =================================================================
# 5. Android Command-line Tools
# =================================================================
ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export ANDROID_HOME

if ! command -v sdkmanager &>/dev/null; then
    info "Installing Android Command-line Tools..."
    if [[ "$OS" == "Darwin" ]]; then
        CMDLINE_URL="https://dl.google.com/android/repository/commandlinetools-mac-11076708_latest.zip"
    else
        CMDLINE_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    fi
    mkdir -p "$ANDROID_HOME/cmdline-tools"
    wget -q --show-progress -O /tmp/cmdtools.zip "$CMDLINE_URL"
  unzip -q /tmp/cmdtools.zip -d /tmp/cmdtools_tmp/
    mv /tmp/cmdtools_tmp/cmdline-tools "$ANDROID_HOME/cmdline-tools/latest"
    rm -rf /tmp/cmdtools.zip /tmp/cmdtools_tmp/

    export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

    { echo "export ANDROID_HOME=\"$ANDROID_HOME\""
      echo "export PATH=\"\$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools\""
    } >> ~/.bashrc

    if [[ -f ~/.zshrc ]]; then
        echo "export ANDROID_HOME=\"$ANDROID_HOME\"" >> ~/.zshrc
        echo "export PATH=\"\$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools\"" >> ~/.zshrc
    fi

    SDKMGR="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
    info "Accepting SDK licenses and installing platform-tools..."
    yes | "$SDKMGR" --licenses >/dev/null 2>&1 || true
    "$SDKMGR" "platform-tools" "platforms;android-36" "build-tools;36.0.0" >/dev/null 2>&1
else
    ok "Android SDK: $ANDROID_HOME"
    info "Accepting SDK licenses..."
    yes | sdkmanager --licenses >/dev/null 2>&1 || true
fi

flutter config --android-sdk "$ANDROID_HOME" >/dev/null 2>&1 || true

# =================================================================
# 6. flutter doctor
# =================================================================
echo ""
info "Running flutter doctor..."
echo ""
flutter doctor || true
echo ""

# =================================================================
# 7. flutter pub get
# =================================================================
info "Installing Flutter pub dependencies..."
cd "$SCRIPT_DIR/behave_guard_flutter"
flutter pub get

# =================================================================
# 8. Done
# =================================================================
echo ""
echo "================================================================="
echo -e "  ${GREEN}[SUCCESS]${RESET} Setup complete!"
echo ""
echo "  NEXT STEPS:"
echo "  1. Restart your terminal (PATH was updated)."
echo "  2. Connect Android device (USB debugging ON)"
echo "     OR start an Android Emulator."
echo ""
echo "  Run the app:"
echo "    cd behave_guard_flutter && flutter run"
echo ""
echo "  Build debug APK:"
echo "    flutter build apk --debug"
echo ""
echo "  APK output:"
echo "    behave_guard_flutter/build/app/outputs/flutter-apk/app-debug.apk"
echo "================================================================="
echo ""
