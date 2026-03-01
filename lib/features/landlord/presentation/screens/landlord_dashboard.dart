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
  final VoidCallback? onSwitchToSpaces;

  const LandlordDashboard({super.key, this.onSwitchToSpaces});

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
      padding: const EdgeInsets.all(24),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height - 220,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.landlordColor.withValues(alpha: 0.1),
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
                'Welcome, Landlord!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Set up your first space to start managing tenants, payments, and maintenance.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Steps
              _OnboardingStep(
                number: '1',
                icon: Icons.add_business_outlined,
                title: 'Create a Space',
                subtitle: 'Add your apartment complex or building',
              ),
              const SizedBox(height: 12),
              _OnboardingStep(
                number: '2',
                icon: Icons.door_front_door_outlined,
                title: 'Add Units',
                subtitle: 'Define individual rooms or units inside your space',
              ),
              const SizedBox(height: 12),
              _OnboardingStep(
                number: '3',
                icon: Icons.people_outline,
                title: 'Add Tenants',
                subtitle: 'Share your join code so tenants can request to join',
              ),

              const SizedBox(height: 32),

              // CTA button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: widget.onSwitchToSpaces,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Go to Spaces'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.landlordColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
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
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.landlordColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: AppTheme.landlordColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VIEWING SPACE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSpaceId,
                          isExpanded: true,
                          isDense: true,
                          hint: const Text(
                            'Select Space',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          icon: const Icon(
                            Icons.expand_more,
                            color: AppTheme.landlordColor,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                          items: spaces.map<DropdownMenuItem<String>>((space) {
                            return DropdownMenuItem<String>(
                              value: space.id,
                              child: Text(
                                space.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: _onSpaceSelected,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

// Onboarding step row for the empty state
class _OnboardingStep extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardingStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.landlordColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.landlordColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: AppTheme.landlordColor),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header
          InkWell(
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
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E40AF), AppTheme.landlordColor],
                ),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.payments,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Payments · ${summary!.periodLabel}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (summary!.hasOverdue) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${summary!.overdueCount} Overdue',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.white, size: 12),
                ],
              ),
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: summary!.percentPaid / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(
                      summary!.hasOverdue
                          ? AppTheme.warningColor
                          : AppTheme.successColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${summary!.percentPaid.toStringAsFixed(0)}% Paid',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textHint),
                ),
                const SizedBox(height: 16),

                // Stats
                Row(
                  children: [
                    Expanded(
                      child: _StatColumn(
                        label: 'Expected',
                        value: CurrencyFormatter.formatCents(
                            summary!.totalExpected),
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Expanded(
                      child: _StatColumn(
                        label: 'Paid',
                        value: CurrencyFormatter.formatCents(
                            summary!.totalPaid),
                        color: AppTheme.successColor,
                      ),
                    ),
                    Expanded(
                      child: _StatColumn(
                        label: 'Unpaid',
                        value: CurrencyFormatter.formatCents(
                            summary!.totalUnpaid),
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

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
                      side:
                          const BorderSide(color: AppTheme.landlordColor),
                    ),
                    child: const Text('View All Payments'),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        child: Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E40AF), AppTheme.landlordColor],
                ),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.schedule,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Upcoming Payments',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      size: 28,
                      color: AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'All caught up!',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'No payments due in the next 7 days',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final displayList = upcomingPayments.take(3).toList();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E40AF), AppTheme.landlordColor],
              ),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.schedule,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Upcoming Payments',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (upcomingPayments.length > 3)
                  InkWell(
                    onTap: () {
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
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Payment items
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: displayList
                  .map((payment) => _UpcomingPaymentItem(
                        payment: payment,
                        spaceId: spaceId,
                      ))
                  .toList(),
            ),
          ),
        ],
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
    if (payment.isDueToday) return AppTheme.errorColor;
    if (payment.isDueSoon) return AppTheme.warningColor;
    return AppTheme.successColor;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urgencyColor = _getUrgencyColor();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _showMarkPaidDialog(context, ref),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: urgencyColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: urgencyColor.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              // Days indicator box
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: urgencyColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
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
                        fontSize: 15,
                        height: 1,
                      ),
                    ),
                    Text(
                      'days',
                      style: TextStyle(
                        color: urgencyColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
                        const SizedBox(width: 6),
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