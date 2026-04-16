import 'package:flutter/material.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: SafeArea(
        child: Column(
          children: [

            /// ===== FIXED HEADER =====
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// TITLE
                  const Text(
                    "Finance Tracker",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// SUMMARY CARD
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [

                        Column(
                          children: [
                            Text("Income", style: TextStyle(color: Colors.green)),
                            SizedBox(height: 5),
                            Text("₹1000"),
                          ],
                        ),

                        Column(
                          children: [
                            Text("Expense", style: TextStyle(color: Colors.red)),
                            SizedBox(height: 5),
                            Text("₹500"),
                          ],
                        ),

                        Column(
                          children: [
                            Text("Balance"),
                            SizedBox(height: 5),
                            Text("₹500"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// ===== SCROLLABLE PART =====
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [

                    /// ACTION BUTTONS
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [

                          _buildButton("Add Expense"),
                          _buildButton("Add Income"),
                          _buildButton("Transfer"),
                          _buildButton("Transactions"),

                        ],
                      ),
                    ),

                    /// RECENT TRANSACTIONS
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          const Text(
                            "Recent Transactions",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          _transactionTile("Food", "- ₹200"),
                          _transactionTile("Salary", "+ ₹1000"),
                          _transactionTile("Shopping", "- ₹500"),

                        ],
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// BUTTON WIDGET
  Widget _buildButton(String text) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 3)
        ],
      ),
      child: Center(child: Text(text)),
    );
  }

  /// TRANSACTION TILE
  Widget _transactionTile(String title, String amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(amount),
        ],
      ),
    );
  }
}