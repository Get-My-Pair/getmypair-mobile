/// Sent on API calls so rack, services, and payments follow the selected family profile.
class ActiveProfileHeader {
  static const name = 'X-Active-Profile-Id';

  static String? currentId;

  static void applyTo(Map<String, String> headers) {
    final id = currentId?.trim();
    if (id == null || id.isEmpty) return;
    headers[name] = id;
  }
}
