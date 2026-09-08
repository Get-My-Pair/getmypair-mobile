#!/bin/sh
set -ex

FLUTTER_ROOT="$HOME/flutter"
PROJECT_ROOT="$CI_PRIMARY_REPOSITORY_PATH/gmp"

# Install Flutter — pinned to match local version exactly
git clone https://github.com/flutter/flutter.git --depth 1 -b 3.44.9 "$FLUTTER_ROOT"
export PATH="$PATH:$FLUTTER_ROOT/bin"
flutter doctor

cd "$PROJECT_ROOT"
flutter precache --ios
flutter pub get

# Do NOT run pod install manually — flutter build handles CocoaPods internally,
# exactly like it does on a local machine.

flutter build ios --release --no-codesign