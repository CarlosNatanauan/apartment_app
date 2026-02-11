class Membership {
  final String id;
  final String userId;
  final String? spaceId;
  final String? roomId;
  final String status;
  final DateTime? createdAt;
  final String? userEmail;
  final String? roomNumber;

  Membership({
    required this.id,
    required this.userId,
    this.spaceId,
    this.roomId,
    required this.status,
    this.createdAt,
    this.userEmail,
    this.roomNumber,
  });

  factory Membership.fromJson(Map<String, dynamic> json) {
    // Extract membership ID
    final membershipId = json['membershipId'] as String? ?? json['id'] as String;
    
    // Extract user info (nested in tenant object)
    final tenant = json['tenant'] as Map<String, dynamic>?;
    final userId = tenant?['userId'] as String? ?? json['userId'] as String? ?? '';
    final userEmail = tenant?['email'] as String? ?? json['userEmail'] as String?;
    
    // Extract space info (pending only)
    final space = json['space'] as Map<String, dynamic>?;
    final spaceId = space?['spaceId'] as String? ?? json['spaceId'] as String?;
    
    // Extract room info (active members)
    final room = json['room'] as Map<String, dynamic>?;
    final roomId = room?['roomId'] as String? ?? json['roomId'] as String?;
    
    // ✅ FIX 1: Handle roomNumber as both int and String!
    final roomNumberRaw = room?['roomNumber'] ?? json['roomNumber'];
    final roomNumber = roomNumberRaw?.toString();
    
    // ✅ FIX 2: Handle missing status field (default to ACTIVE if not present)
    final status = json['status'] as String? ?? 'ACTIVE';
    
    // Extract timestamp
    DateTime? timestamp;
    if (json['requestedAt'] != null) {
      timestamp = DateTime.parse(json['requestedAt'] as String);
    } else if (json['approvedAt'] != null) {
      timestamp = DateTime.parse(json['approvedAt'] as String);
    } else if (json['createdAt'] != null) {
      timestamp = DateTime.parse(json['createdAt'] as String);
    }
    
    return Membership(
      id: membershipId,
      userId: userId,
      spaceId: spaceId,
      roomId: roomId,
      status: status,  // ✅ Now safe
      createdAt: timestamp,
      userEmail: userEmail,
      roomNumber: roomNumber,  // ✅ Now safe
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'membershipId': id,
      'userId': userId,
      if (spaceId != null) 'spaceId': spaceId,
      if (roomId != null) 'roomId': roomId,
      'status': status,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (userEmail != null) 'userEmail': userEmail,
      if (roomNumber != null) 'roomNumber': roomNumber,
    };
  }

  Membership copyWith({
    String? id,
    String? userId,
    String? spaceId,
    String? roomId,
    String? status,
    DateTime? createdAt,
    String? userEmail,
    String? roomNumber,
  }) {
    return Membership(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      spaceId: spaceId ?? this.spaceId,
      roomId: roomId ?? this.roomId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      userEmail: userEmail ?? this.userEmail,
      roomNumber: roomNumber ?? this.roomNumber,
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isActive => status == 'ACTIVE';
  bool get isRejected => status == 'REJECTED';

  @override
  String toString() => 'Membership(id: $id, user: $userEmail, status: $status, room: $roomNumber)';
}