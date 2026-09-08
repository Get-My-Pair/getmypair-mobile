cd "$PROJECT_ROOT"

rm -rf ios/Pods ios/.symlinks ios/Podfile.lock .dart_tool build
flutter clean
flutter precache --ios
flutter pub get

# Workaround: pre-create the .symlinks path for google_mlkit_commons
# so Flutter's podhelper.rb can find apple_silicon_simulator.rb reliably
MLKIT_COMMONS_VERSION=$(grep -A2 "name: google_mlkit_commons" pubspec.lock | grep version | sed 's/.*"\(.*\)".*/\1/')
MLKIT_COMMONS_PATH="$HOME/.pub-cache/hosted/pub.dev/google_mlkit_commons-${MLKIT_COMMONS_VERSION}"

mkdir -p ios/.symlinks/plugins
if [ -d "$MLKIT_COMMONS_PATH" ]; then
  ln -sfn "$MLKIT_COMMONS_PATH" "ios/.symlinks/plugins/google_mlkit_commons"
fi

cd ios
pod install
cd "$PROJECT_ROOT"

flutter build ios --release --no-codesign