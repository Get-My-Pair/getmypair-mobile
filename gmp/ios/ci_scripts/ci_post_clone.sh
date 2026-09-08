#!/bin/sh
set -ex

# Ensure Homebrew and CocoaPods binaries are available in PATH
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

FLUTTER_ROOT="$HOME/flutter"
PROJECT_ROOT="$CI_PRIMARY_REPOSITORY_PATH/gmp"

# Install Flutter - cloned from the stable branch
if [ ! -d "$FLUTTER_ROOT" ]; then
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_ROOT"
fi

export PATH="$FLUTTER_ROOT/bin:$PATH"

# Pre-download iOS artifacts and set up dependencies
flutter precache --ios

cd "$PROJECT_ROOT"

# Clean stale caches
rm -rf ios/Pods
rm -rf ios/.symlinks
rm -rf ios/Podfile.lock
rm -rf .dart_tool

# Get packages and rebuild plugin symlinks (.symlinks directory)
flutter pub get

# Explicitly run pod install inside the ios directory to verify CocoaPods setup
cd ios
pod install