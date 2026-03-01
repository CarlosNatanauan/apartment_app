import 'package:apartment_app/core/utils/currency_formatter.dart';
import 'package:apartment_app/features/landlord/data/models/payment_models.dart';
import 'package:apartment_app/features/landlord/presentation/providers/payments_provider.dart';
import 'package:apartment_app/features/landlord/presentation/screens/widgets/dialogs/mark_payment_dialog.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UpcomingPaymentsScreen extends ConsumerStatefulWidget {
  final String spaceId;
  final String spaceName;

  const UpcomingPaymentsScreen({
    super.key,
    required this.spaceId,
    required this.spaceName,
  });

  @override
  ConsumerState<UpcomingPaymentsScreen> createState() => _UpcomingPaymentsScreenState();
}

class _UpcomingPaymentsScreenState extends ConsumerState<UpcomingPaymentsScreen> {
  int _selectedDays = 7;

  @override
  void initState() {
    super.initState();
    // Load upcoming payments when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentsProvider.notifier).loadUpcoming(widget.spaceId, days: _selectedDays);
    });
  }

  Future<void> _handleRefresh() async {
    await ref.read(paymentsProvider.notifier).loadUpcoming(widget.spaceId, days: _selectedDays);
  }

  void _onDaysChanged(int days) {
    setState(() => _selectedDays = days);
    ref.read(paymentsProvider.notifier).loadUpcoming(widget.spaceId, days: days);
  }

  @override
  Widget build(BuildContext context) {
    final paymentsState = ref.watch(paymentsProvider);
    final upcomingPayments = paymentsState.upcomingPayments;
    final isLoading = paymentsState.isLoadingUpcoming;

    // Group payments by urgency
    final overdue = upcomingPayments.where((p) => p.isOverdue).toList();
    final dueToday = upcomingPayments.where((p) => p.isDueToday).toList();
    final dueSoon = upcomingPayments.where((p) => p.isDueSoon).toList();
    final upcoming = upcomingPayments.where((p) => 
        !p.isOverdue && !p.isDueToday && !p.isDueSoon
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Upcoming Payments'),
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
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Column(
          children: [
            // Days selector
            _buildDaysSelector(),
            
            // Payment list
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : upcomingPayments.isEmpty
                      ? _buildEmptyState()
                      : _buildPaymentList(overdue, dueToday, dueSoon, upcoming),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Show next:',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDayChip(7),
                  const SizedBox(width: 8),
                  _buildDayChip(14),
                  const SizedBox(width: 8),
                  _buildDayChip(30),
                  const SizedBox(width: 8),
                  _buildDayChip(60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayChip(int days) {
    final isSelected = _selectedDays == days;

    return FilterChip(
      label: Text('$days days'),
      selected: isSelected,
      onSelected: (_) => _onDaysChanged(days),
      backgroundColor: AppTheme.surfaceColor,
      selectedColor: AppTheme.landlordColor.withValues(alpha: 0.1),
      checkmarkColor: AppTheme.landlordColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.landlordColor : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.landlordColor : AppTheme.borderColor,
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
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Upcoming Payments',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All payments are up to date for the next $_selectedDays days!',
                    style: const TextStyle(color: AppTheme.textSecondary),
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

  Widget _buildPaymentList(
    List<UpcomingPayment> overdue,
    List<UpcomingPayment> dueToday,
    List<UpcomingPayment> dueSoon,
    List<UpcomingPayment> upcoming,
  ) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        // Overdue section (red)
        if (overdue.isNotEmpty) ...[
          _buildSectionHeader(
            'Overdue',
            overdue.length,
            AppTheme.errorColor,
            Icons.error,
          ),
          ...overdue.map((payment) => _UpcomingPaymentCard(
            payment: payment,
            spaceId: widget.spaceId,
            urgencyColor: AppTheme.errorColor,
          )),
        ],
        
        // Due today section (orange/red)
        if (dueToday.isNotEmpty) ...[
          _buildSectionHeader(
            'Due Today',
            dueToday.length,
            AppTheme.errorColor,
            Icons.warning_amber_rounded,
          ),
          ...dueToday.map((payment) => _UpcomingPaymentCard(
            payment: payment,
            spaceId: widget.spaceId,
            urgencyColor: AppTheme.errorColor,
          )),
        ],
        
        // Due soon section (yellow)
        if (dueSoon.isNotEmpty) ...[
          _buildSectionHeader(
            'Due Soon (1-3 days)',
            dueSoon.length,
            AppTheme.warningColor,
            Icons.schedule,
          ),
          ...dueSoon.map((payment) => _UpcomingPaymentCard(
            payment: payment,
            spaceId: widget.spaceId,
            urgencyColor: AppTheme.warningColor,
          )),
        ],
        
        // Upcoming section (green)
        if (upcoming.isNotEmpty) ...[
          _buildSectionHeader(
            'Upcoming',
            upcoming.length,
            AppTheme.successColor,
            Icons.event_available,
          ),
          ...upcoming.map((payment) => _UpcomingPaymentCard(
            payment: payment,
            spaceId: widget.spaceId,
            urgencyColor: AppTheme.successColor,
          )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingPaymentCard extends ConsumerWidget {
  final UpcomingPayment payment;
  final String spaceId;
  final Color urgencyColor;

  const _UpcomingPaymentCard({
    required this.payment,
    required this.spaceId,
    required this.urgencyColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _showMarkPaidDialog(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Days indicator box (rounded-8)
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: urgencyColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      payment.isOverdue
                          ? '${-payment.daysUntilDue}'
                          : '${payment.daysUntilDue}',
                      style: TextStyle(
                        color: urgencyColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        height: 1,
                      ),
                    ),
                    Text(
                      'day${payment.daysUntilDue == 1 || payment.daysUntilDue == -1 ? '' : 's'}',
                      style: TextStyle(
                        color: urgencyColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Payment details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.tenant.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.door_front_door_outlined,
                          size: 13,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Unit ${payment.roomNumber}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: urgencyColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            payment.urgencyLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: urgencyColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount + chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatCents(payment.monthlyRent),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right,
                    color: urgencyColor,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMarkPaidDialog(BuildContext context, WidgetRef ref) async {
    await showMarkPaymentDialog(
      context: context,
      spaceId: spaceId,
      leaseId: payment.leaseId,
      tenantName: payment.tenant.fullName,
      roomNumber: payment.roomNumber,
      amount: payment.monthlyRent,
    );
  }
}