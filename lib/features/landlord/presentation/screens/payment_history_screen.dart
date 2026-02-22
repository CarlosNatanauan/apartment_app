import 'package:apartment_app/core/utils/currency_formatter.dart';
import 'package:apartment_app/features/landlord/data/models/payment_models.dart';
import 'package:apartment_app/features/landlord/data/repositories/payments_repository.dart';
import 'package:apartment_app/features/landlord/presentation/providers/spaces_provider.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  final String leaseId;
  final String tenantName;
  final String roomNumber;
  final int? monthlyRent;

  const PaymentHistoryScreen({
    super.key,
    required this.leaseId,
    required this.tenantName,
    required this.roomNumber,
    this.monthlyRent,
  });

  @override
  ConsumerState<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  List<LeasePaymentHistory>? _paymentHistory;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final repository = PaymentsRepository(apiClient);
      
      final history = await repository.getLeasePaymentHistory(widget.leaseId);
      
      setState(() {
        _paymentHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _loadPaymentHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Payment History'),
            Text(
              'Room ${widget.roomNumber}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState()
                : _paymentHistory == null || _paymentHistory!.isEmpty
                    ? _buildEmptyState()
                    : _buildHistoryList(),
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load payment history',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error ?? 'Unknown error',
                    style: const TextStyle(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadPaymentHistory,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: AppTheme.textHint.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Payment History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Payment records will appear here once payments are made.',
                    style: TextStyle(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    // Group by year
    final groupedByYear = <int, List<LeasePaymentHistory>>{};
    for (final payment in _paymentHistory!) {
      groupedByYear.putIfAbsent(payment.periodYear, () => []).add(payment);
    }

    // Sort years descending
    final sortedYears = groupedByYear.keys.toList()..sort((a, b) => b.compareTo(a));

    // Calculate stats
    final totalPayments = _paymentHistory!.where((p) => p.isPaid).length;
    final totalPaid = _paymentHistory!
        .where((p) => p.isPaid)
        .fold<int>(0, (sum, p) => sum + p.amount);

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        // Tenant info header
        _buildTenantHeader(),
        
        // Stats card
        if (totalPayments > 0) _buildStatsCard(totalPayments, totalPaid),
        
        const SizedBox(height: 8),
        
        // Payment history by year
        ...sortedYears.expand((year) {
          final yearPayments = groupedByYear[year]!;
          // Sort months descending within each year
          yearPayments.sort((a, b) => b.periodMonth.compareTo(a.periodMonth));
          
          return [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '$year',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            ...yearPayments.map((payment) => _PaymentHistoryCard(
              payment: payment,
            )),
          ];
        }),
      ],
    );
  }

  Widget _buildTenantHeader() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.tenantColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: AppTheme.tenantColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.tenantName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.door_front_door_outlined,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Room ${widget.roomNumber}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (widget.monthlyRent != null) ...[
                        const SizedBox(width: 12),
                        const Text('•', style: TextStyle(color: AppTheme.textHint)),
                        const SizedBox(width: 12),
                        Text(
                          CurrencyFormatter.formatCents(widget.monthlyRent!),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          '/month',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(int totalPayments, int totalPaid) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'Total Payments',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalPayments',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: AppTheme.borderColor,
            ),
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'Total Paid',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.formatCents(totalPaid),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  final LeasePaymentHistory payment;

  const _PaymentHistoryCard({
    required this.payment,
  });

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = payment.isPaid;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Month indicator
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isPaid 
                    ? AppTheme.successColor.withOpacity(0.1)
                    : AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isPaid 
                      ? AppTheme.successColor.withOpacity(0.3)
                      : AppTheme.errorColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    payment.periodLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isPaid ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                  ),
                  Text(
                    '${payment.periodYear}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isPaid 
                          ? AppTheme.successColor.withOpacity(0.7)
                          : AppTheme.errorColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Payment details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isPaid ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: isPaid ? AppTheme.successColor : AppTheme.errorColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isPaid ? 'Paid' : 'Unpaid',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isPaid ? AppTheme.successColor : AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                  
                  if (isPaid && payment.paidAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(payment.paidAt!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                  
                  if (payment.note != null && payment.note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      payment.note!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textHint,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            // Amount
            Text(
              CurrencyFormatter.formatCents(payment.amount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}