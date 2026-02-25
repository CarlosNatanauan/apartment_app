// Monthly Payment Record (for a single lease in a month)
class MonthlyPayment {
  final String leaseId;
  final String roomNumber;
  final String spaceName;
  final int monthlyRent;
  final int year;
  final int month;
  final bool isPaid;
  final DateTime? paidAt;
  final String? note;
  final int paymentDueDay;

  MonthlyPayment({
    required this.leaseId,
    required this.roomNumber,
    required this.spaceName,
    required this.monthlyRent,
    required this.year,
    required this.month,
    required this.isPaid,
    this.paidAt,
    this.note,
    required this.paymentDueDay,
  });

  factory MonthlyPayment.fromJson(
    Map<String, dynamic> json, {
    required int year,
    required int month,
  }) {
    final payment = json['payment'] as Map<String, dynamic>?;
    final isPaid = payment != null && payment['paidAt'] != null;

    return MonthlyPayment(
      leaseId: json['leaseId'] as String,
      roomNumber: json['roomNumber']?.toString() ?? 'N/A',
      spaceName: json['spaceName'] as String? ?? 'Space',
      monthlyRent: json['monthlyRent'] as int? ?? 0,
      year: year,
      month: month,
      isPaid: isPaid,
      paidAt: isPaid ? DateTime.parse(payment['paidAt'] as String) : null,
      note: json['note'] as String?,
      paymentDueDay: json['paymentDueDay'] as int? ?? 1,
    );
  }

  // Due date for this month
  DateTime get dueDate {
    return DateTime(year, month, paymentDueDay);
  }

  // Days until due (negative if overdue)
  int get daysUntilDue {
    final now = DateTime.now();
    return dueDate.difference(now).inDays;
  }

  bool get isOverdue {
    return !isPaid && DateTime.now().isAfter(dueDate);
  }

  bool get isDueToday {
    final now = DateTime.now();
    return !isPaid &&
        now.year == year &&
        now.month == month &&
        now.day == paymentDueDay;
  }

  bool get isDueSoon {
    return !isPaid && daysUntilDue >= 0 && daysUntilDue <= 3;
  }

  String get statusLabel {
    if (isPaid) return 'Paid';
    if (isOverdue) return 'Overdue';
    if (isDueToday) return 'Due Today';
    if (isDueSoon) return 'Due Soon';
    return 'Upcoming';
  }

  String get monthLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[month - 1]} $year';
  }

  String get formattedDueDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[month - 1]} $paymentDueDay, $year';
  }
}

// Lease Payment History (for history screen)
class LeasePaymentHistory {
  final int periodYear;
  final int periodMonth;
  final int amount;
  final bool isPaid;
  final DateTime? paidAt;
  final String? note;

  LeasePaymentHistory({
    required this.periodYear,
    required this.periodMonth,
    required this.amount,
    required this.isPaid,
    this.paidAt,
    this.note,
  });

  factory LeasePaymentHistory.fromJson(Map<String, dynamic> json) {
    return LeasePaymentHistory(
      periodYear: json['periodYear'] as int,
      periodMonth: json['periodMonth'] as int,
      amount: json['amount'] as int,
      isPaid: json['isPaid'] as bool? ?? false,
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      note: json['note'] as String?,
    );
  }

  String get periodLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[periodMonth - 1];
  }
}