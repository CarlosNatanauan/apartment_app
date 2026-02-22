import 'package:apartment_app/core/utils/currency_formatter.dart';
import 'package:apartment_app/features/landlord/data/models/payment_models.dart';
import 'package:apartment_app/features/landlord/presentation/providers/payments_provider.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentDetailsScreen extends ConsumerStatefulWidget {
  final String spaceId;
  final String spaceName;

  const PaymentDetailsScreen({
    super.key,
    required this.spaceId,
    required this.spaceName,
  });

  @override
  ConsumerState<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends ConsumerState<PaymentDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Load payment data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentsProvider.notifier).loadSummary(widget.spaceId);
    });
  }

  Future<void> _handleRefresh() async {
    await ref.read(paymentsProvider.notifier).loadSummary(widget.spaceId);
  }

  void _showMarkPaidDialog(BuildContext context, LeasePayment lease, TenantInfo tenant) {
    showDialog(
      context: context,
      builder: (context) => _MarkPaymentDialog(
        spaceId: widget.spaceId,
        lease: lease,
        tenant: tenant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentsState = ref.watch(paymentsProvider);
    final summary = paymentsState.summary;
    final isLoading = paymentsState.isLoadingSummary;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Payments'),
            Text(
              widget.spaceName,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          // Month navigation
          if (summary != null) ...[
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                ref.read(paymentsProvider.notifier).previousMonth();
                ref.read(paymentsProvider.notifier).loadSummary(widget.spaceId);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    ref.read(paymentsProvider.notifier).goToCurrentMonth();
                    ref.read(paymentsProvider.notifier).loadSummary(widget.spaceId);
                  },
                  child: Text(summary.periodLabel),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                ref.read(paymentsProvider.notifier).nextMonth();
                ref.read(paymentsProvider.notifier).loadSummary(widget.spaceId);
              },
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : summary == null
                ? _buildEmptyState()
                : _buildPaymentList(summary),
      ),
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
                    Icons.payments_outlined,
                    size: 64,
                    color: AppTheme.textHint.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No payment data',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Payment information will appear here',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentList(PaymentSummary summary) {
    if (summary.tenants.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        // Summary header
        _buildSummaryHeader(summary),
        
        const SizedBox(height: 8),
        
        // Tenant payments
        ...summary.tenants.map((tenantPayment) => _TenantPaymentCard(
          tenantPayment: tenantPayment,
          onMarkPaid: (lease) => _showMarkPaidDialog(context, lease, tenantPayment.tenant),
        )),
      ],
    );
  }

  Widget _buildSummaryHeader(PaymentSummary summary) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Progress bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: summary.percentPaid / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(
                        summary.hasOverdue ? AppTheme.warningColor : AppTheme.successColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${summary.percentPaid.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Stats
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Expected',
                    value: CurrencyFormatter.formatCents(summary.totalExpected),
                    color: AppTheme.textPrimary,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Paid',
                    value: CurrencyFormatter.formatCents(summary.totalPaid),
                    color: AppTheme.successColor,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Unpaid',
                    value: CurrencyFormatter.formatCents(summary.totalUnpaid),
                    color: AppTheme.errorColor,
                  ),
                ),
              ],
            ),
            
            if (summary.hasOverdue) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.errorColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${summary.overdueCount} payment${summary.overdueCount == 1 ? '' : 's'} overdue',
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TenantPaymentCard extends StatelessWidget {
  final TenantPayment tenantPayment;
  final Function(LeasePayment) onMarkPaid;

  const _TenantPaymentCard({
    required this.tenantPayment,
    required this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tenant header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.tenantColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppTheme.tenantColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenantPayment.tenant.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        tenantPayment.tenant.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badges
                if (tenantPayment.isFullyPaid)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.successColor, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Paid',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (tenantPayment.hasOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${tenantPayment.overdueCount} Overdue',
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Room leases
            ...tenantPayment.roomLeases.map((lease) => _LeasePaymentItem(
              lease: lease,
              onMarkPaid: () => onMarkPaid(lease),
            )),
            
            // Total for tenant
            if (tenantPayment.roomLeases.length > 1) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatCents(tenantPayment.totalRent),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LeasePaymentItem extends StatelessWidget {
  final LeasePayment lease;
  final VoidCallback onMarkPaid;

  const _LeasePaymentItem({
    required this.lease,
    required this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = lease.isPaid;
    final isOverdue = lease.isOverdue;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (isPaid) {
      statusColor = AppTheme.successColor;
      statusIcon = Icons.check_circle;
      statusText = 'Paid';
    } else if (isOverdue) {
      statusColor = AppTheme.errorColor;
      statusIcon = Icons.error;
      statusText = 'Overdue';
    } else {
      statusColor = AppTheme.warningColor;
      statusIcon = Icons.pending;
      statusText = 'Unpaid';
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: statusColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.door_front_door_outlined,
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Room ${lease.room?.roomNumber ?? 'N/A'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (lease.hasRentInfo) ...[
                        Text(
                          CurrencyFormatter.formatCents(lease.monthlyRent!),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Due ${lease.paymentDueDay}${_getDaySuffix(lease.paymentDueDay!)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                      
                      if (isPaid && lease.payment != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Paid ${_formatDate(lease.payment!.paidAt)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.successColor,
                          ),
                        ),
                        if (lease.payment!.note != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Note: ${lease.payment!.note}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textHint,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                
                if (!isPaid)
                  ElevatedButton(
                    onPressed: onMarkPaid,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: const Size(0, 0),
                    ),
                    child: const Text(
                      'Mark Paid',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _MarkPaymentDialog extends ConsumerStatefulWidget {
  final String spaceId;
  final LeasePayment lease;
  final TenantInfo tenant;

  const _MarkPaymentDialog({
    required this.spaceId,
    required this.lease,
    required this.tenant,
  });

  @override
  ConsumerState<_MarkPaymentDialog> createState() => _MarkPaymentDialogState();
}

class _MarkPaymentDialogState extends ConsumerState<_MarkPaymentDialog> {
  final _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleMarkPaid() async {
    setState(() => _isSubmitting = true);

    try {
      final paymentsState = ref.read(paymentsProvider);
      
      await ref.read(paymentsProvider.notifier).markPaid(
        spaceId: widget.spaceId,
        leaseId: widget.lease.leaseId,
        year: paymentsState.currentYear,
        month: paymentsState.currentMonth,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Payment marked as paid!'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark payment: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mark Payment as Paid'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tenant info
          Text(
            widget.tenant.fullName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          Text(
            'Room ${widget.lease.room?.roomNumber ?? 'N/A'}',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Amount
          Text(
            CurrencyFormatter.formatCents(widget.lease.monthlyRent ?? 0),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.successColor,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Note field (optional)
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'e.g., Cash payment received',
              prefixIcon: Icon(Icons.note_outlined),
            ),
            maxLines: 2,
            enabled: !_isSubmitting,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleMarkPaid,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successColor,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Mark as Paid'),
        ),
      ],
    );
  }
}