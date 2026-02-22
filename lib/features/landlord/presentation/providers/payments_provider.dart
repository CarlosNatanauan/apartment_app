import 'package:apartment_app/core/api/api_client.dart';
import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/features/landlord/presentation/providers/spaces_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/payment_models.dart';
import '../../data/repositories/payments_repository.dart';

// Payments state
class PaymentsState {
  final PaymentSummary? summary;
  final List<UpcomingPayment> upcomingPayments;
  final bool isLoadingSummary;
  final bool isLoadingUpcoming;
  final String? error;
  
  // Current period being viewed
  final int currentYear;
  final int currentMonth;

  PaymentsState({
    this.summary,
    this.upcomingPayments = const [],
    this.isLoadingSummary = false,
    this.isLoadingUpcoming = false,
    this.error,
    required this.currentYear,
    required this.currentMonth,
  });

  PaymentsState copyWith({
    PaymentSummary? summary,
    List<UpcomingPayment>? upcomingPayments,
    bool? isLoadingSummary,
    bool? isLoadingUpcoming,
    String? error,
    int? currentYear,
    int? currentMonth,
    bool clearError = false,
    bool clearSummary = false,
  }) {
    return PaymentsState(
      summary: clearSummary ? null : (summary ?? this.summary),
      upcomingPayments: upcomingPayments ?? this.upcomingPayments,
      isLoadingSummary: isLoadingSummary ?? this.isLoadingSummary,
      isLoadingUpcoming: isLoadingUpcoming ?? this.isLoadingUpcoming,
      error: clearError ? null : (error ?? this.error),
      currentYear: currentYear ?? this.currentYear,
      currentMonth: currentMonth ?? this.currentMonth,
    );
  }
}

// Payments notifier
class PaymentsNotifier extends Notifier<PaymentsState> {
  late final PaymentsRepository _repository;

  @override
  PaymentsState build() {
    final apiClient = ref.read(apiClientProvider);
    _repository = PaymentsRepository(apiClient);
    
    final now = DateTime.now();
    return PaymentsState(
      currentYear: now.year,
      currentMonth: now.month,
    );
  }

  // Load payment summary for current period
  Future<void> loadSummary(String spaceId) async {
    state = state.copyWith(isLoadingSummary: true, clearError: true);

    try {
      print('💰 Loading payment summary...');
      
      final summary = await _repository.getPaymentSummary(
        spaceId,
        year: state.currentYear,
        month: state.currentMonth,
      );
      
      print('✅ Summary loaded: ${summary.totalTenants} tenants, ${summary.overdueCount} overdue');
      
      state = state.copyWith(
        summary: summary,
        isLoadingSummary: false,
      );
    } on ApiException catch (e) {
      print('❌ Failed to load summary (ApiException): ${e.message}');
      
      state = state.copyWith(
        isLoadingSummary: false,
        error: e.message,
      );
    } catch (e) {
      print('❌ Failed to load summary (Exception): $e');
      
      state = state.copyWith(
        isLoadingSummary: false,
        error: 'Failed to load payment summary',
      );
    }
  }

  // Load upcoming payments
  Future<void> loadUpcoming(String spaceId, {int days = 7}) async {
    state = state.copyWith(isLoadingUpcoming: true, clearError: true);

    try {
      print('⏰ Loading upcoming payments...');
      
      final upcoming = await _repository.getUpcomingPayments(
        spaceId,
        days: days,
      );
      
      print('✅ Upcoming loaded: ${upcoming.length} payments');
      
      state = state.copyWith(
        upcomingPayments: upcoming,
        isLoadingUpcoming: false,
      );
    } on ApiException catch (e) {
      print('❌ Failed to load upcoming (ApiException): ${e.message}');
      
      state = state.copyWith(
        isLoadingUpcoming: false,
        error: e.message,
      );
    } catch (e) {
      print('❌ Failed to load upcoming (Exception): $e');
      
      state = state.copyWith(
        isLoadingUpcoming: false,
        error: 'Failed to load upcoming payments',
      );
    }
  }

  // Load both summary and upcoming
  Future<void> loadAll(String spaceId) async {
    await Future.wait([
      loadSummary(spaceId),
      loadUpcoming(spaceId),
    ]);
  }

  // Mark payment as paid
  Future<void> markPaid({
    required String spaceId,
    required String leaseId,
    required int year,
    required int month,
    String? note,
  }) async {
    try {
      print('✅ Marking payment as paid...');
      
      await _repository.markPaid(
        leaseId: leaseId,
        year: year,
        month: month,
        note: note,
      );
      
      print('✅ Payment marked, refreshing data...');
      
      // Refresh both summary and upcoming
      await loadAll(spaceId);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to mark payment: ${e.toString()}');
    }
  }

  // Unmark payment
  Future<void> unmarkPaid({
    required String spaceId,
    required String leaseId,
    required int year,
    required int month,
  }) async {
    try {
      print('❌ Unmarking payment...');
      
      await _repository.unmarkPaid(
        leaseId: leaseId,
        year: year,
        month: month,
      );
      
      print('✅ Payment unmarked, refreshing data...');
      
      // Refresh both summary and upcoming
      await loadAll(spaceId);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to unmark payment: ${e.toString()}');
    }
  }

  // Navigate to different month
  void setMonth(int year, int month) {
    if (year == state.currentYear && month == state.currentMonth) {
      return; // Already on this month
    }
    
    state = state.copyWith(
      currentYear: year,
      currentMonth: month,
      clearSummary: true, // Clear old summary
    );
  }

  // Go to previous month
  void previousMonth() {
    final newDate = DateTime(state.currentYear, state.currentMonth - 1);
    setMonth(newDate.year, newDate.month);
  }

  // Go to next month
  void nextMonth() {
    final newDate = DateTime(state.currentYear, state.currentMonth + 1);
    setMonth(newDate.year, newDate.month);
  }

  // Go to current month
  void goToCurrentMonth() {
    final now = DateTime.now();
    setMonth(now.year, now.month);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Provider
final paymentsProvider = NotifierProvider<PaymentsNotifier, PaymentsState>(() {
  return PaymentsNotifier();
});