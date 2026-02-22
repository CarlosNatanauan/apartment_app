import 'package:apartment_app/core/api/api_client.dart';
import 'package:apartment_app/core/api/api_response.dart';
import '../models/payment_models.dart';

class PaymentsRepository {
  final ApiClient _apiClient;

  PaymentsRepository(this._apiClient);

  // Get payment summary for a space for a specific month
  Future<PaymentSummary> getPaymentSummary(
    String spaceId, {
    int? year,
    int? month,
  }) async {
    try {
      final now = DateTime.now();
      final y = year ?? now.year;
      final m = month ?? now.month;
      
      print('💰 Loading payment summary for space $spaceId ($y-$m)');
      
      final response = await _apiClient.get(
        '/spaces/$spaceId/payments/summary?year=$y&month=$m',
        fromJson: (data) => PaymentSummary.fromJson(data as Map<String, dynamic>),
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to load payment summary');
      }

      print('✅ Loaded payment summary: ${response.data!.totalTenants} tenants');
      
      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to load payment summary: ${e.toString()}');
    }
  }

  // Get upcoming payments (defaults to next 7 days)
  Future<List<UpcomingPayment>> getUpcomingPayments(
    String spaceId, {
    int days = 7,
  }) async {
    try {
      print('⏰ Loading upcoming payments for space $spaceId (next $days days)');
      
      final response = await _apiClient.get(
        '/spaces/$spaceId/payments/upcoming?days=$days',
        fromJson: (data) {
          if (data is List) {
            return data
                .map((json) => UpcomingPayment.fromJson(json as Map<String, dynamic>))
                .toList();
          }
          return <UpcomingPayment>[];
        },
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to load upcoming payments');
      }

      print('✅ Loaded ${response.data!.length} upcoming payments');
      
      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to load upcoming payments: ${e.toString()}');
    }
  }

  // Mark a lease payment as paid
  Future<void> markPaid({
    required String leaseId,
    required int year,
    required int month,
    String? note,
  }) async {
    try {
      print('✅ Marking payment as paid: lease=$leaseId, period=$year-$month');
      
      final Map<String, dynamic> requestData = {
        'periodYear': year,
        'periodMonth': month,
      };
      
      if (note != null && note.isNotEmpty) {
        requestData['note'] = note;
      }

      final response = await _apiClient.post(
        '/room-leases/$leaseId/payments/mark-paid',
        data: requestData,
        fromJson: (data) => data,
      );

      if (!response.ok) {
        throw Exception('Failed to mark payment as paid');
      }

      print('✅ Payment marked as paid successfully');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to mark payment as paid: ${e.toString()}');
    }
  }

  // Unmark a payment (undo mark as paid)
  Future<void> unmarkPaid({
    required String leaseId,
    required int year,
    required int month,
  }) async {
    try {
      print('❌ Unmarking payment: lease=$leaseId, period=$year-$month');
      
      final response = await _apiClient.post(
        '/room-leases/$leaseId/payments/unmark-paid',
        data: {
          'periodYear': year,
          'periodMonth': month,
        },
        fromJson: (data) => data,
      );

      if (!response.ok) {
        throw Exception('Failed to unmark payment');
      }

      print('✅ Payment unmarked successfully');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to unmark payment: ${e.toString()}');
    }
  }

  // Get payment history for a lease
  Future<List<LeasePaymentHistory>> getLeasePaymentHistory(
    String leaseId,
  ) async {
    try {
      print('📜 Loading payment history for lease $leaseId');
      
      final response = await _apiClient.get(
        '/room-leases/$leaseId/payments',
        fromJson: (data) {
          if (data is List) {
            return data
                .map((json) => LeasePaymentHistory.fromJson(json as Map<String, dynamic>))
                .toList();
          }
          return <LeasePaymentHistory>[];
        },
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to load payment history');
      }

      print('✅ Loaded ${response.data!.length} payment records');
      
      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to load payment history: ${e.toString()}');
    }
  }
}