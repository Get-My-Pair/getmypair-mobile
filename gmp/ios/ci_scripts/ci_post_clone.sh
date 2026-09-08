#!/bin/sh
set -ex

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

FLUTTER_ROOT="$HOME/flutter"
PROJECT_ROOT="$CI_PRIMARY_REPOSITORY_PATH/gmp"

if [ ! -d "$FLUTTER_ROOT" ]; then
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_ROOT"
fi

export PATH="$FLUTTER_ROOT/bin:$PATH"

cd "$PROJECT_ROOT"

flutter precache --ios

# Remove cached pods & locks
rm -rf ios/Pods ios/Podfile.lock .dart_tool

flutter pub get

# Generate plugin symlinks without full build
flutter build ios --config-only --no-codesign