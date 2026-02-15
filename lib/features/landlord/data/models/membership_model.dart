class Membership {
  final String id;
  final String userId;
  final String? spaceId;
  final String? spaceName; // Space name
  final String? roomId;
  final String status;
  final DateTime? createdAt; // When requested (for all)
  final DateTime? approvedAt; // 🆕 NEW: When approved (only for ACTIVE)
  final String? userEmail;
  final String? userFirstName; // 🆕 NEW: Tenant first name (for landlord view)
  final String? userLastName; // 🆕 NEW: Tenant last name (for landlord view)
  final String? roomNumber;

  // Landlord info
  final String? landlordId;
  final String? landlordFirstName; // 🆕 NEW
  final String? landlordLastName; // 🆕 NEW
  final String? landlordEmail;

  // Rent fields
  final int? monthlyRent;
  final DateTime? rentStartDate;
  final int? paymentDueDay;

  Membership({
    required this.id,
    required this.userId,
    this.spaceId,
    this.spaceName,
    this.roomId,
    required this.status,
    this.createdAt,
    this.approvedAt,
    this.userEmail,
    this.userFirstName, // 🆕 NEW
    this.userLastName, // 🆕 NEW
    this.roomNumber,
    this.landlordId,
    this.landlordFirstName, // 🆕 NEW
    this.landlordLastName, // 🆕 NEW
    this.landlordEmail,
    this.monthlyRent,
    this.rentStartDate,
    this.paymentDueDay,
  });

  String? get tenantFullName {
    if (userFirstName != null && userLastName != null) {
      return '$userFirstName $userLastName';
    }
    return null;
  }

  // 🆕 NEW: Get landlord full name (for tenant view)
  String? get landlordFullName {
    if (landlordFirstName != null && landlordLastName != null) {
      return '$landlordFirstName $landlordLastName';
    }
    return null;
  }

  factory Membership.fromJson(Map<String, dynamic> json) {
    // Extract membership ID
    final membershipId =
        json['membershipId'] as String? ?? json['id'] as String;

    // Extract user info (from tenant object for landlord view)
    final tenant = json['tenant'] as Map<String, dynamic>?;
    final userId =
        tenant?['userId'] as String? ?? json['userId'] as String? ?? '';
    final userEmail =
        tenant?['email'] as String? ?? json['userEmail'] as String?;
    final userFirstName = tenant?['firstName'] as String?; // 🆕 NEW
    final userLastName = tenant?['lastName'] as String?; // 🆕 NEW

    // Extract space info
    final space = json['space'] as Map<String, dynamic>?;
    final spaceId = space?['spaceId'] as String? ?? json['spaceId'] as String?;
    final spaceName = space?['name'] as String?;

    // 🆕 NEW: Extract landlord info from space
    final landlord = space?['landlord'] as Map<String, dynamic>?;
    final landlordId = landlord?['landlordId'] as String?;
    final landlordFirstName = landlord?['firstName'] as String?; // 🆕 NEW
    final landlordLastName = landlord?['lastName'] as String?; // 🆕 NEW
    final landlordEmail = landlord?['email'] as String?;

    // Extract room info
    final room = json['room'] as Map<String, dynamic>?;
    final roomId = room?['roomId'] as String? ?? json['roomId'] as String?;
    final roomNumberRaw = room?['roomNumber'] ?? json['roomNumber'];
    final roomNumber = roomNumberRaw?.toString();

    // Extract status
    final status = json['status'] as String? ?? 'ACTIVE';

    // Extract timestamps
    DateTime? createdAt;
    if (json['requestedAt'] != null) {
      createdAt = DateTime.parse(json['requestedAt'] as String);
    } else if (json['joinedAt'] != null) {
      createdAt = DateTime.parse(json['joinedAt'] as String);
    } else if (json['createdAt'] != null) {
      createdAt = DateTime.parse(json['createdAt'] as String);
    }

    // 🆕 NEW: Extract approvedAt timestamp
    DateTime? approvedAt;
    if (json['approvedAt'] != null) {
      approvedAt = DateTime.parse(json['approvedAt'] as String);
    }

    // Extract rent fields
    final monthlyRent = json['monthlyRent'] as int?;

    DateTime? rentStartDate;
    if (json['rentStartDate'] != null) {
      rentStartDate = DateTime.parse(json['rentStartDate'] as String);
    }

    final paymentDueDay = json['paymentDueDay'] as int?;

    return Membership(
      id: membershipId,
      userId: userId,
      spaceId: spaceId,
      spaceName: spaceName,
      roomId: roomId,
      status: status,
      createdAt: createdAt,
      approvedAt: approvedAt,
      userEmail: userEmail,
      userFirstName: userFirstName, // 🆕 NEW
      userLastName: userLastName, // 🆕 NEW
      roomNumber: roomNumber,
      landlordId: landlordId,
      landlordFirstName: landlordFirstName, // 🆕 NEW
      landlordLastName: landlordLastName, // 🆕 NEW
      landlordEmail: landlordEmail,
      monthlyRent: monthlyRent,
      rentStartDate: rentStartDate,
      paymentDueDay: paymentDueDay,
    );
  }

Map<String, dynamic> toJson() {
  return {
    'membershipId': id,
    'userId': userId,
    if (spaceId != null) 'spaceId': spaceId,
    if (spaceName != null) 'spaceName': spaceName,
    if (roomId != null) 'roomId': roomId,
    'status': status,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (approvedAt != null) 'approvedAt': approvedAt!.toIso8601String(),
    if (userEmail != null) 'userEmail': userEmail,
    if (userFirstName != null) 'userFirstName': userFirstName,
    if (userLastName != null) 'userLastName': userLastName,
    if (roomNumber != null) 'roomNumber': roomNumber,

    // ✅ landlord fields
    if (landlordId != null) 'landlordId': landlordId,
    if (landlordFirstName != null) 'landlordFirstName': landlordFirstName,
    if (landlordLastName != null) 'landlordLastName': landlordLastName,
    if (landlordEmail != null) 'landlordEmail': landlordEmail,

    if (monthlyRent != null) 'monthlyRent': monthlyRent,
    if (rentStartDate != null) 'rentStartDate': rentStartDate!.toIso8601String(),
    if (paymentDueDay != null) 'paymentDueDay': paymentDueDay,
  };
}

Membership copyWith({
  String? id,
  String? userId,
  String? spaceId,
  String? spaceName,
  String? roomId,
  String? status,
  DateTime? createdAt,
  DateTime? approvedAt,
  String? userEmail,
  String? userFirstName,
  String? userLastName,
  String? roomNumber,

  String? landlordId,
  String? landlordFirstName,
  String? landlordLastName,
  String? landlordEmail,

  int? monthlyRent,
  DateTime? rentStartDate,
  int? paymentDueDay,
}) {
  return Membership(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    spaceId: spaceId ?? this.spaceId,
    spaceName: spaceName ?? this.spaceName,
    roomId: roomId ?? this.roomId,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    approvedAt: approvedAt ?? this.approvedAt,
    userEmail: userEmail ?? this.userEmail,
    userFirstName: userFirstName ?? this.userFirstName,
    userLastName: userLastName ?? this.userLastName,
    roomNumber: roomNumber ?? this.roomNumber,

    landlordId: landlordId ?? this.landlordId,
    landlordFirstName: landlordFirstName ?? this.landlordFirstName,
    landlordLastName: landlordLastName ?? this.landlordLastName,
    landlordEmail: landlordEmail ?? this.landlordEmail,

    monthlyRent: monthlyRent ?? this.monthlyRent,
    rentStartDate: rentStartDate ?? this.rentStartDate,
    paymentDueDay: paymentDueDay ?? this.paymentDueDay,
  );
}


  bool get isPending => status == 'PENDING';
  bool get isActive => status == 'ACTIVE';
  bool get isRejected => status == 'REJECTED';

  bool get hasRentInfo =>
      monthlyRent != null && rentStartDate != null && paymentDueDay != null;

  // 🆕 NEW: Helper to check if approved
  bool get isApproved => approvedAt != null;

  // 🆕 NEW: Helper to get days since requested
  int? get daysSinceRequest {
    if (createdAt == null) return null;
    return DateTime.now().difference(createdAt!).inDays;
  }

  // 🆕 NEW: Helper to get days since approved
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
        'room: $roomNumber, '
        'landlord: $landlordEmail, ' // 🆕 NEW
        'rent: ${monthlyRent != null ? '\$${(monthlyRent! / 100).toStringAsFixed(2)}' : 'N/A'}'
        ')';
  }
}
