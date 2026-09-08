#!/bin/sh
set -ex

FLUTTER_ROOT="$HOME/flutter"
PROJECT_ROOT="$CI_PRIMARY_REPOSITORY_PATH/gmp"

# Install Flutter
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_ROOT"
export PATH="$PATH:$FLUTTER_ROOT/bin"
flutter doctor

# --- Everything below explicitly cd's to PROJECT_ROOT first ---

cd "$PROJECT_ROOT"
flutter precache --ios
flutter pub get

# If your Podfile still needs `pod install`, uncomment these 3 lines —
# note it cd's back to PROJECT_ROOT afterward, which was likely the bug:
# cd "$PROJECT_ROOT/ios"
# pod install --repo-update
# cd "$PROJECT_ROOT"

cd "$PROJECT_ROOT"
flutter build ios --release --no-codesign