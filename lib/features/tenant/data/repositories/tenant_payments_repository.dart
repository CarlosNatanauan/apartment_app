import 'package:apartment_app/core/api/api_client.dart';
import 'package:apartment_app/core/api/api_response.dart';
import '../models/tenant_payment_models.dart';

class TenantPaymentsRepository {
  final ApiClient _apiClient;

  TenantPaymentsRepository(this._apiClient);

  // Get tenant's payments for a specific month
  Future<List<MonthlyPayment>> getMyPayments({
    required int year,
    required int month,
  }) async {
    try {
      print('💳 Loading tenant payments: $year-$month');
      
      final response = await _apiClient.get(
        '/memberships/me/payments?year=$year&month=$month',
        fromJson: (data) {
          if (data is List) {
            return data
                .map((json) => MonthlyPayment.fromJson(json as Map<String, dynamic>))
                .toList();
          }
          return <MonthlyPayment>[];
        },
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to load payments');
      }

      print('✅ Loaded ${response.data!.length} payments');
      
      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to load payments: ${e.toString()}');
    }
  }

  // Get payment history for a specific lease
  Future<List<LeasePaymentHistory>> getLeasePaymentHistory(String leaseId) async {
    try {
      print('📜 Loading payment history for lease: $leaseId');
      
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