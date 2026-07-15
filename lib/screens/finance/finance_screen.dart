import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/providers/app_settings_provider.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  int _activeAccountIndex = 0;
  final PageController _pageController = PageController();

  void _showAddTransactionDialog(bool isIncome, FinanceSettingsState settings) {
    final formKey = GlobalKey<FormState>();
    String title = '';
    double amount = 0;
    String category = 'Others';
    String account = settings.mockAccountsList.first['name'];

    showDialog(
      context: context,
      builder: (context) {
        final cats = settings.categories;
        final accs = settings.mockAccountsList;

        return AlertDialog(
          title: Text(isIncome ? 'Add Income (Mock)' : 'Add Expense (Mock)'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Description / Title'),
                    validator: (v) => v!.trim().isEmpty ? 'Enter description' : null,
                    onChanged: (v) => title = v,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Amount (₹)'),
                    keyboardType: TextInputType.number,
                    validator: (v) => double.tryParse(v ?? '') == null ? 'Enter valid amount' : null,
                    onChanged: (v) => amount = double.tryParse(v) ?? 0,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Category'),
                    value: cats.contains(category) ? category : cats.first,
                    items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => category = v ?? 'Others',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Account'),
                    value: account,
                    items: accs.map((a) => DropdownMenuItem<String>(value: a['name'], child: Text(a['name']))).toList(),
                    onChanged: (v) => account = v ?? '',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  AppSnackbar.success(context, 'Mock transaction "$title" of ₹$amount successfully recorded!');
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showTransferDialog(FinanceSettingsState settings) {
    final formKey = GlobalKey<FormState>();
    double amount = 0;
    String fromAcc = settings.mockAccountsList.first['name'];
    String toAcc = settings.mockAccountsList[1]['name'];

    showDialog(
      context: context,
      builder: (context) {
        final accs = settings.mockAccountsList;

        return AlertDialog(
          title: const Text('Transfer Balance (Mock)'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Amount (₹)'),
                    keyboardType: TextInputType.number,
                    validator: (v) => double.tryParse(v ?? '') == null ? 'Enter valid amount' : null,
                    onChanged: (v) => amount = double.tryParse(v) ?? 0,
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'From Account'),
                        value: fromAcc,
                        items: accs.map((a) => DropdownMenuItem<String>(value: a['name'], child: Text(a['name']))).toList(),
                        onChanged: (v) => fromAcc = v ?? '',
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'To Account'),
                        value: toAcc,
                        items: accs.map((a) => DropdownMenuItem<String>(value: a['name'], child: Text(a['name']))).toList(),
                        onChanged: (v) => toAcc = v ?? '',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  AppSnackbar.success(context, 'Mock transferred ₹$amount from $fromAcc to $toAcc!');
                }
              },
              child: const Text('Transfer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(financeSettingsProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Swiper Section
            _buildAccountsPageViewer(settings),
            const SizedBox(height: 16),

            // Action Buttons
            _buildActionButtonsRow(settings),
            const SizedBox(height: 24),

            // Monthly Budget Card
            _buildMonthlyBudgetCard(),
            const SizedBox(height: 24),

            // Category analytics breakdown
            _buildCategoryBreakdown(),
            const SizedBox(height: 24),

            // Recent Transactions
            const Text(
              'RECENT TRANSACTIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            _buildTransactionsList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountsPageViewer(FinanceSettingsState settings) {
    final accountsList = settings.mockAccountsList;
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pageController,
            itemCount: accountsList.length,
            onPageChanged: (index) {
              setState(() {
                _activeAccountIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final acc = accountsList[index];
              // Alternating gradient themes for cards
              final gradient = index.isEven
                  ? AppTheme.primaryGradient
                  : const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    );

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (index.isEven ? AppTheme.primary : const Color(0xFF8B5CF6)).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      acc['name'].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${acc['balance'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 26,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Mock Account Balance',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          index.isEven ? Icons.account_balance_wallet_rounded : Icons.savings_rounded,
                          color: Colors.white.withOpacity(0.3),
                          size: 40,
                        )
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            accountsList.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3.0),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _activeAccountIndex == index
                    ? AppTheme.primary
                    : AppTheme.textMuted.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtonsRow(FinanceSettingsState settings) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'Expense',
            icon: Icons.call_made_rounded,
            color: AppTheme.danger,
            onTap: () => _showAddTransactionDialog(false, settings),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionButton(
            label: 'Income',
            icon: Icons.call_received_rounded,
            color: AppTheme.accent,
            onTap: () => _showAddTransactionDialog(true, settings),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionButton(
            label: 'Transfer',
            icon: Icons.swap_horiz_rounded,
            color: AppTheme.primary,
            onTap: () => _showTransferDialog(settings),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyBudgetCard() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackground = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final Color borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MONTHLY SPENDING BUDGET',
                style: TextStyle(
                  color: isDark ? AppTheme.textMuted : AppTheme.lightTextSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
              const Icon(Icons.edit_calendar_rounded, size: 16, color: AppTheme.primary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹6,280.50',
                    style: TextStyle(
                      color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Spent out of ₹10,000.00 limits',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
              Text(
                '62.8% Used',
                style: TextStyle(
                  color: AppTheme.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              value: 0.628,
              minHeight: 8,
              backgroundColor: Color(0xFF1E293B),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackground = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final Color borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    final categories = [
      {'name': 'Food & Drinks', 'spent': 3240.00, 'percent': 0.51, 'color': const Color(0xFF3B82F6)},
      {'name': 'Transport',     'spent': 1500.00, 'percent': 0.24, 'color': const Color(0xFF10B981)},
      {'name': 'Academics',     'spent': 1100.00, 'percent': 0.17, 'color': const Color(0xFFF59E0B)},
      {'name': 'Others',        'spent':  440.50, 'percent': 0.08, 'color': const Color(0xFFEC4899)},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPENDING BREAKDOWN BY CATEGORY',
            style: TextStyle(
              color: isDark ? AppTheme.textMuted : AppTheme.lightTextSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          ...categories.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: c['color'] as Color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              c['name'] as String,
                              style: TextStyle(
                                color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '₹${(c['spent'] as double).toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: c['percent'] as double,
                        minHeight: 4,
                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(c['color'] as Color),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackground = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final Color borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    final transactions = [
      {'title': 'Stipend Received', 'type': 'income',  'amount': 5000.0, 'date': 'Today, 2:30 PM',  'category': 'Stipend', 'icon': Icons.arrow_downward},
      {'title': 'Hostel Mess Food',  'type': 'expense', 'amount': 120.0,  'date': 'Today, 1:15 PM',  'category': 'Food',    'icon': Icons.arrow_upward},
      {'title': 'Reference Book',   'type': 'expense', 'amount': 450.0,  'date': 'Yesterday',       'category': 'Academics', 'icon': Icons.arrow_upward},
      {'title': 'Uber Auto Ride',   'type': 'expense', 'amount': 150.0,  'date': '12 July',         'category': 'Transport', 'icon': Icons.arrow_upward},
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: transactions.length,
        separatorBuilder: (context, index) => Divider(
          color: borderColor,
          height: 1,
        ),
        itemBuilder: (context, index) {
          final tx = transactions[index];
          final isIncome = tx['type'] == 'income';
          final amountColor = isIncome ? AppTheme.accent : (isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary);
          final prefix = isIncome ? '+' : '-';

          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isIncome ? AppTheme.accent.withOpacity(0.12) : AppTheme.textMuted.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                tx['icon'] as IconData,
                color: isIncome ? AppTheme.accent : AppTheme.textMuted,
                size: 16,
              ),
            ),
            title: Text(
              tx['title'] as String,
              style: TextStyle(
                color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            subtitle: Text(
              '${tx['date']} • ${tx['category']}',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
            ),
            trailing: Text(
              '$prefix₹${(tx['amount'] as double).toStringAsFixed(0)}',
              style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          );
        },
      ),
    );
  }
}
