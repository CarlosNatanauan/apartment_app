import 'package:apartment_app/core/utils/currency_formatter.dart';
import 'package:apartment_app/features/tenant/data/models/tenant_payment_models.dart';
import 'package:apartment_app/features/tenant/presentation/provider/tenant_payments_provider.dart';
import 'package:apartment_app/features/tenant/presentation/screens/tenant_payment_history_screen.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TenantPaymentsSection extends ConsumerWidget {
  const TenantPaymentsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsState = ref.watch(tenantPaymentsProvider);
    final isLoading = paymentsState.isLoading;
    final payments = paymentsState.payments;
    final paymentsBySpace = paymentsState.paymentsBySpace;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.tenantColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.payments,
                    color: AppTheme.tenantColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'My Payments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Month navigation
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.borderColor,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      ref.read(tenantPaymentsProvider.notifier).previousMonth();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 24,
                    color: AppTheme.tenantColor,
                  ),
                  Expanded(
                    child: Text(
                      paymentsState.periodLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color: paymentsState.isCurrentMonth
                          ? AppTheme.textHint
                          : AppTheme.tenantColor,
                    ),
                    onPressed: paymentsState.isCurrentMonth
                        ? null
                        : () {
                            ref.read(tenantPaymentsProvider.notifier).nextMonth();
                          },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 24,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Loading state
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            // Empty state
            else if (payments.isEmpty)
              _buildEmptyState()
            // Payments list
            else ...[
              // Summary stats
              if (payments.length > 1) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.tenantColor.withOpacity(0.08),
                        AppTheme.tenantColor.withOpacity(0.03),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.tenantColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        label: 'Paid',
                        value: '${paymentsState.paidCount}',
                        color: AppTheme.successColor,
                        icon: Icons.check_circle,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppTheme.borderColor,
                      ),
                      _buildStatItem(
                        label: 'Unpaid',
                        value: '${paymentsState.unpaidCount}',
                        color: AppTheme.errorColor,
                        icon: Icons.pending,
                      ),
                      if (paymentsState.overdueCount > 0) ...[
                        Container(
                          width: 1,
                          height: 40,
                          color: AppTheme.borderColor,
                        ),
                        _buildStatItem(
                          label: 'Overdue',
                          value: '${paymentsState.overdueCount}',
                          color: AppTheme.errorColor,
                          icon: Icons.error,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Payments by space
              ...paymentsBySpace.entries.map((entry) {
                final spaceName = entry.key;
                final spacePayments = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Space name header
                    if (paymentsBySpace.length > 1) ...[
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.tenantColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.tenantColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.business,
                              size: 16,
                              color: AppTheme.tenantColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              spaceName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.tenantColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Payment cards
                    ...spacePayments.map((payment) => _PaymentCard(
                      payment: payment,
                    )),
                  ],
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.textHint.withOpacity(0.03),
            AppTheme.textHint.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.tenantColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppTheme.tenantColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Payments This Month',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any active room leases\nfor this period',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Individual Payment Card
class _PaymentCard extends StatelessWidget {
  final MonthlyPayment payment;

  const _PaymentCard({required this.payment});

  Color _getStatusColor() {
    if (payment.isPaid) return AppTheme.successColor;
    if (payment.isOverdue) return AppTheme.errorColor;
    if (payment.isDueToday) return AppTheme.errorColor.withOpacity(0.8);
    if (payment.isDueSoon) return AppTheme.warningColor;
    return AppTheme.textSecondary;
  }

  IconData _getStatusIcon() {
    if (payment.isPaid) return Icons.check_circle;
    if (payment.isOverdue) return Icons.error;
    if (payment.isDueToday) return Icons.warning;
    return Icons.schedule;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to payment history
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TenantPaymentHistoryScreen(
                leaseId: payment.leaseId,
                roomNumber: payment.roomNumber,
                spaceName: payment.spaceName,
                monthlyRent: payment.monthlyRent,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Room number and status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.door_front_door_outlined,
                      size: 22,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Room ${payment.roomNumber}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              payment.statusLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Amount badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.tenantColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      CurrencyFormatter.formatCents(payment.monthlyRent),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.tenantColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              
              // Divider
              Container(
                height: 1,
                color: statusColor.withOpacity(0.15),
              ),
              
              const SizedBox(height: 12),

              // Bottom row: Payment info
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      payment.isPaid
                          ? 'Paid on ${_formatDate(payment.paidAt!)}'
                          : 'Due ${payment.formattedDueDate}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppTheme.textHint,
                  ),
                ],
              ),

              // Payment note
              if (payment.note != null && payment.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.note_outlined,
                        size: 14,
                        color: AppTheme.textHint,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          payment.note!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}