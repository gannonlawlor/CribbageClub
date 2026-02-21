/// Returns the initials (up to 2 characters) from a display name.
/// e.g. "John Smith" -> "JS", "alice" -> "A", "" -> "?"
String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
