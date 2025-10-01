import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _selectedFilter = 'Today';

  final List<String> _filters = [
    'Today',
    'This Week',
    'This Month',
    'This Year',
    'All Time',
  ];

  DateTimeRange _getDateRange(String filter) {
    final now = DateTime.now();
    switch (filter) {
      case 'Today':
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day, 0, 0, 0),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return DateTimeRange(
          start: DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day,
            0,
            0,
            0,
          ),
          end: DateTime(
            endOfWeek.year,
            endOfWeek.month,
            endOfWeek.day,
            23,
            59,
            59,
          ),
        );
      case 'This Month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return DateTimeRange(start: startOfMonth, end: endOfMonth);
      case 'This Year':
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);
        return DateTimeRange(start: startOfYear, end: endOfYear);
      case 'All Time':
      default:
        return DateTimeRange(
          start: DateTime(2000, 1, 1),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
    }
  }

  // FIXED: Helper to aggregate transactions for plotting
  Map<String, double> _aggregateTransactions(
    List<QueryDocumentSnapshot> transactions,
    String filter,
  ) {
    Map<DateTime, double> dataWithDates = {};
    
    for (var doc in transactions) {
      final date = (doc['date'] as Timestamp).toDate();
      DateTime key;
      
      switch (filter) {
        case 'Today':
          // Group by 10-minute intervals for better granularity
          int tenMinInterval = (date.minute ~/ 10) * 10;
          key = DateTime(date.year, date.month, date.day, date.hour, tenMinInterval);
          break;
        case 'This Week':
          // Group by day
          key = DateTime(date.year, date.month, date.day);
          break;
        case 'This Month':
          // Group by day
          key = DateTime(date.year, date.month, date.day);
          break;
        case 'This Year':
          // Group by month
          key = DateTime(date.year, date.month);
          break;
        case 'All Time':
        default:
          // Group by year
          key = DateTime(date.year);
      }
      
      dataWithDates[key] = (dataWithDates[key] ?? 0) + (doc['amount'] as num).toDouble();
    }
    
    // Sort by DateTime and convert to display strings
    var sortedEntries = dataWithDates.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    Map<String, double> result = {};
    for (var entry in sortedEntries) {
      String displayKey;
      switch (filter) {
        case 'Today':
          displayKey = DateFormat('hh a').format(entry.key);
          break;
        case 'This Week':
          displayKey = DateFormat('EEE').format(entry.key);
          break;
        case 'This Month':
          displayKey = DateFormat('d MMM').format(entry.key);
          break;
        case 'This Year':
          displayKey = DateFormat('MMM').format(entry.key);
          break;
        case 'All Time':
        default:
          displayKey = DateFormat('y').format(entry.key);
      }
      result[displayKey] = entry.value;
    }
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not logged in.')));
    }

    final now = DateTime.now();
    final dateRange = _getDateRange(_selectedFilter);

    String formatCurrency(double amount) {
      return NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(amount);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFECE2D2),
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: const Color(0xFFD9641E),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.bar_chart),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => _filters
                .map(
                  (filter) => PopupMenuItem(value: filter, child: Text(filter)),
                )
                .toList(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "${_selectedFilter == 'Today' ? "Today's" : _selectedFilter} Transactions"
              "${_selectedFilter == 'Today' ? ' (${DateFormat('EEEE, MMM d, y').format(now)})' : ''}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // Transactions List & Chart
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('spending')
                  .where('userId', isEqualTo: user.uid)
                  .where(
                    'date',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start),
                  )
                  .where(
                    'date',
                    isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end),
                  )
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
                  return Center(
                    child: Text(
                      'No transactions for $_selectedFilter.'.replaceAll(
                        'Today',
                        'today',
                      ),
                    ),
                  );
                }

                final transactions = snapshot.data!.docs;

                // --- Line Chart Data ---
                final aggData = _aggregateTransactions(
                  transactions,
                  _selectedFilter,
                );
                final spots = aggData.entries
                    .toList()
                    .asMap()
                    .entries
                    .map(
                      (entry) =>
                          FlSpot(entry.key.toDouble(), entry.value.value),
                    )
                    .toList();

                // Group transactions by date (yyyy-MM-dd)
                final Map<String, List<QueryDocumentSnapshot>> grouped = {};
                for (var doc in transactions) {
                  final date = (doc['date'] as Timestamp).toDate();
                  final dateKey = DateFormat('yyyy-MM-dd').format(date);
                  grouped.putIfAbsent(dateKey, () => []).add(doc);
                }

                return ListView(
                  children: [
                    if (aggData.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: SizedBox(
                          height: 220,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 50,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        '₹${(value / 1000).toStringAsFixed(0)}k',
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx < 0 || idx >= aggData.keys.length)
                                        return const SizedBox.shrink();
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          aggData.keys.elementAt(idx),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: true),
                              minY: 0,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  color: const Color(0xFFD9641E),
                                  barWidth: 3,
                                  dotData: FlDotData(show: true),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // --- Existing grouped transaction list ---
                    ...grouped.entries.map((entry) {
                      final dateLabel = DateFormat(
                        'EEEE, MMM d, y',
                      ).format(DateTime.parse(entry.key));
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              dateLabel,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD9641E),
                              ),
                            ),
                          ),
                          ...entry.value.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final description = data['description'] ?? 'N/A';
                            final category = data['category'] ?? 'N/A';
                            final amount = (data['amount'] as num).toDouble();
                            final date = (data['date'] as Timestamp).toDate();

                            return Card(
                              color: Colors.white,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              elevation: 2,
                              child: ListTile(
                                leading: const Icon(
                                  Icons.receipt,
                                  color: Color(0xFFD9641E),
                                ),
                                title: Text(
                                  description,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: Colors.black),
                                ),
                                subtitle: Text(
                                  '$category - ${DateFormat('hh:mm a').format(date)}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.black87),
                                ),
                                trailing: Text(
                                  formatCurrency(amount),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}