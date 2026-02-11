class Room {
  final String id;
  final String roomNumber;
  final String? spaceId;  // ✅ Optional (backend doesn't always return it)
  final DateTime? createdAt;
  final DateTime? deletedAt;

  Room({
    required this.id,
    required this.roomNumber,
    this.spaceId,
    this.createdAt,
    this.deletedAt,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    // ✅ Handle roomNumber as both int and String
    final roomNumberRaw = json['roomNumber'];
    final roomNumber = roomNumberRaw?.toString() ?? '';
    
    return Room(
      id: json['id'] as String,
      roomNumber: roomNumber,  // ✅ Converted to string
      spaceId: json['spaceId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomNumber': roomNumber,
      if (spaceId != null) 'spaceId': spaceId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
    };
  }

  Room copyWith({
    String? id,
    String? roomNumber,
    String? spaceId,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return Room(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      spaceId: spaceId ?? this.spaceId,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() => 'Room(id: $id, roomNumber: $roomNumber, spaceId: ${spaceId ?? "unknown"})';
}