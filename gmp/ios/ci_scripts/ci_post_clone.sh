#!/bin/sh
set -ex

# Ensure Homebrew and CocoaPods binaries are in PATH
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

FLUTTER_ROOT="$HOME/flutter"
PROJECT_ROOT="$CI_PRIMARY_REPOSITORY_PATH/gmp"

# Install Flutter if not already present
if [ ! -d "$FLUTTER_ROOT" ]; then
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_ROOT"
fi

export PATH="$FLUTTER_ROOT/bin:$PATH"

cd "$PROJECT_ROOT"

# Precache iOS dependencies
flutter precache --ios

# Clean stale caches
rm -rf ios/Pods
rm -rf ios/.symlinks
rm -rf ios/Podfile.lock
rm -rf .dart_tool

# Get Flutter packages
flutter pub get

# Generate native iOS project files & plugin symlinks without a full build
flutter build ios --config-only --no-codesign

# Run pod install
cd ios
pod install