/// Google Maps API key shared by Android/iOS/web setup.
///
/// Override at run time with:
/// `--dart-define=GOOGLE_MAPS_API_KEY=your_key`
/// Keep [web/index.html] in sync for the initial script tag.
class GoogleMapsConfig {
  static const String apiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyDea05I6AVaExAvm2uSyuSRGqX7hq9i5Tw',
  );
}
