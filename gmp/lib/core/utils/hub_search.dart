/// Hub-scoped search matching for Care / Rehome / Save pages.
bool hubSearchMatches(
  String query, {
  required String label,
  List<String> keywords = const [],
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;

  final labelLower = label.toLowerCase().replaceAll('\n', ' ');
  final compactLabel = labelLower.replaceAll(RegExp(r'[\s_]'), '');
  final compactQuery = q.replaceAll(RegExp(r'[\s_]'), '');

  if (labelLower.contains(q) || compactLabel.contains(compactQuery)) {
    return true;
  }

  for (final raw in keywords) {
    final key = raw.toLowerCase().trim();
    if (key.isEmpty) continue;
    if (key == q || key.startsWith(q) || q.startsWith(key)) return true;
    if (q.length >= 3 && key.contains(q)) return true;
  }
  return false;
}
