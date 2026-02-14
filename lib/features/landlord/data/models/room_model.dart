class Room {
  final String id;
  final String roomNumber;
  final String? spaceId;
  final DateTime? createdAt;
  final DateTime? deletedAt;
  
  // 🆕 NEW: Occupancy status
  final bool isOccupied;
  final String? occupiedBy;  // Tenant email

  Room({
    required this.id,
    required this.roomNumber,
    this.spaceId,
    this.createdAt,
    this.deletedAt,
    this.isOccupied = false,  // Default to available
    this.occupiedBy,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    // Handle roomNumber as both int and String
    final roomNumberRaw = json['roomNumber'];
    final roomNumber = roomNumberRaw?.toString() ?? '';
    
    // 🆕 NEW: Parse occupancy status
    final isOccupied = json['isOccupied'] as bool? ?? false;
    final occupiedBy = json['occupiedBy'] as String?;
    
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
      occupiedBy: occupiedBy,
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
      if (occupiedBy != null) 'occupiedBy': occupiedBy,
    };
  }

  Room copyWith({
    String? id,
    String? roomNumber,
    String? spaceId,
    DateTime? createdAt,
    DateTime? deletedAt,
    bool? isOccupied,
    String? occupiedBy,
  }) {
    return Room(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      spaceId: spaceId ?? this.spaceId,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isOccupied: isOccupied ?? this.isOccupied,
      occupiedBy: occupiedBy ?? this.occupiedBy,
    );
  }

  // 🆕 NEW: Helper getter
  bool get isAvailable => !isOccupied;

  @override
  String toString() => 'Room(id: $id, roomNumber: $roomNumber, isOccupied: $isOccupied, occupiedBy: ${occupiedBy ?? "none"})';
}