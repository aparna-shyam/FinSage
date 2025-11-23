import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

// Assuming these external services are defined elsewhere
import '../services/voice_input_service.dart';
// import '../utils/voice_command_parser.dart'; // Not strictly needed in this file

// ⭐️ THEME COLORS ⭐️
const Color _primaryColor = Color(0xFF008080); // Deep Teal
const Color _secondaryColor = Color(0xFFB76E79); // Rose Gold
const Color _gradientStart = Color(0xFF2C3E50); // Dark Blue-Purple
const Color _gradientEnd = Color(0xFF4CA1AF); // Lighter Blue-Teal
const Color _cardColor = Color(0xFFFFFFFF); // Pure White

// ⭐️ MOCK/Placeholder for TransactionData/Parser (MUST BE REPLACED) ⭐️
// This class and method are currently mocked to allow the code to run.
// In a real app, `voice_command_parser.dart` would provide a robust implementation.
class TransactionData {
  final double? amount;
  final String? category;
  final String? description;
  final bool isExpense; // Added to handle income/expense if necessary

  TransactionData({
    this.amount,
    this.category,
    this.description,
    this.isExpense = true, // Defaulting to expense
  });

  // ⚠️ NOTE: This is a placeholder and should be implemented robustly
  // by `VoiceCommandParser` from `../utils/voice_command_parser.dart`
  static TransactionData? parseTransaction(String text) {
    if (text.toLowerCase().contains('spent') ||
        text.toLowerCase().contains('paid')) {
      return TransactionData(
        amount: 100.0,
        category: 'Food',
        description: text,
      );
    }
    return null;
  }
}
// ⭐️ END MOCK/Placeholder ⭐️

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _selectedFilter = 'This Week'; // default is weekly

  // Filters: weekly, monthly, month comparison, yearly, hourly
  final List<String> _filters = [
    'This Week',
    'This Month',
    'Month Comparison',
    'Yearly',
    'Hourly',
  ];

  // ⚠️ NOTE: VoiceInputService must be correctly initialized and defined
  // For this fix, we assume it's correctly imported/defined.
  final VoiceInputService _voiceService = VoiceInputService();

  // 🔹 Get date range based on filter
  DateTimeRange _getDateRange(String filter) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (filter) {
      case 'This Week':
        // Start of the week (Monday)
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        end = DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
          59,
        ); // Up to now, or end of day
        break;
      case 'Month Comparison':
        // Show last 6 months including current month for comparison
        final monthsBack = 5;
        start = DateTime(now.year, now.month - monthsBack, 1);
        end = DateTime(
          now.year,
          now.month + 1,
          0,
          23,
          59,
          59,
        ); // End of current month
        break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59); // Up to now
        break;
      case 'Yearly':
        // Current year
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case 'Hourly':
        // Today (group by hour)
        start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      default:
        start = DateTime(2000);
        end = now;
    }
    return DateTimeRange(start: start, end: end);
  }

  // 🔹 Aggregate transactions for graph display - CORRECTED LOGIC
  Map<String, double> _aggregateTransactions(
    List<QueryDocumentSnapshot> transactions,
    String filter,
    DateTimeRange dateRange,
  ) {
    Map<DateTime, double> dataWithDates = {};

    // 1. Calculate raw aggregation
    for (var doc in transactions) {
      final date = (doc['date'] as Timestamp).toDate();
      DateTime key;

      switch (filter) {
        case 'This Week':
        case 'This Month':
          key = DateTime(date.year, date.month, date.day); // Group by day
          break;
        case 'Month Comparison':
        case 'Yearly':
          key = DateTime(date.year, date.month); // Group by month
          break;
        case 'Hourly':
          key = DateTime(
            date.year,
            date.month,
            date.day,
            date.hour,
          ); // Group by hour
          break;
        default:
          key = DateTime(date.year);
      }

      dataWithDates[key] =
          (dataWithDates[key] ?? 0) + (doc['amount'] as num).toDouble();
    }

    // 2. Fill in zero values for missing time units within the range
    Map<DateTime, double> filledData = {};
    DateTime current = dateRange.start;

    while (current.isBefore(dateRange.end) ||
        current.isAtSameMomentAs(dateRange.end)) {
      DateTime key;
      String label;

      switch (filter) {
        case 'This Week':
        case 'This Month':
          key = DateTime(current.year, current.month, current.day);
          label = DateFormat(
            filter == 'This Week' ? 'EEE' : 'd MMM',
          ).format(key);
          current = current.add(const Duration(days: 1));
          break;
        case 'Month Comparison':
        case 'Yearly':
          key = DateTime(current.year, current.month);
          label = DateFormat(
            filter == 'Month Comparison' ? 'MMM yyyy' : 'MMM',
          ).format(key);
          current = DateTime(current.year, current.month + 1, 1);
          break;
        case 'Hourly':
          key = DateTime(
            current.year,
            current.month,
            current.day,
            current.hour,
          );
          label = DateFormat('ha').format(key);
          current = current.add(const Duration(hours: 1));
          break;
        default:
          key = DateTime(current.year);
          label = DateFormat('y').format(key);
          current = DateTime(current.year + 1);
      }

      // Stop if the key generated is beyond the end date
      if (key.isAfter(dateRange.end)) break;

      filledData[key] = dataWithDates[key] ?? 0.0;
    }

    // 3. Convert keys to string labels, keeping them in order
    Map<String, double> result = {};
    final sortedKeys = filledData.keys.toList()..sort();

    for (var key in sortedKeys) {
      String label;
      switch (filter) {
        case 'This Week':
          label = DateFormat('EEE').format(key); // e.g. Mon
          break;
        case 'This Month':
          label = DateFormat('d MMM').format(key); // e.g. 5 Oct
          break;
        case 'Month Comparison':
          label = DateFormat('MMM yyyy').format(key); // e.g. Oct 2025
          break;
        case 'Yearly':
          label = DateFormat('MMM').format(key); // e.g. Jan
          break;
        case 'Hourly':
          label = DateFormat('ha').format(key); // e.g. 2PM
          break;
        default:
          label = DateFormat('y').format(key); // e.g. 2025
      }
      result[label] = filledData[key]!;
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
      final data = doc.data() as Map<String, dynamic>;
      // Safely access and cast the date field
      final dateTimestamp = data['date'];
      if (dateTimestamp is Timestamp) {
        final date = dateTimestamp.toDate();
        final dateKey = formatter.format(date);
        grouped.putIfAbsent(dateKey, () => []).add(doc);
      }
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
          // Use the correct parser from the external utility
          final data = TransactionData.parseTransaction(text);
          if (data != null && data.amount != null) {
            // Check if amount is valid
            if (data.amount! > 0) {
              await _showConfirmTransactionDialog(data, text);
            } else {
              _showSnackbar('Amount must be greater than zero.');
            }
          } else {
            _showSnackbar('Could not understand. Try: "Spent 500 on food"');
          }
        },
      ),
    );
  }

  // Helper for showing Snackbars
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // 🔹 Confirm and save the transaction
  Future<void> _showConfirmTransactionDialog(
    TransactionData data,
    String originalText,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackbar('User not logged in. Cannot save transaction.');
      return;
    }

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
            _buildRow('Amount', formatCurrency(data.amount!)),
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
        _showSnackbar('✅ Transaction saved successfully!');
      } catch (e) {
        _showSnackbar('Error saving transaction: $e');
      }
    }
  }

  // 🔹 Manual input placeholder
  void _showManualInputDialog() {
    _showSnackbar(
      'Tapped Add Transaction (+): Implement manual input logic here.',
    );
  }

  Widget _buildRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value),
      ],
    ),
  );

  String formatCurrency(double amount) =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(amount);

  // ⭐️ Single transaction tile
  Widget _buildTransactionTile(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Safely cast date
    final dateTimestamp = data['date'];
    final date = (dateTimestamp is Timestamp)
        ? dateTimestamp.toDate()
        : DateTime.now();

    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final description = data['description'] ?? 'N/A';
    final category = data['category'] ?? 'Other';

    return Card(
      color: _cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.receipt, color: _secondaryColor),
        title: Text(description),
        subtitle: Text('$category - ${DateFormat('hh:mm a').format(date)}'),
        trailing: Text(
          formatCurrency(amount),
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
        color: _cardColor, // Ensure visibility against the gradient
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not logged in.')));
    }

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
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: _cardColor),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'No transactions found for $_selectedFilter.',
                  style: const TextStyle(color: _cardColor),
                ),
              );
            }

            final transactions = snapshot.data!.docs;
            final aggData = _aggregateTransactions(
              transactions,
              _selectedFilter,
              dateRange,
            );
            final spots = aggData.values
                .toList()
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value))
                .toList();

            final groupedTransactions = _groupTransactionsByDate(transactions);

            final List<Widget> datedTransactionList = [];
            final sortedDateKeys = groupedTransactions.keys.toList()
              ..sort(
                (a, b) => DateFormat(
                  'EEEE, d MMMM yyyy',
                ).parse(b).compareTo(DateFormat('EEEE, d MMMM yyyy').parse(a)),
              ); // Sort descending

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
                          gridData: FlGridData(
                            show: true,
                            drawHorizontalLine: true,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: _cardColor.withOpacity(0.2),
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              axisNameWidget: Text(
                                _selectedFilter,
                                style: const TextStyle(color: _cardColor),
                              ),
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: 1,
                                getTitlesWidget:
                                    (double value, TitleMeta meta) {
                                      final idx = value.toInt();
                                      if (idx >= 0 &&
                                          idx < aggData.keys.length) {
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          space: 8.0,
                                          child: Text(
                                            aggData.keys.elementAt(idx),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: _cardColor,
                                            ),
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
                                reservedSize: 40,
                                getTitlesWidget: (double v, TitleMeta meta) {
                                  if (v == 0) return const SizedBox();
                                  return Text(
                                    '₹${(v / 1000).toStringAsFixed(0)}k',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: _cardColor,
                                    ),
                                    textAlign: TextAlign.left,
                                  );
                                },
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
                          minY: 0,
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
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    _secondaryColor.withOpacity(0.5),
                                    _secondaryColor.withOpacity(0.0),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
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
  static const Color _cardColor = Color(0xFFFFFFFF);

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
    // Explicitly stop listening and dispose controller
    widget.voiceService.stopListening();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    // Prevent starting if already listening
    if (_isListening) return;

    setState(() {
      _isListening = true;
      _statusText = 'Listening... Speak now.';
    });
    _controller.repeat(reverse: true);

    final result = await widget.voiceService.startListening();

    _controller.stop();
    if (mounted) {
      // Update state before popping to ensure UI consistency
      setState(() {
        _isListening = false;
        _statusText = 'Tap mic to start';
      });

      // Pop the dialog after processing is complete
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
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Creates a pulsating effect while listening
                final scale = _isListening
                    ? 1.0 +
                          (_controller.value * 0.2) // Scales from 1.0 to 1.2
                    : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? Colors.red.shade600 : _primaryColor,
                      boxShadow: _isListening
                          ? [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.6),
                                blurRadius: 15,
                                spreadRadius: 3,
                              ),
                            ]
                          : [],
                    ),
                    child: const Icon(Icons.mic, color: _cardColor, size: 45),
                  ),
                );
              },
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
