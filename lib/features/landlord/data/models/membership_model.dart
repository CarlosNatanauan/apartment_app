// Room Lease Model (nested in Membership)
class RoomLease {
  final String leaseId;
  final String status;
  final String? roomId;
  final String? roomNumber;
  final int? monthlyRent;
  final DateTime? rentStartDate;
  final int? paymentDueDay;
  final DateTime? requestedAt;
  final DateTime? approvedAt;
  final DateTime? endedAt;

  RoomLease({
    required this.leaseId,
    required this.status,
    this.roomId,
    this.roomNumber,
    this.monthlyRent,
    this.rentStartDate,
    this.paymentDueDay,
    this.requestedAt,
    this.approvedAt,
    this.endedAt,
  });

  factory RoomLease.fromJson(Map<String, dynamic> json) {
    final room = json['room'] as Map<String, dynamic>?;
    
    return RoomLease(
      leaseId: json['leaseId'] as String? ?? json['id'] as String,
      status: json['status'] as String? ?? 'PENDING',
      roomId: room?['roomId'] as String? ?? room?['id'] as String?,
      roomNumber: room?['roomNumber']?.toString(),
      monthlyRent: json['monthlyRent'] as int?,
      rentStartDate: json['rentStartDate'] != null
          ? DateTime.parse(json['rentStartDate'] as String)
          : null,
      paymentDueDay: json['paymentDueDay'] as int?,
      requestedAt: json['requestedAt'] != null
          ? DateTime.parse(json['requestedAt'] as String)
          : null,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leaseId': leaseId,
      'status': status,
      if (roomId != null) 'roomId': roomId,
      if (roomNumber != null) 'roomNumber': roomNumber,
      if (monthlyRent != null) 'monthlyRent': monthlyRent,
      if (rentStartDate != null) 'rentStartDate': rentStartDate!.toIso8601String(),
      if (paymentDueDay != null) 'paymentDueDay': paymentDueDay,
      if (requestedAt != null) 'requestedAt': requestedAt!.toIso8601String(),
      if (approvedAt != null) 'approvedAt': approvedAt!.toIso8601String(),
      if (endedAt != null) 'endedAt': endedAt!.toIso8601String(),
    };
  }

  bool get isPending => status == 'PENDING';
  bool get isActive => status == 'ACTIVE';
  bool get isRejected => status == 'REJECTED';
  bool get isEnded => status == 'ENDED';

  bool get hasRentInfo =>
      monthlyRent != null && rentStartDate != null && paymentDueDay != null;
}

// Updated Membership Model with BACKWARD COMPATIBILITY
class Membership {
  final String id;
  final String userId;
  final String? spaceId;
  final String? spaceName;
  final String status;
  final DateTime? createdAt;
  final DateTime? approvedAt;
  final String? userEmail;
  final String? userFirstName;
  final String? userLastName;

  // Landlord info
  final String? landlordId;
  final String? landlordFirstName;
  final String? landlordLastName;
  final String? landlordEmail;

  // 🆕 NEW: Room Leases array
  final List<RoomLease> roomLeases;

  Membership({
    required this.id,
    required this.userId,
    this.spaceId,
    this.spaceName,
    required this.status,
    this.createdAt,
    this.approvedAt,
    this.userEmail,
    this.userFirstName,
    this.userLastName,
    this.landlordId,
    this.landlordFirstName,
    this.landlordLastName,
    this.landlordEmail,
    this.roomLeases = const [],
  });

  String? get tenantFullName {
    if (userFirstName != null && userLastName != null) {
      return '$userFirstName $userLastName';
    }
    return null;
  }

  String? get landlordFullName {
    if (landlordFirstName != null && landlordLastName != null) {
      return '$landlordFirstName $landlordLastName';
    }
    return null;
  }

  // 🆕 NEW: Computed properties for room leases
  List<RoomLease> get activeLeases =>
      roomLeases.where((l) => l.isActive).toList();
  
  List<RoomLease> get pendingLeases =>
      roomLeases.where((l) => l.isPending).toList();
  
  List<RoomLease> get rejectedLeases =>
      roomLeases.where((l) => l.isRejected).toList();
  
  List<RoomLease> get endedLeases =>
      roomLeases.where((l) => l.isEnded).toList();

  bool get hasActiveLeases => activeLeases.isNotEmpty;
  bool get hasPendingLeases => pendingLeases.isNotEmpty;
  
  int get activeRoomCount => activeLeases.length;
  int get pendingRoomCount => pendingLeases.length;

  // ✅ BACKWARD COMPATIBILITY: Return first active lease's fields
  // This allows old code to continue working without changes
  String? get roomId => activeLeases.isNotEmpty ? activeLeases.first.roomId : null;
  String? get roomNumber => activeLeases.isNotEmpty ? activeLeases.first.roomNumber : null;
  int? get monthlyRent => activeLeases.isNotEmpty ? activeLeases.first.monthlyRent : null;
  DateTime? get rentStartDate => activeLeases.isNotEmpty ? activeLeases.first.rentStartDate : null;
  int? get paymentDueDay => activeLeases.isNotEmpty ? activeLeases.first.paymentDueDay : null;
  
  // ✅ Helper: Check if membership has rent info (via first active lease)
  bool get hasRentInfo => activeLeases.isNotEmpty && activeLeases.first.hasRentInfo;

  factory Membership.fromJson(Map<String, dynamic> json) {
    final membershipId =
        json['membershipId'] as String? ?? json['id'] as String;

    final tenant = json['tenant'] as Map<String, dynamic>?;
    final userId =
        tenant?['userId'] as String? ?? json['userId'] as String? ?? '';
    final userEmail =
        tenant?['email'] as String? ?? json['userEmail'] as String?;
    final userFirstName = tenant?['firstName'] as String?;
    final userLastName = tenant?['lastName'] as String?;

    final space = json['space'] as Map<String, dynamic>?;
    final spaceId = space?['spaceId'] as String? ?? json['spaceId'] as String?;
    final spaceName = space?['name'] as String?;

    final landlord = space?['landlord'] as Map<String, dynamic>?;
    final landlordId = landlord?['landlordId'] as String?;
    final landlordFirstName = landlord?['firstName'] as String?;
    final landlordLastName = landlord?['lastName'] as String?;
    final landlordEmail = landlord?['email'] as String?;

    final status = json['status'] as String? ?? 'ACTIVE';

    DateTime? createdAt;
    if (json['requestedAt'] != null) {
      createdAt = DateTime.parse(json['requestedAt'] as String);
    } else if (json['joinedAt'] != null) {
      createdAt = DateTime.parse(json['joinedAt'] as String);
    } else if (json['createdAt'] != null) {
      createdAt = DateTime.parse(json['createdAt'] as String);
    }

    DateTime? approvedAt;
    if (json['approvedAt'] != null) {
      approvedAt = DateTime.parse(json['approvedAt'] as String);
    }

    // 🆕 NEW: Parse room leases array
    List<RoomLease> roomLeases = [];
    if (json['roomLeases'] != null && json['roomLeases'] is List) {
      final leasesList = json['roomLeases'] as List;
      roomLeases = leasesList
          .map((leaseJson) => RoomLease.fromJson(leaseJson as Map<String, dynamic>))
          .toList();
    }

    return Membership(
      id: membershipId,
      userId: userId,
      spaceId: spaceId,
      spaceName: spaceName,
      status: status,
      createdAt: createdAt,
      approvedAt: approvedAt,
      userEmail: userEmail,
      userFirstName: userFirstName,
      userLastName: userLastName,
      landlordId: landlordId,
      landlordFirstName: landlordFirstName,
      landlordLastName: landlordLastName,
      landlordEmail: landlordEmail,
      roomLeases: roomLeases,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'membershipId': id,
      'userId': userId,
      if (spaceId != null) 'spaceId': spaceId,
      if (spaceName != null) 'spaceName': spaceName,
      'status': status,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (approvedAt != null) 'approvedAt': approvedAt!.toIso8601String(),
      if (userEmail != null) 'userEmail': userEmail,
      if (userFirstName != null) 'userFirstName': userFirstName,
      if (userLastName != null) 'userLastName': userLastName,
      if (landlordId != null) 'landlordId': landlordId,
      if (landlordFirstName != null) 'landlordFirstName': landlordFirstName,
      if (landlordLastName != null) 'landlordLastName': landlordLastName,
      if (landlordEmail != null) 'landlordEmail': landlordEmail,
      'roomLeases': roomLeases.map((l) => l.toJson()).toList(),
    };
  }

  Membership copyWith({
    String? id,
    String? userId,
    String? spaceId,
    String? spaceName,
    String? status,
    DateTime? createdAt,
    DateTime? approvedAt,
    String? userEmail,
    String? userFirstName,
    String? userLastName,
    String? landlordId,
    String? landlordFirstName,
    String? landlordLastName,
    String? landlordEmail,
    List<RoomLease>? roomLeases,
  }) {
    return Membership(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      spaceId: spaceId ?? this.spaceId,
      spaceName: spaceName ?? this.spaceName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      userEmail: userEmail ?? this.userEmail,
      userFirstName: userFirstName ?? this.userFirstName,
      userLastName: userLastName ?? this.userLastName,
      landlordId: landlordId ?? this.landlordId,
      landlordFirstName: landlordFirstName ?? this.landlordFirstName,
      landlordLastName: landlordLastName ?? this.landlordLastName,
      landlordEmail: landlordEmail ?? this.landlordEmail,
      roomLeases: roomLeases ?? this.roomLeases,
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isActive => status == 'ACTIVE';
  bool get isRejected => status == 'REJECTED';

  bool get isApproved => approvedAt != null;

  int? get daysSinceRequest {
    if (createdAt == null) return null;
    return DateTime.now().difference(createdAt!).inDays;
  }

  int? get daysSinceApproved {
    if (approvedAt == null) return null;
    return DateTime.now().difference(approvedAt!).inDays;
  }

  @override
  String toString() {
    return 'Membership('
        'id: $id, '
        'user: $userEmail, '
        'space: $spaceName, '
        'status: $status, '
        'activeRooms: $activeRoomCount, '
        'pendingRooms: $pendingRoomCount'
        ')';
  }
}