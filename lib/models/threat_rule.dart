/// ThreatRule data model — mirrors the backend ThreatRule DB model.
class ThreatRule {
  final int id;
  final int? userId;
  final String name;
  final List<String> permissions;
  final String threat;
  final String description;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  const ThreatRule({
    required this.id,
    this.userId,
    required this.name,
    required this.permissions,
    required this.threat,
    required this.description,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory ThreatRule.fromJson(Map<String, dynamic> json) {
    return ThreatRule(
      id: json['id'] as int,
      userId: json['user_id'] as int?,
      name: json['name'] as String? ?? '',
      permissions: List<String>.from(json['permissions'] ?? []),
      threat: json['threat'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  ThreatRule copyWith({
    String? name,
    List<String>? permissions,
    String? threat,
    String? description,
    bool? isActive,
  }) {
    return ThreatRule(
      id: id,
      userId: userId,
      name: name ?? this.name,
      permissions: permissions ?? this.permissions,
      threat: threat ?? this.threat,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
