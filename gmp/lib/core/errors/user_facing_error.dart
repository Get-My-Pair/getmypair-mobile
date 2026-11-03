/// Maps raw exceptions / API strings into safe UI copy.
/// Never surfaces backend stack traces, status payloads, or technical details.
class UserFacingError {
  UserFacingError._();

  static const String networkTitle = 'Network error';
  static const String networkMessage =
      'Unable to connect. Please check your internet connection and try again.';

  static const String genericTitle = 'Something went wrong';
  static const String genericMessage =
      'We couldn\'t complete this request. Please try again.';

  static bool isNetwork(Object? error) {
    if (error == null) return false;
    final typeName = error.runtimeType.toString().toLowerCase();
    if (typeName.contains('networkfailure') ||
        typeName.contains('networkexception')) {
      return true;
    }
    final raw = _raw(error).toLowerCase();
    return raw.contains('socketexception') ||
        raw.contains('networkexception') ||
        raw.contains('networkfailure') ||
        raw.contains('network failure') ||
        raw.contains('network error') ||
        raw.contains('no internet') ||
        raw.contains('connection timeout') ||
        raw.contains('connection timed out') ||
        raw.contains('failed host lookup') ||
        raw.contains('network is unreachable') ||
        raw.contains('connection refused') ||
        raw.contains('connection reset') ||
        raw.contains('clientexception') ||
        raw.contains('xmlhttprequest') ||
        raw.contains('handshake exception') ||
        (raw.contains('timeout') && raw.contains('connection'));
  }

  static String titleFor(Object? error) =>
      isNetwork(error) ? networkTitle : genericTitle;

  static String messageFor(Object? error) =>
      isNetwork(error) ? networkMessage : genericMessage;

  /// Prefer this for dialogs / snackbars / inline banners.
  static String sanitize(Object? error) => messageFor(error);

  static String _raw(Object error) {
    if (error is String) return error;
    return error.toString();
  }
}
