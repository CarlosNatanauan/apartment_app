import 'package:apartment_app/features/landlord/data/models/payment_models.dart';
import 'package:apartment_app/features/landlord/data/models/space_model.dart';
import 'package:apartment_app/features/landlord/presentation/providers/notices_provider.dart';
import 'package:apartment_app/features/landlord/presentation/providers/payments_provider.dart';
import 'package:apartment_app/features/landlord/presentation/providers/spaces_provider.dart';
import 'package:apartment_app/features/landlord/presentation/screens/payment_details_screen.dart';
import 'package:apartment_app/features/landlord/presentation/screens/upcoming_payments_screen.dart';
import 'package:apartment_app/features/landlord/presentation/screens/widgets/cards/notices_section_card.dart';
import 'package:apartment_app/features/landlord/presentation/screens/widgets/dialogs/mark_payment_dialog.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:apartment_app/core/utils/currency_formatter.dart';

class LandlordDashboard extends ConsumerStatefulWidget {
  const LandlordDashboard({super.key});

  @override
  ConsumerState<LandlordDashboard> createState() => _LandlordDashboardState();
}

class _LandlordDashboardState extends ConsumerState<LandlordDashboard> {
  String? _selectedSpaceId;

  @override
  void initState() {
    super.initState();
    // Load spaces when dashboard initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(spacesProvider.notifier).loadSpaces();
    });
  }

  void _onSpaceSelected(String? spaceId) {
    if (spaceId == null || spaceId == _selectedSpaceId) return;
    
    setState(() {
      _selectedSpaceId = spaceId;
    });
    
    // Load payment data and notices for selected space
    ref.read(paymentsProvider.notifier).loadAll(spaceId);
    ref.read(noticesProvider.notifier).loadNotices(spaceId);
  }

  Future<void> _handleRefresh() async {
    if (_selectedSpaceId != null) {
      await Future.wait([
        ref.read(paymentsProvider.notifier).loadAll(_selectedSpaceId!),
        ref.read(noticesProvider.notifier).loadNotices(_selectedSpaceId!),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacesState = ref.watch(spacesProvider);
    final paymentsState = ref.watch(paymentsProvider);
    final spaces = spacesState.spaces;

    // Auto-select first space if none selected
    if (_selectedSpaceId == null && spaces.isNotEmpty) {
      Future.microtask(() => _onSpaceSelected(spaces.first.id));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: spacesState.isLoading && spaces.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : spaces.isEmpty
                ? _buildEmptyState()
                : _buildDashboard(spaces, paymentsState),
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
                      color: AppTheme.landlordColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.business,
                      size: 64,
                      color: AppTheme.landlordColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Spaces Yet',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a space first to view your dashboard.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to spaces tab
                      // (This assumes the parent LandlordMainScreen can handle tab switching)
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Go to Spaces'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.landlordColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboard(List<Space> spaces, PaymentsState paymentsState) {
    final selectedSpace = spaces.firstWhere(
      (s) => s.id == _selectedSpaceId,
      orElse: () => spaces.first,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Space Selector
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSpaceId,
                isExpanded: true,
                hint: const Text('Select Space'),
                icon: const Icon(Icons.arrow_drop_down),
                items: spaces.map<DropdownMenuItem<String>>((space) {
                  return DropdownMenuItem<String>(
                    value: space.id,
                    child: Row(
                      children: [
                        const Icon(Icons.business, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            space.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: _onSpaceSelected,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Notices Section
        if (_selectedSpaceId != null) ...[
          NoticesSectionCard(
            spaceId: _selectedSpaceId!,
            spaceName: selectedSpace.name,
          ),
          
          const SizedBox(height: 16),
        ],

        // Payment Summary Card
        if (_selectedSpaceId != null) ...[
          _PaymentSummaryCard(
            spaceId: _selectedSpaceId!,
            spaceName: selectedSpace.name,
            summary: paymentsState.summary,
            isLoading: paymentsState.isLoadingSummary,
          ),
          
          const SizedBox(height: 16),
          
          // Upcoming Payments Card
          _UpcomingPaymentsCard(
            spaceId: _selectedSpaceId!,
            spaceName: selectedSpace.name,
            upcomingPayments: paymentsState.upcomingPayments,
            isLoading: paymentsState.isLoadingUpcoming,
          ),
        ],
      ],
    );
  }
}

// Payment Summary Card Widget
class _PaymentSummaryCard extends StatelessWidget {
  final String spaceId;
  final String spaceName;
  final PaymentSummary? summary;
  final bool isLoading;

  const _PaymentSummaryCard({
    required this.spaceId,
    required this.spaceName,
    this.summary,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (summary == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentDetailsScreen(
                spaceId: spaceId,
                spaceName: spaceName,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.payments, color: AppTheme.landlordColor),
                  const SizedBox(width: 8),
                  Text(
                    'Payments - ${summary!.periodLabel}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (summary!.hasOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${summary!.overdueCount} Overdue',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: summary!.percentPaid / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(
                    summary!.hasOverdue ? AppTheme.warningColor : AppTheme.successColor,
                  ),
                ),
              ),
              
              const SizedBox(height: 4),
              
              Text(
                '${summary!.percentPaid.toStringAsFixed(0)}% Paid',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textHint,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Stats
              Row(
                children: [
                  Expanded(
                    child: _StatColumn(
                      label: 'Expected',
                      value: CurrencyFormatter.formatCents(summary!.totalExpected),
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: _StatColumn(
                      label: 'Paid',
                      value: CurrencyFormatter.formatCents(summary!.totalPaid),
                      color: AppTheme.successColor,
                    ),
                  ),
                  Expanded(
                    child: _StatColumn(
                      label: 'Unpaid',
                      value: CurrencyFormatter.formatCents(summary!.totalUnpaid),
                      color: AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // View Details button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentDetailsScreen(
                          spaceId: spaceId,
                          spaceName: spaceName,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.landlordColor,
                    side: const BorderSide(color: AppTheme.landlordColor),
                  ),
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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

// Upcoming Payments Card Widget
class _UpcomingPaymentsCard extends StatelessWidget {
  final String spaceId;
  final String spaceName;
  final List<UpcomingPayment> upcomingPayments;
  final bool isLoading;

  const _UpcomingPaymentsCard({
    required this.spaceId,
    required this.spaceName,
    required this.upcomingPayments,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (upcomingPayments.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule, color: AppTheme.successColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Upcoming Payments (Next 7 Days)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: AppTheme.successColor.withOpacity(0.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'No upcoming payments',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final displayList = upcomingPayments.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.schedule, color: AppTheme.warningColor),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Upcoming Payments (Next 7 Days)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (upcomingPayments.length > 3)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpcomingPaymentsScreen(
                            spaceId: spaceId,
                            spaceName: spaceName,
                          ),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // List of upcoming payments
            ...displayList.map((payment) => _UpcomingPaymentItem(
              payment: payment,
              spaceId: spaceId,
            )),
          ],
        ),
      ),
    );
  }
}

class _UpcomingPaymentItem extends ConsumerWidget {
  final UpcomingPayment payment;
  final String spaceId;

  const _UpcomingPaymentItem({
    required this.payment,
    required this.spaceId,
  });

  Color _getUrgencyColor() {
    if (payment.isOverdue) return AppTheme.errorColor;
    if (payment.isDueToday) return AppTheme.errorColor.withOpacity(0.8);
    if (payment.isDueSoon) return AppTheme.warningColor;
    return AppTheme.successColor;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urgencyColor = _getUrgencyColor();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Show mark paid dialog
          _showMarkPaidDialog(context, ref);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: urgencyColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: urgencyColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Days indicator
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    payment.isOverdue 
                        ? '${-payment.daysUntilDue}d'
                        : '${payment.daysUntilDue}d',
                    style: TextStyle(
                      color: urgencyColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Unit ${payment.roomNumber}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          payment.urgencyLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: urgencyColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      payment.tenant.fullName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Amount
              Text(
                CurrencyFormatter.formatCents(payment.monthlyRent),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMarkPaidDialog(BuildContext context, WidgetRef ref) async {
    final result = await showMarkPaymentDialog(
      context: context,
      spaceId: spaceId,
      leaseId: payment.leaseId,
      tenantName: payment.tenant.fullName,
      roomNumber: payment.roomNumber,
      amount: payment.monthlyRent,
    );
    
    // Dialog already handles success message and refresh
  }
}