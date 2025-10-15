import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Import your voice input files
import '../services/voice_input_service.dart';
import '../utils/voice_command_parser.dart';

// Updated color constants to match dashboard_page.dart
const Color _primaryColor = Color(0xFF008080); // Deep Teal
const Color _secondaryColor = Color(0xFFB76E79); // Rose Gold
const Color _gradientStartColor = Color(0xFF2C3E50); // Dark Blue-Purple
const Color _gradientEndColor = Color(0xFF4CA1AF); // Lighter Blue-Teal
const Color _cardColor = Color(0xFFFFFFFF); // Pure White

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime? _selectedDate;

  User? get user => FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _goalController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _addGoal() async {
    if (_goalController.text.isEmpty || _amountController.text.isEmpty) return;

    final currentUser = user;
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('goals')
          .add({
            'goal': _goalController.text,
            'targetAmount': double.tryParse(_amountController.text) ?? 0,
            'currentAmount': 0.0,
            'targetDate': _selectedDate,
            'createdAt': FieldValue.serverTimestamp(),
          });

      _goalController.clear();
      _amountController.clear();
      _selectedDate = null;
    } catch (e) {
      debugPrint('Error adding goal: $e');
    }
  }

  Future<void> _updateGoal(
    String goalId,
    String newGoalName,
    double newTargetAmount,
    DateTime? newTargetDate,
  ) async {
    final currentUser = user;
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('goals')
          .doc(goalId)
          .update({
            'goal': newGoalName,
            'targetAmount': newTargetAmount,
            'targetDate': newTargetDate,
            'lastUpdated': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Goal updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating goal: $e')));
      }
    }
  }

  Future<void> _addSavings(
    String goalId,
    String goalName,
    double currentAmount,
    double targetAmount,
  ) async {
    final TextEditingController savingsController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Savings to "$goalName"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current: ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(currentAmount)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Text(
              'Target: ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(targetAmount)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: savingsController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Amount to Add',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.add_circle_outline),
                prefixText: '₹ ',
              ),
            ),
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
            child: const Text(
              'Add Savings',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && savingsController.text.isNotEmpty) {
      final amount = double.tryParse(savingsController.text) ?? 0;
      if (amount > 0) {
        await _updateGoalSavings(goalId, currentAmount + amount);
      }
    }
    savingsController.dispose();
  }

  Future<void> _updateGoalSavings(String goalId, double newAmount) async {
    final currentUser = user;
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('goals')
          .doc(goalId)
          .update({
            'currentAmount': newAmount,
            'lastUpdated': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Savings added successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating savings: $e')));
      }
    }
  }

  Future<void> _viewSavingsHistory(String goalId, String goalName) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Savings History: $goalName'),
        content: const Text('Savings history feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<DateTime?> _pickDate(DateTime? initialDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _primaryColor),
            ),
          ),
          child: child!,
        );
      },
    );
    return picked;
  }

  void _showAddGoalDialog() {
    _goalController.clear();
    _amountController.clear();
    _selectedDate = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Goal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _goalController,
                      decoration: const InputDecoration(
                        labelText: 'Goal Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Target Amount',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final picked = await _pickDate(_selectedDate);
                        setDialogState(() {
                          _selectedDate = picked;
                        });
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Target Date (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _selectedDate == null
                              ? 'Select Date'
                              : DateFormat('d MMM y').format(_selectedDate!),
                          style: TextStyle(
                            color: _selectedDate == null
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _addGoal();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditGoalDialog(
    String goalId,
    String currentGoal,
    double currentAmount,
    DateTime? currentTargetDate,
  ) async {
    // Local controllers. No need to dispose them explicitly here.
    final TextEditingController editGoalController = TextEditingController(
      text: currentGoal,
    );
    final TextEditingController editAmountController = TextEditingController(
      text: currentAmount.toStringAsFixed(0),
    );
    DateTime? tempSelectedDate = currentTargetDate;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit Goal: $currentGoal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: editGoalController,
                      decoration: const InputDecoration(
                        labelText: 'Goal Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: editAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Target Amount',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final picked = await _pickDate(tempSelectedDate);
                        setDialogState(() {
                          tempSelectedDate = picked;
                        });
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Target Date (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          tempSelectedDate == null
                              ? 'Select Date'
                              : DateFormat('d MMM y').format(tempSelectedDate!),
                          style: TextStyle(
                            color: tempSelectedDate == null
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newGoal = editGoalController.text.trim();
                    final newAmount =
                        double.tryParse(editAmountController.text.trim()) ?? 0;

                    if (newGoal.isNotEmpty && newAmount > 0) {
                      _updateGoal(goalId, newGoal, newAmount, tempSelectedDate);
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showVoiceInputDialog() {
    final voiceService = VoiceInputService();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VoiceInputDialog(
        voiceService: voiceService,
        title: 'Add Goal by Voice',
        hint: 'Say: "Save 50000 for vacation by December"',
        onResult: (text) async {
          final data = VoiceCommandParser.parseGoal(text);
          if (data != null && data.targetAmount != null) {
            await _showConfirmGoalDialog(data, text);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Could not understand. Try: "Save 50000 for vacation"',
                  ),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _showConfirmGoalDialog(
    GoalData data,
    String originalText,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You said: "$originalText"'),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildConfirmRow('Goal Name:', data.name ?? 'Savings Goal'),
            _buildConfirmRow('Target Amount:', '₹${data.targetAmount}'),
            if (data.targetDate != null)
              _buildConfirmRow(
                'Target Date:',
                DateFormat('d MMM y').format(data.targetDate!),
              ),
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
            child: const Text(
              'Save Goal',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('goals')
            .add({
              'goal': data.name ?? 'Savings Goal',
              'targetAmount': data.targetAmount,
              'currentAmount': 0.0,
              'targetDate': data.targetDate,
              'createdAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Goal saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving goal: $e')));
        }
      }
    }
  }

  Widget _buildConfirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = user;
    if (currentUser == null) {
      return const Center(child: Text('Please log in to see your goals.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Goals', style: TextStyle(color: Colors.white)),
        backgroundColor: _primaryColor,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'voice_goal',
            onPressed: _showVoiceInputDialog,
            backgroundColor: _secondaryColor, // Rose Gold (Step 1)
            child: const Icon(Icons.mic, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'add_goal',
            onPressed: _showAddGoalDialog,
            backgroundColor: _secondaryColor, // Rose Gold (Step 1)
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradientStartColor, _gradientEndColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .collection('goals')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 80,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No goals added yet.',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add a goal or 🎤 for voice input',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final goals = snapshot.data!.docs;

              return ListView.builder(
                itemCount: goals.length,
                itemBuilder: (context, index) {
                  final goalData = goals[index].data() as Map<String, dynamic>;
                  final goalId = goals[index].id;
                  final goalName = goalData['goal'] ?? 'Unnamed Goal';
                  final targetAmount =
                      (goalData['targetAmount'] as num?)?.toDouble() ?? 0;
                  final currentAmount =
                      (goalData['currentAmount'] as num?)?.toDouble() ?? 0;
                  final targetDate = goalData['targetDate'] != null
                      ? (goalData['targetDate'] as Timestamp).toDate()
                      : null;

                  final progress = targetAmount > 0
                      ? currentAmount / targetAmount
                      : 0.0;
                  final remainingAmount = targetAmount - currentAmount;
                  final isCompleted = currentAmount >= targetAmount;

                  return Dismissible(
                    // Swipe-to-Delete (Step 2)
                    key: Key(goalId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      color: Colors.red,
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Goal'),
                          content: Text(
                            'Are you sure you want to delete "$goalName"?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser.uid)
                          .collection('goals')
                          .doc(goalId)
                          .delete();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Goal deleted'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: GestureDetector(
                      // Double-Tap-to-Edit (Step 3)
                      onDoubleTap: () => _showEditGoalDialog(
                        goalId,
                        goalName,
                        targetAmount,
                        targetDate,
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: _cardColor,
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? Colors.green.withOpacity(0.1)
                                      : _primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isCompleted ? Icons.check_circle : Icons.flag,
                                  color: isCompleted
                                      ? Colors.green
                                      : _primaryColor,
                                  size: 28,
                                ),
                              ),
                              title: Text(
                                goalName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: progress > 1 ? 1 : progress,
                                      backgroundColor: Colors.grey[300],
                                      color: isCompleted
                                          ? Colors.green
                                          : _primaryColor,
                                      minHeight: 8,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Saved',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          Text(
                                            NumberFormat.currency(
                                              locale: 'en_IN',
                                              symbol: '₹',
                                            ).format(currentAmount),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${(progress * 100).toStringAsFixed(0)}%',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isCompleted
                                                  ? Colors.green
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Target',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          Text(
                                            NumberFormat.currency(
                                              locale: 'en_IN',
                                              symbol: '₹',
                                            ).format(targetAmount),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: _primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (!isCompleted) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Remaining: ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(remainingAmount)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 6),
                                    const Text(
                                      '🎉 Goal Achieved!',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  if (targetDate != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: _primaryColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Target: ${DateFormat('d MMM y').format(targetDate)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: _primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) async {
                                  if (value == 'delete') {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Goal'),
                                        content: Text(
                                          'Are you sure you want to delete "$goalName"?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              Navigator.pop(context, true);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(currentUser.uid)
                                          .collection('goals')
                                          .doc(goalId)
                                          .delete();

                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Goal deleted'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete Goal'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isCompleted)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _addSavings(
                                      goalId,
                                      goalName,
                                      currentAmount,
                                      targetAmount,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'Add Savings',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// Voice Input Dialog Widget
class VoiceInputDialog extends StatefulWidget {
  final VoiceInputService voiceService;
  final Function(String) onResult;
  final String title;
  final String hint;

  const VoiceInputDialog({
    super.key,
    required this.voiceService,
    required this.onResult,
    required this.title,
    required this.hint,
  });

  @override
  State<VoiceInputDialog> createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends State<VoiceInputDialog>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  String _statusText = 'Tap microphone to start';
  late AnimationController _animationController;

  static const Color _primaryColor = Color(0xFF008080);
  static const Color _secondaryColor = Color(0xFFB76E79);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    widget.voiceService.stopListening();
    super.dispose();
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _statusText = 'Listening... Speak now';
    });
    _animationController.repeat();

    final result = await widget.voiceService.startListening();

    _animationController.stop();

    if (mounted) {
      Navigator.pop(context);
      if (result != null && result.isNotEmpty) {
        widget.onResult(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No speech detected. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
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
                color: _isListening ? Colors.red : _secondaryColor,
                boxShadow: _isListening
                    ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ]
                    : [],
              ),
              child: _isListening
                  ? RotationTransition(
                      turns: _animationController,
                      child: const Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 50,
                      ),
                    )
                  : const Icon(Icons.mic, color: Colors.white, size: 50),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _statusText,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          if (!_isListening)
            Text(
              widget.hint,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
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
