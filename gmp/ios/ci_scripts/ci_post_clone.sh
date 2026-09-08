#!/bin/sh
set -e

# Install Flutter (adjust version/channel as needed)
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

flutter precache --ios
flutter pub get

# This regenerates ios/Flutter/ephemeral/, including
# FlutterGeneratedPluginSwiftPackage
cd "$CI_PRIMARY_REPOSITORY_PATH"
flutter build ios --release --no-codesign