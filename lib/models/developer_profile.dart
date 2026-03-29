/// Credits / profile for the home screen developer section.
class DeveloperProfile {
  final String name;
  final String role;

  /// Longer text shown on the detail screen — edit per person.
  final String bio;

  /// Bundled asset path, e.g. `assets/developers/akash.png` (add file under assets/developers/).
  final String? photoAssetPath;

  /// Full HTTPS URLs (opened in browser / app).
  final String? githubUrl;
  final String? linkedinUrl;

  /// KIIT student roll number (display only).
  final String? kiitRollNo;

  const DeveloperProfile({
    required this.name,
    required this.role,
    this.bio = '',
    this.photoAssetPath,
    this.githubUrl,
    this.linkedinUrl,
    this.kiitRollNo,
  });

  bool get hasGithub =>
      githubUrl != null && githubUrl!.trim().isNotEmpty;

  bool get hasLinkedin =>
      linkedinUrl != null && linkedinUrl!.trim().isNotEmpty;

  bool get hasKiitRollNo =>
      kiitRollNo != null && kiitRollNo!.trim().isNotEmpty;

  /// Two-letter avatar fallback when no photo.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.single;
      return s.length >= 2 ? s.substring(0, 2).toUpperCase() : s.toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
