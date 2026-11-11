/// Google Maps API key shared by Android/iOS/web setup.
///
/// Override at run time with:
/// `--dart-define=GOOGLE_MAPS_API_KEY=your_key`
/// Keep [web/index.html] / platform manifests in sync for native SDKs.
/// Restrict the key by bundle ID / package name and Maps APIs in Cloud Console.
class GoogleMapsConfig {
  static const String apiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );
}
