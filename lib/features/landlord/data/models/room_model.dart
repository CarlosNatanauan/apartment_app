class Occupant {
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? email;

  const Occupant({
    this.firstName,
    this.lastName,
    this.fullName,
    this.email,
  });

  String get displayName {
    final fn = firstName?.trim();
    final ln = lastName?.trim();

    if ((fn ?? '').isNotEmpty && (ln ?? '').isNotEmpty) return '$fn $ln';
    if ((fullName ?? '').trim().isNotEmpty) return fullName!.trim();
    if ((email ?? '').trim().isNotEmpty) return email!.trim();
    return 'Unknown';
  }

  factory Occupant.fromJson(Map<String, dynamic> json) {
    return Occupant(
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      fullName: json['fullName'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (fullName != null) 'fullName': fullName,
      if (email != null) 'email': email,
    };
  }
}

class Room {
  final String id;
  final String roomNumber;
  final String? spaceId;
  final DateTime? createdAt;
  final DateTime? deletedAt;

  // ✅ Occupancy status
  final bool isOccupied;

  // ✅ NEW: occupant object from backend
  final Occupant? occupant;

  Room({
    required this.id,
    required this.roomNumber,
    this.spaceId,
    this.createdAt,
    this.deletedAt,
    this.isOccupied = false,
    this.occupant,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    final roomNumberRaw = json['roomNumber'];
    final roomNumber = roomNumberRaw?.toString() ?? '';

    final isOccupied = json['isOccupied'] as bool? ?? false;

    final occupantJson = json['occupant'];
    final occupant = occupantJson is Map<String, dynamic>
        ? Occupant.fromJson(occupantJson)
        : null;

    return Room(
      id: json['id'] as String,
      roomNumber: roomNumber,
      spaceId: json['spaceId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      isOccupied: isOccupied,
      occupant: occupant,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomNumber': roomNumber,
      if (spaceId != null) 'spaceId': spaceId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
      'isOccupied': isOccupied,
      if (occupant != null) 'occupant': occupant!.toJson(),
    };
  }

  Room copyWith({
    String? id,
    String? roomNumber,
    String? spaceId,
    DateTime? createdAt,
    DateTime? deletedAt,
    bool? isOccupied,
    Occupant? occupant,
  }) {
    return Room(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      spaceId: spaceId ?? this.spaceId,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isOccupied: isOccupied ?? this.isOccupied,
      occupant: occupant ?? this.occupant,
    );
  }

  // Helper getter
  bool get isAvailable => !isOccupied;

  // ✅ Backwards-compatible getter (so existing UI still works)
  String? get occupiedBy => occupant?.email;

  // ✅ Convenience: show name in UI
  String? get occupiedByName => occupant?.displayName;

  @override
  String toString() {
    return 'Room('
        'id: $id, '
        'roomNumber: $roomNumber, '
        'isOccupied: $isOccupied, '
        'occupant: ${occupant?.email ?? "none"}'
        ')';
  }
}
