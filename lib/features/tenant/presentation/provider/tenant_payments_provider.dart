import 'package:apartment_app/core/api/api_client.dart';
import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/tenant_payment_models.dart';
import '../../data/repositories/tenant_payments_repository.dart';

// Tenant Payments State
class TenantPaymentsState {
  final List<MonthlyPayment> payments;
  final bool isLoading;
  final String? error;
  final int currentYear;
  final int currentMonth;

  TenantPaymentsState({
    this.payments = const [],
    this.isLoading = false,
    this.error,
    int? currentYear,
    int? currentMonth,
  })  : currentYear = currentYear ?? DateTime.now().year,
        currentMonth = currentMonth ?? DateTime.now().month;

  TenantPaymentsState copyWith({
    List<MonthlyPayment>? payments,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? currentYear,
    int? currentMonth,
  }) {
    return TenantPaymentsState(
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentYear: currentYear ?? this.currentYear,
      currentMonth: currentMonth ?? this.currentMonth,
    );
  }

  // Group payments by space
  Map<String, List<MonthlyPayment>> get paymentsBySpace {
    final Map<String, List<MonthlyPayment>> grouped = {};
    
    for (final payment in payments) {
      grouped.putIfAbsent(payment.spaceName, () => []).add(payment);
    }
    
    return grouped;
  }

  // Get paid/unpaid counts
  int get paidCount => payments.where((p) => p.isPaid).length;
  int get unpaidCount => payments.where((p) => !p.isPaid).length;
  int get overdueCount => payments.where((p) => p.isOverdue).length;

  // Check if current month
  bool get isCurrentMonth {
    final now = DateTime.now();
    return currentYear == now.year && currentMonth == now.month;
  }

  String get periodLabel {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[currentMonth - 1]} $currentYear';
  }
}

// Tenant Payments Notifier
class TenantPaymentsNotifier extends Notifier<TenantPaymentsState> {
  late final TenantPaymentsRepository _repository;

  @override
  TenantPaymentsState build() {
    final apiClient = ref.read(apiClientProvider);
    _repository = TenantPaymentsRepository(apiClient);
    
    return TenantPaymentsState();
  }

  // Load payments for current month
  Future<void> loadPayments() async {
    await loadPaymentsForMonth(
      year: state.currentYear,
      month: state.currentMonth,
    );
  }

  // Load payments for specific month
  Future<void> loadPaymentsForMonth({
    required int year,
    required int month,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      currentYear: year,
      currentMonth: month,
    );

    try {
      print('💳 Loading payments for $year-$month');
      
      final payments = await _repository.getMyPayments(
        year: year,
        month: month,
      );
      
      print('✅ Loaded ${payments.length} payments');
      
      state = state.copyWith(
        payments: payments,
        isLoading: false,
      );
    } on ApiException catch (e) {
      print('❌ Failed to load payments (ApiException): ${e.message}');
      
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      print('❌ Failed to load payments (Exception): $e');
      
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load payments',
      );
    }
  }

  // Navigate to next month
  void nextMonth() {
    int newMonth = state.currentMonth + 1;
    int newYear = state.currentYear;
    
    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    }
    
    loadPaymentsForMonth(year: newYear, month: newMonth);
  }

  // Navigate to previous month
  void previousMonth() {
    int newMonth = state.currentMonth - 1;
    int newYear = state.currentYear;
    
    if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }
    
    loadPaymentsForMonth(year: newYear, month: newMonth);
  }

  // Go to current month
  void goToCurrentMonth() {
    final now = DateTime.now();
    loadPaymentsForMonth(year: now.year, month: now.month);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Provider
final tenantPaymentsProvider =
    NotifierProvider<TenantPaymentsNotifier, TenantPaymentsState>(() {
  return TenantPaymentsNotifier();
});