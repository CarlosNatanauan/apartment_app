// Payment Summary Model - Monthly overview of all payments
class PaymentSummary {
  final int periodYear;
  final int periodMonth;
  final int totalExpected; // in cents
  final int totalPaid; // in cents
  final int totalUnpaid; // in cents
  final int overdueCount;
  final List<TenantPayment> tenants;

  PaymentSummary({
    required this.periodYear,
    required this.periodMonth,
    required this.totalExpected,
    required this.totalPaid,
    required this.totalUnpaid,
    required this.overdueCount,
    required this.tenants,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    final tenantsList = json['tenants'] as List? ?? [];

    return PaymentSummary(
      periodYear: json['periodYear'] as int,
      periodMonth: json['periodMonth'] as int,
      totalExpected: json['totalExpected'] as int,
      totalPaid: json['totalPaid'] as int,
      totalUnpaid: json['totalUnpaid'] as int,
      overdueCount: json['overdueCount'] as int,
      tenants: tenantsList
          .map((json) => TenantPayment.fromJson(json as Map<String, dynamic>))
          .toList(),
    );
  }

  // Computed properties
  double get percentPaid =>
      totalExpected > 0 ? (totalPaid / totalExpected) * 100 : 0;

  bool get hasOverdue => overdueCount > 0;

  int get totalTenants => tenants.length;

  int get tenantsWithOverdue => tenants.where((t) => t.hasOverdue).length;

  String get periodLabel {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[periodMonth - 1]} $periodYear';
  }
}

// Tenant Payment - Payment breakdown per tenant
class TenantPayment {
  final String spaceMembershipId;
  final TenantInfo tenant;
  final List<LeasePayment> roomLeases;

  TenantPayment({
    required this.spaceMembershipId,
    required this.tenant,
    required this.roomLeases,
  });

  factory TenantPayment.fromJson(Map<String, dynamic> json) {
    final tenantJson = json['tenant'] as Map<String, dynamic>;
    final leasesList = json['roomLeases'] as List? ?? [];

    return TenantPayment(
      spaceMembershipId: json['spaceMembershipId'] as String,
      tenant: TenantInfo.fromJson(tenantJson),
      roomLeases: leasesList
          .map((json) => LeasePayment.fromJson(json as Map<String, dynamic>))
          .toList(),
    );
  }

  // Computed properties
  int get totalRent =>
      roomLeases.fold(0, (sum, l) => sum + (l.monthlyRent ?? 0));

  int get paidRent => roomLeases
      .where((l) => l.payment != null)
      .fold(0, (sum, l) => sum + (l.monthlyRent ?? 0));

  int get unpaidRent => totalRent - paidRent;

  int get paidCount => roomLeases.where((l) => l.payment != null).length;

  int get unpaidCount => roomLeases.where((l) => l.payment == null).length;

  int get overdueCount => roomLeases.where((l) => l.isOverdue).length;

  bool get hasOverdue => overdueCount > 0;

  bool get isFullyPaid =>
      roomLeases.isNotEmpty && roomLeases.every((l) => l.payment != null);
}

// Tenant Info - Basic tenant details
class TenantInfo {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;

  TenantInfo({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory TenantInfo.fromJson(Map<String, dynamic> json) {
    return TenantInfo(
      userId: json['userId'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}

// Lease Payment - Payment info for a single lease
class LeasePayment {
  final String leaseId;
  final RoomInfo? room;
  final int? monthlyRent; // in cents
  final int? paymentDueDay;
  final PaymentRecord? payment;
  final bool isOverdue;

  LeasePayment({
    required this.leaseId,
    this.room,
    this.monthlyRent,
    this.paymentDueDay,
    this.payment,
    required this.isOverdue,
  });

  factory LeasePayment.fromJson(Map<String, dynamic> json) {
    final roomJson = json['room'] as Map<String, dynamic>?;
    final paymentJson = json['payment'] as Map<String, dynamic>?;

    return LeasePayment(
      leaseId: json['leaseId'] as String,
      room: roomJson != null ? RoomInfo.fromJson(roomJson) : null,
      monthlyRent: json['monthlyRent'] as int?,
      paymentDueDay: json['paymentDueDay'] as int?,
      payment: paymentJson != null ? PaymentRecord.fromJson(paymentJson) : null,
      isOverdue: json['isOverdue'] as bool? ?? false,
    );
  }

  // Computed properties
  bool get isPaid => payment != null;
  bool get hasRentInfo => monthlyRent != null && paymentDueDay != null;
}

// Room Info - Basic room details
class RoomInfo {
  final String roomId;
  final String roomNumber;

  RoomInfo({required this.roomId, required this.roomNumber});

  factory RoomInfo.fromJson(Map<String, dynamic> json) {
    return RoomInfo(
      roomId: json['roomId'] as String,
      roomNumber: json['roomNumber']?.toString() ?? '',
    );
  }
}

// Payment Record - Actual payment details
class PaymentRecord {
  final String paymentId;
  final DateTime paidAt;
  final String? note;

  PaymentRecord({required this.paymentId, required this.paidAt, this.note});

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      paymentId: json['paymentId'] as String,
      paidAt: DateTime.parse(json['paidAt'] as String),
      note: json['note'] as String?,
    );
  }
}

// Upcoming Payment - Payment due soon
class UpcomingPayment {
  final String leaseId;
  final TenantInfo tenant;
  final String roomNumber;
  final int monthlyRent; // in cents
  final DateTime dueDateThisMonth;
  final int daysUntilDue;

  UpcomingPayment({
    required this.leaseId,
    required this.tenant,
    required this.roomNumber,
    required this.monthlyRent,
    required this.dueDateThisMonth,
    required this.daysUntilDue,
  });

  factory UpcomingPayment.fromJson(Map<String, dynamic> json) {
    final tenantJson = json['tenant'] as Map<String, dynamic>;

    return UpcomingPayment(
      leaseId: json['leaseId'] as String,
      tenant: TenantInfo.fromJson(tenantJson),
      roomNumber: json['roomNumber']?.toString() ?? '',
      monthlyRent: json['monthlyRent'] as int,
      dueDateThisMonth: DateTime.parse(json['dueDateThisMonth'] as String),
      daysUntilDue: json['daysUntilDue'] as int,
    );
  }

  // Computed properties
  bool get isDueSoon => daysUntilDue <= 3 && daysUntilDue > 0;
  bool get isDueToday => daysUntilDue == 0;
  bool get isOverdue => daysUntilDue < 0;

  String get urgencyLabel {
    if (isOverdue) {
      final days = -daysUntilDue;
      return '$days day${days == 1 ? '' : 's'} overdue';
    }
    if (isDueToday) return 'Due today';
    if (daysUntilDue == 1) return 'Due tomorrow';
    return 'Due in $daysUntilDue days';
  }
}

// Lease Payment History - Historical payment record
class LeasePaymentHistory {
  final String paymentId;
  final int periodYear;
  final int periodMonth;
  final int amount; // in cents
  final DateTime? paidAt;
  final String? note;

  LeasePaymentHistory({
    required this.paymentId,
    required this.periodYear,
    required this.periodMonth,
    required this.amount,
    this.paidAt,
    this.note,
  });

  factory LeasePaymentHistory.fromJson(Map<String, dynamic> json) {
    return LeasePaymentHistory(
      paymentId: json['paymentId'] as String,
      periodYear: json['periodYear'] as int,
      periodMonth: json['periodMonth'] as int,
      amount: json['amount'] as int,
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      note: json['note'] as String?,
    );
  }

  // Computed properties
  bool get isPaid => paidAt != null;

  String get periodLabel {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[periodMonth - 1]} $periodYear';
  }

  String get fullPeriodLabel =>
      '$periodYear-${periodMonth.toString().padLeft(2, '0')}';
}
