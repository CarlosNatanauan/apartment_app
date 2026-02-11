class Space {
  final String id;
  final String name;
  final String joinCode;
  final String? ownerId;  // ✅ Optional
  final DateTime? createdAt;  // ✅ Also make this optional!
  final DateTime? deletedAt;

  Space({
    required this.id,
    required this.name,
    required this.joinCode,
    this.ownerId,  // ✅ Not required
    this.createdAt,  // ✅ Not required either!
    this.deletedAt,
  });

  factory Space.fromJson(Map<String, dynamic> json) {
    return Space(
      id: json['id'] as String,
      name: json['name'] as String,
      joinCode: json['joinCode'] as String,
      ownerId: json['ownerId'] as String?,  // ✅ Nullable
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,  // ✅ Handle missing createdAt
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'joinCode': joinCode,
      if (ownerId != null) 'ownerId': ownerId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
    };
  }

  Space copyWith({
    String? id,
    String? name,
    String? joinCode,
    String? ownerId,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return Space(
      id: id ?? this.id,
      name: name ?? this.name,
      joinCode: joinCode ?? this.joinCode,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() => 'Space(id: $id, name: $name, joinCode: $joinCode)';
}