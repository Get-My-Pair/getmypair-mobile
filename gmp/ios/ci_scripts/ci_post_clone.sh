#!/bin/sh
set -ex

FLUTTER_ROOT="$HOME/flutter"
PROJECT_ROOT="$CI_PRIMARY_REPOSITORY_PATH/gmp"

# Install Flutter — pinned to match local version exactly
git clone https://github.com/flutter/flutter.git --depth 1 -b 3.44.9 "$FLUTTER_ROOT"
export PATH="$PATH:$FLUTTER_ROOT/bin"
flutter doctor

cd "$PROJECT_ROOT"

# Force a fully clean state — remove anything that could be stale
# from a previous Xcode Cloud build cache
rm -rf ios/Pods
rm -rf ios/.symlinks
rm -rf ios/Podfile.lock
rm -rf .dart_tool
rm -rf build

flutter clean
flutter precache --ios
flutter pub get

flutter build ios --release --no-codesign