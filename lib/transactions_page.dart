import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in.')),
      );
    }

    // Get today's start and end times
    final DateTime now = DateTime.now();
    final DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Format amount to currency
    String formatCurrency(double amount) {
      return NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(amount);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: const Color(0xFF6B5B95),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's date header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Today's Transactions (${DateFormat('EEEE, MMM d, y').format(now)})",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Transactions List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('spending')
                  .where('userId', isEqualTo: user.uid)
                  .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                  .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No transactions for today.'));
                }

                final transactions = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final data = transactions[index].data() as Map<String, dynamic>;
                    final description = data['description'] ?? 'N/A';
                    final category = data['category'] ?? 'N/A';
                    final amount = (data['amount'] as num).toDouble();
                    final date = (data['date'] as Timestamp).toDate();

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.receipt),
                        title: Text(
                          description,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          '$category - ${DateFormat('hh:mm a').format(date)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: Text(
                          formatCurrency(amount),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.red,
                              ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
