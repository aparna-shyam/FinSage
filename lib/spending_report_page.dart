import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

enum TimePeriod { daily, weekly, monthly, yearly }

class SpendingReportPage extends StatefulWidget {
  const SpendingReportPage({super.key});

  @override
  State<SpendingReportPage> createState() => _SpendingReportPageState();
}

class _SpendingReportPageState extends State<SpendingReportPage> {
  TimePeriod _selectedPeriod = TimePeriod.daily;

  // A method to format a double to currency.
  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Get the current authenticated user.
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('User not logged in.'),
        ),
      );
    }

    // Build the query based on the selected time period
    DateTime startDate;
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case TimePeriod.daily:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case TimePeriod.weekly:
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case TimePeriod.monthly:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case TimePeriod.yearly:
        startDate = DateTime(now.year, 1, 1);
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Spending Report'),
        backgroundColor: const Color(0xFF6B5B95),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPeriodSelectionButtons(),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('spending')
                    .where('userId', isEqualTo: user.uid)
                    .where('date', isGreaterThanOrEqualTo: startDate)
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
                    return const Center(
                      child: Text('No spending data found for this period.'),
                    );
                  }

                  // Process the data for the graph and list
                  final Map<String, double> categoryTotals = {};
                  double totalSpending = 0;

                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final category = data['category'] as String;
                    final amount = (data['amount'] as num).toDouble();
                    categoryTotals.update(category, (value) => value + amount,
                        ifAbsent: () => amount);
                    totalSpending += amount;
                  }

                  final List<BarChartGroupData> barGroups = [];
                  final List<String> categories = categoryTotals.keys.toList();
                  for (int i = 0; i < categories.length; i++) {
                    barGroups.add(
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: categoryTotals[categories[i]]!,
                            color: Colors.purple,
                            width: 25,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Spending: ${_formatCurrency(totalSpending)}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 20),
                        _buildReportGraph(barGroups, categories, categoryTotals),
                        const SizedBox(height: 20),
                        _buildCategoryBreakdown(categoryTotals),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelectionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: TimePeriod.values.map((period) {
        final isSelected = period == _selectedPeriod;
        // Correctly handle the color property to avoid the type error
        final Color? buttonColor = isSelected
            ? const Color(0xFF6B5B95)
            : Theme.of(context).elevatedButtonTheme.style?.backgroundColor?.resolve({}) as Color?;

        return ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedPeriod = period;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            period.name.toUpperCase(),
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReportGraph(
    List<BarChartGroupData> barGroups,
    List<String> categories,
    Map<String, double> categoryTotals,
  ) {
    final double maxY =
        categoryTotals.values.isEmpty ? 0 : categoryTotals.values.reduce(
      (value, element) => value > element ? value : element,
    );

    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.2,
          barGroups: barGroups,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      categories[value.toInt()],
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatCurrency(value),
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                },
                interval: maxY / 5,
                reservedSize: 40,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(
                  color: Theme.of(context).dividerColor, width: 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(Map<String, double> categoryTotals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Breakdown',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categoryTotals.length,
          itemBuilder: (context, index) {
            final category = categoryTotals.keys.elementAt(index);
            final total = categoryTotals[category]!;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              child: ListTile(
                title: Text(category),
                trailing: Text(
                  _formatCurrency(total),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
