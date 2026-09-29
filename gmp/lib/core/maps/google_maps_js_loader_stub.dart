/// No-op on non-web platforms (native SDKs load Maps separately).
Future<void> ensureGoogleMapsJsLoaded({required String apiKey}) async {}
