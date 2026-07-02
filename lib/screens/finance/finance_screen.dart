import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import '../../core/utils/dummy_data.dart';
import '../../core/widgets/app_snackbar.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  int _activeAccountIndex = 0;
  final PageController _pageController = PageController();

  void _showAddTransactionDialog(bool isIncome) {
    final formKey = GlobalKey<FormState>();
    String title = '';
    double amount = 0;
    String category = 'Others';
    String account = AppState.instance.mockAccountsList.value.first['name'];

    showDialog(
      context: context,
      builder: (context) {
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
                  // Dropdowns
                  ValueListenableBuilder<List<String>>(
                    valueListenable: AppState.instance.categories,
                    builder: (context, cats, _) => DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Category'),
                      value: cats.contains(category) ? category : cats.first,
                      items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => category = v ?? 'Others',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: AppState.instance.mockAccountsList,
                    builder: (context, accs, _) => DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Account'),
                      value: account,
                      items: accs.map((a) => DropdownMenuItem<String>(value: a['name'], child: Text(a['name']))).toList(),
                      onChanged: (v) => account = v ?? '',
                    ),
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
                  AppSnackbar.success(context, 'Mock transaction "${title}" of ₹$amount successfully recorded!');
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showTransferDialog() {
    final formKey = GlobalKey<FormState>();
    double amount = 0;
    String fromAcc = AppState.instance.mockAccountsList.value.first['name'];
    String toAcc = AppState.instance.mockAccountsList.value[1]['name'];

    showDialog(
      context: context,
      builder: (context) {
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
                  ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: AppState.instance.mockAccountsList,
                    builder: (context, accs, _) => Column(
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
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Swiper Section
            _buildAccountsPageViewer(),
            const SizedBox(height: 16),
            
            // Action Buttons
            _buildActionButtonsRow(),
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

  Widget _buildAccountsPageViewer() {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: AppState.instance.mockAccountsList,
      builder: (context, accountsList, _) {
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
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              acc['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const Icon(Icons.credit_card_rounded, color: Colors.white70, size: 20),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Available Balance',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                            Text(
                              '₹${acc['balance'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            // Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                accountsList.length,
                (index) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _activeAccountIndex == index ? AppTheme.primary : AppTheme.textMuted.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtonsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildActionBtn('Expense', Icons.remove_rounded, AppTheme.danger, () => _showAddTransactionDialog(false)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionBtn('Income', Icons.add_rounded, AppTheme.accent, () => _showAddTransactionDialog(true)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionBtn('Transfer', Icons.swap_horiz_rounded, AppTheme.secondary, _showTransferDialog),
        ),
      ],
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Summary',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Budget cap: ₹5,000.00',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text(
                      'Spent: ₹1,200.00',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Remaining: ₹3,800.00',
                      style: TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: 1200 / 5000,
                minHeight: 8,
                backgroundColor: const Color(0xFF1E293B),
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final categoriesList = [
      {'name': 'Food', 'amount': '₹540.00', 'ratio': 0.45, 'color': Colors.orange},
      {'name': 'Transport', 'amount': '₹300.00', 'ratio': 0.25, 'color': AppTheme.primary},
      {'name': 'Academics', 'amount': '₹180.00', 'ratio': 0.15, 'color': AppTheme.accent},
      {'name': 'Entertainment', 'amount': '₹180.00', 'ratio': 0.15, 'color': AppTheme.secondary},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Breakdown',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: categoriesList.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: cat['color'] as Color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cat['name'] as String,
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                              ),
                            ],
                          ),
                          Text(
                            cat['amount'] as String,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: cat['ratio'] as double,
                          minHeight: 5,
                          backgroundColor: const Color(0xFF1E293B),
                          valueColor: AlwaysStoppedAnimation<Color>(cat['color'] as Color),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    final list = DummyData.transactions;
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (context, index) => const Divider(color: Color(0xFF1E293B), height: 1),
        itemBuilder: (context, index) {
          final tx = list[index];
          final color = tx.isIncome ? AppTheme.accent : AppTheme.danger;
          final prefix = tx.isIncome ? '+' : '-';
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.08),
              child: Icon(
                tx.isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: color,
                size: 20,
              ),
            ),
            title: Text(
              tx.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: Text(
              '${tx.account} • ${tx.dateString}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
            trailing: Text(
              '$prefix ₹${tx.amount.toStringAsFixed(0)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          );
        },
      ),
    );
  }
}
