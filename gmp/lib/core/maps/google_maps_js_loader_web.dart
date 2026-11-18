import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// True when `window.google.maps` is available.
bool get isGoogleMapsJsLoaded {
  final google = web.window.getProperty('google'.toJS);
  if (google == null || google.isUndefinedOrNull) return false;
  final maps = (google as JSObject).getProperty('maps'.toJS);
  return maps != null && !maps.isUndefinedOrNull;
}

/// Ensures the Maps JavaScript API is on the page (needed after hot restart,
/// which does not reload `web/index.html`).
Future<void> ensureGoogleMapsJsLoaded({required String apiKey}) async {
  if (apiKey.isEmpty || apiKey == 'YOUR_GOOGLE_MAPS_API_KEY') {
    throw StateError(
      'GOOGLE_MAPS_API_KEY is not set. Add it to web/index.html and '
      '--dart-define=GOOGLE_MAPS_API_KEY=...',
    );
  }

  if (isGoogleMapsJsLoaded) return;

  // Another call may already be injecting the script.
  final existing = web.document.querySelector(
    'script[data-gmp-maps-loader="true"]',
  );
  if (existing != null) {
    await _waitUntilLoaded();
    return;
  }

  final completer = Completer<void>();

  void completeOk() {
    if (!completer.isCompleted) completer.complete();
  }

  void completeErr(Object error) {
    if (!completer.isCompleted) completer.completeError(error);
  }

  // Google invokes this when the JS API is ready.
  web.window.setProperty(
    '_gmpMapsReady'.toJS,
    completeOk.toJS,
  );

  final script = web.HTMLScriptElement()
    ..async = true
    ..dataset['gmpMapsLoader'] = 'true'
    ..src =
        'https://maps.googleapis.com/maps/api/js'
        '?key=$apiKey'
        '&libraries=marker,geometry'
        '&callback=_gmpMapsReady';

  script.onerror = (web.Event event) {
    completeErr(
      StateError(
        'Failed to load Google Maps JavaScript API. '
        'Enable Maps JavaScript API for this key in Google Cloud Console.',
      ),
    );
  }.toJS;

  web.document.head?.append(script);

  await completer.future.timeout(
    const Duration(seconds: 25),
    onTimeout: () {
      throw TimeoutException('Timed out loading Google Maps JavaScript API');
    },
  );

  if (!isGoogleMapsJsLoaded) {
    throw StateError('Google Maps JS loaded but google.maps is still undefined');
  }
}

Future<void> _waitUntilLoaded() async {
  final sw = Stopwatch()..start();
  while (!isGoogleMapsJsLoaded) {
    if (sw.elapsed > const Duration(seconds: 25)) {
      throw TimeoutException('Timed out waiting for Google Maps JavaScript API');
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}
