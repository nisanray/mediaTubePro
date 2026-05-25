String prettyFilename(String filename) {
  if (filename.trim().isEmpty) return filename;

  var base = filename;
  // Remove extension if present
  final dot = base.lastIndexOf('.');
  if (dot > 0) base = base.substring(0, dot);

  // Replace underscores with spaces for nicer display
  var cleaned = base.replaceAll('_', ' ').trim();

  // Our saved pattern is: DISPLAYNAME_QUALITY_MediaTube
  // Try to extract DISPLAYNAME from that pattern
  final m = RegExp(r'^(.*)\s+[^\s]+\s+MediaTube\s*$').firstMatch(cleaned);
  if (m != null) {
    return m.group(1)!.trim();
  }

  // Fallback: remove common appended tokens like "[MediaTube]" or "- MediaTube"
  cleaned = cleaned
      .replaceAll(RegExp(r"\[MediaTube\]", caseSensitive: false), '')
      .trim();
  cleaned = cleaned
      .replaceAll(RegExp(r"-\s*MediaTube\s*", caseSensitive: false), '')
      .trim();

  return cleaned;
}
