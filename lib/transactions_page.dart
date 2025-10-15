import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/voice_input_service.dart';
import '../utils/voice_command_parser.dart';

// ⭐️ THEME COLORS ⭐️
const Color _primaryColor = Color(0xFF008080); // Deep Teal
const Color _secondaryColor = Color(0xFFB76E79); // Rose Gold
const Color _gradientStart = Color(0xFF2C3E50); // Dark Blue-Purple
const Color _gradientEnd = Color(0xFF4CA1AF); // Lighter Blue-Teal
const Color _cardColor = Color(0xFFFFFFFF); // Pure White

// ⭐️ TEMP FIX: Define missing class locally (remove when actual file available) ⭐️
class TransactionData {
  final double? amount;
  final String? category;
  final String? description;

  TransactionData({this.amount, this.category, this.description});

  static TransactionData? parseTransaction(String text) {
    return TransactionData(amount: 100.0, category: 'Dummy', description: text);
  }
}
// ⭐️ END TEMP FIX ⭐️

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

  final VoiceInputService _voiceService = VoiceInputService();

  // 🔹 Get date range based on filter
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
        return DateTimeRange(start: startOfWeek, end: endOfWeek);
      case 'This Month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return DateTimeRange(start: startOfMonth, end: endOfMonth);
      case 'This Year':
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);
        return DateTimeRange(start: startOfYear, end: endOfYear);
      default:
        return DateTimeRange(start: DateTime(2000), end: now);
    }
  }

  // 🔹 Aggregate transactions for graph display
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
          // Group by hour
          key = DateTime(date.year, date.month, date.day, date.hour);
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
        default:
          // Group by year
          key = DateTime(date.year);
      }

      dataWithDates[key] =
          (dataWithDates[key] ?? 0) + (doc['amount'] as num).toDouble();
    }

    final sorted = dataWithDates.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    Map<String, double> result = {};
    for (var entry in sorted) {
      String label;
      switch (filter) {
        case 'Today':
          label = DateFormat('ha').format(entry.key); // e.g. 2PM
          break;
        case 'This Week':
          label = DateFormat('EEE').format(entry.key); // e.g. Mon
          break;
        case 'This Month':
          label = DateFormat('d MMM').format(entry.key); // e.g. 5 Oct
          break;
        case 'This Year':
          label = DateFormat('MMM').format(entry.key); // e.g. Jan
          break;
        default:
          label = DateFormat('y').format(entry.key); // e.g. 2025
      }
      result[label] = entry.value;
    }

    return result;
  }

  // ⭐️ Group transactions by date for the list view
  Map<String, List<QueryDocumentSnapshot>> _groupTransactionsByDate(
    List<QueryDocumentSnapshot> transactions,
  ) {
    Map<String, List<QueryDocumentSnapshot>> grouped = {};
    final DateFormat formatter = DateFormat('EEEE, d MMMM yyyy');

    for (var doc in transactions) {
      final date = (doc['date'] as Timestamp).toDate();
      final dateKey = formatter.format(date);
      grouped.putIfAbsent(dateKey, () => []).add(doc);
    }
    return grouped;
  }

  // 🔹 Show voice input dialog
  void _showVoiceInputDialog() {
    showDialog(
      context: context,
      builder: (_) => VoiceInputDialog(
        voiceService: _voiceService,
        onResult: (text) async {
          final data = TransactionData.parseTransaction(text);
          if (data != null && data.amount != null) {
            await _showConfirmTransactionDialog(data, text);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not understand. Try: "Spent 500 on food"'),
              ),
            );
          }
        },
      ),
    );
  }

  // 🔹 Confirm and save the transaction
  Future<void> _showConfirmTransactionDialog(
    TransactionData data,
    String originalText,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You said: "$originalText"'),
            const SizedBox(height: 12),
            _buildRow('Amount', '₹${data.amount}'),
            _buildRow('Category', data.category ?? 'Other'),
            _buildRow('Description', data.description ?? 'N/A'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('spending').add({
          'userId': user.uid,
          'amount': data.amount,
          'category': data.category ?? 'Other',
          'description': data.description ?? 'Voice transaction',
          'date': DateTime.now(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Transaction saved successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving transaction: $e')));
      }
    }
  }

  // 🔹 Manual input placeholder
  void _showManualInputDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tapped Add Transaction (+): Implement manual input logic here.',
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text('$label:'), Text(value)],
    ),
  );

  String formatCurrency(double amount) =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(amount);

  // ⭐️ Single transaction tile
  Widget _buildTransactionTile(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final date = (data['date'] as Timestamp).toDate();
    return Card(
      color: _cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.receipt, color: _secondaryColor),
        title: Text(data['description'] ?? 'N/A'),
        subtitle: Text(
          '${data['category']} - ${DateFormat('hh:mm a').format(date)}',
        ),
        trailing: Text(
          formatCurrency((data['amount'] as num).toDouble()),
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader(String dateKey) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(
      dateKey,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _cardColor,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text('User not logged in.')));

    final dateRange = _getDateRange(_selectedFilter);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (val) => setState(() => _selectedFilter = val),
            itemBuilder: (_) => _filters
                .map((f) => PopupMenuItem(value: f, child: Text(f)))
                .toList(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_gradientStart, _gradientEnd],
          ),
        ),
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
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_secondaryColor),
                ),
              );
            }
            if (snapshot.hasError)
              return Center(child: Text('Error: ${snapshot.error}'));
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No transactions found.',
                  style: TextStyle(color: _cardColor),
                ),
              );
            }

            final transactions = snapshot.data!.docs;
            final aggData = _aggregateTransactions(
              transactions,
              _selectedFilter,
            );
            final spots = aggData.values
                .toList()
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value))
                .toList();

            final groupedTransactions = _groupTransactionsByDate(transactions);

            final List<Widget> datedTransactionList = [];
            final sortedDateKeys = groupedTransactions.keys.toList();
            for (var dateKey in sortedDateKeys) {
              datedTransactionList.add(_buildDateHeader(dateKey));
              datedTransactionList.addAll(
                groupedTransactions[dateKey]!.map(_buildTransactionTile),
              );
            }

            return ListView(
              children: [
                if (aggData.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx >= 0 && idx < aggData.keys.length) {
                                    return Text(
                                      aggData.keys.elementAt(idx),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: _cardColor,
                                      ),
                                    );
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) => Text(
                                  '₹${(v / 1000).toStringAsFixed(0)}k',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: _cardColor,
                                  ),
                                ),
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(
                              color: _cardColor.withOpacity(0.5),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: _secondaryColor,
                              barWidth: 3,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 3,
                                    color: _cardColor,
                                    strokeWidth: 1,
                                    strokeColor: _secondaryColor,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ...datedTransactionList,
              ],
            );
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'voiceFab',
            onPressed: _showVoiceInputDialog,
            backgroundColor: _secondaryColor,
            child: const Icon(Icons.mic, color: _cardColor),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'addFab',
            onPressed: _showManualInputDialog,
            backgroundColor: _primaryColor,
            child: const Icon(Icons.add, color: _cardColor),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// 🔹 Voice Input Dialog
class VoiceInputDialog extends StatefulWidget {
  final VoiceInputService voiceService;
  final Function(String) onResult;

  const VoiceInputDialog({
    super.key,
    required this.voiceService,
    required this.onResult,
  });

  @override
  State<VoiceInputDialog> createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends State<VoiceInputDialog>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  String _statusText = 'Tap mic to start';
  late AnimationController _controller;

  static const Color _primaryColor = Color(0xFF008080);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.voiceService.stopListening();
    super.dispose();
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _statusText = 'Listening...';
    });
    _controller.repeat();

    final result = await widget.voiceService.startListening();

    _controller.stop();
    if (mounted) {
      Navigator.pop(context);
      if (result != null && result.isNotEmpty) {
        widget.onResult(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No speech detected, try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Voice Input'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _isListening ? null : _startListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? Colors.red : _primaryColor,
                boxShadow: _isListening
                    ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ]
                    : [],
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 45),
            ),
          ),
          const SizedBox(height: 16),
          Text(_statusText, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          if (!_isListening)
            const Text(
              'Example: "Spent 500 on food"',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
      actions: [
        if (!_isListening)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
      ],
    );
  }
}
