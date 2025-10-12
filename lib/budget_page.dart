import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Import your voice input files
import '../services/voice_input_service.dart';
import '../utils/voice_command_parser.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  User? get user => FirebaseAuth.instance.currentUser;

  final Map<String, double> _categoryBudgets = {};
  final Map<String, double> _categorySpent = {};

  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  // Predefined categories for dropdown
  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Bills',
    'Groceries',
    'Health',
    'Education',
    'Other',
  ];

  String? _selectedCategory;

  @override
  void dispose() {
    _categoryController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _fetchBudgets() async {
    final currentUser = user;
    if (currentUser == null) return;

    // Fetch budgets from Firestore
    final budgetSnapshot = await FirebaseFirestore.instance
        .collection('budgets')
        .where('userId', isEqualTo: currentUser.uid)
        .get();

    final spendingSnapshot = await FirebaseFirestore.instance
        .collection('spending')
        .where('userId', isEqualTo: currentUser.uid)
        .get();

    setState(() {
      _categoryBudgets.clear();
      _categorySpent.clear();

      for (var doc in budgetSnapshot.docs) {
        final data = doc.data();
        _categoryBudgets[data['category']] =
            (data['budget'] as num?)?.toDouble() ?? 0.0;
      }

      for (var doc in spendingSnapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String? ?? 'Others';
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        _categorySpent[category] = (_categorySpent[category] ?? 0) + amount;
      }
    });
  }

  Future<void> _addBudget() async {
    final currentUser = user;
    if (currentUser == null) return;
    
    final category = _selectedCategory ?? _categoryController.text.trim();
    final amount = double.tryParse(_budgetController.text.trim()) ?? 0.0;

    if (category.isEmpty || amount <= 0) return;

    // Check if budget already exists for this category
    final existingBudget = await FirebaseFirestore.instance
        .collection('budgets')
        .where('userId', isEqualTo: currentUser.uid)
        .where('category', isEqualTo: category)
        .get();

    if (existingBudget.docs.isNotEmpty) {
      // Update existing budget
      await FirebaseFirestore.instance
          .collection('budgets')
          .doc(existingBudget.docs.first.id)
          .update({'budget': amount});
    } else {
      // Add new budget
      await FirebaseFirestore.instance.collection('budgets').add({
        'userId': currentUser.uid,
        'category': category,
        'budget': amount,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    _categoryController.clear();
    _budgetController.clear();
    _selectedCategory = null;

    _fetchBudgets();
    Navigator.pop(context);
  }

  void _showAddBudgetDialog() {
    _categoryController.clear();
    _budgetController.clear();
    _selectedCategory = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Budget'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category.toLowerCase(),
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Budget Amount',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee),
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
                  onPressed: _addBudget,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B5B95),
                  ),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Voice input budget method
  void _showVoiceInputDialog() {
    final voiceService = VoiceInputService();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VoiceInputDialog(
        voiceService: voiceService,
        title: 'Set Budget by Voice',
        hint: 'Say: "Set budget 5000 for food"',
        onResult: (text) async {
          final data = VoiceCommandParser.parseBudget(text);
          if (data != null && data.amount != null) {
            await _showConfirmBudgetDialog(data, text);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not understand. Try: "Budget 5000 for food"'),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        },
      ),
    );
  }

  // Confirm and save budget
  Future<void> _showConfirmBudgetDialog(
    BudgetData data,
    String originalText,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You said: "$originalText"'),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildConfirmRow('Category:', data.category ?? 'other'),
            _buildConfirmRow('Budget Amount:', '₹${data.amount}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B5B95),
            ),
            child: const Text('Save Budget'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final category = data.category ?? 'other';
        
        // Check if budget already exists
        final existingBudget = await FirebaseFirestore.instance
            .collection('budgets')
            .where('userId', isEqualTo: user.uid)
            .where('category', isEqualTo: category)
            .get();

        if (existingBudget.docs.isNotEmpty) {
          // Update existing
          await FirebaseFirestore.instance
              .collection('budgets')
              .doc(existingBudget.docs.first.id)
              .update({'budget': data.amount});
        } else {
          // Add new
          await FirebaseFirestore.instance.collection('budgets').add({
            'userId': user.uid,
            'category': category,
            'budget': data.amount,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        await _fetchBudgets();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Budget saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving budget: $e')),
          );
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
          Text(value),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchBudgets();
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(amount);
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'bills':
        return Icons.receipt_long;
      case 'groceries':
        return Icons.local_grocery_store;
      case 'health':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text('Please log in to view your budget.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Budget'),
        backgroundColor: const Color(0xFF6B5B95),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _categoryBudgets.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No budgets set yet.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add a budget or 🎤 for voice input',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              )
            : ListView(
                children: _categoryBudgets.keys.map((category) {
                  final budget = _categoryBudgets[category] ?? 0.0;
                  final spent = _categorySpent[category] ?? 0.0;
                  final progress = spent / budget;

                  Color progressColor;
                  String statusText;
                  if (progress < 0.7) {
                    progressColor = Colors.green;
                    statusText = 'On Track';
                  } else if (progress < 1) {
                    progressColor = Colors.orange;
                    statusText = 'Warning';
                  } else {
                    progressColor = Colors.red;
                    statusText = 'Over Budget';
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6B5B95).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getCategoryIcon(category),
                                  color: const Color(0xFF6B5B95),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      statusText,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: progressColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: progressColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${(progress * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: progressColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress > 1 ? 1 : progress,
                              color: progressColor,
                              backgroundColor: Colors.grey[300],
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Spent',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(spent),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Budget',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(budget),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6B5B95),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (progress < 1) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Remaining: ${_formatCurrency(budget - spent)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            Text(
                              'Exceeded by: ${_formatCurrency(spent - budget)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'voice_budget',
            onPressed: _showVoiceInputDialog,
            backgroundColor: const Color(0xFF8B7BA8),
            child: const Icon(Icons.mic, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'add_budget',
            onPressed: _showAddBudgetDialog,
            backgroundColor: const Color(0xFF6B5B95),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
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
          const SnackBar(content: Text('No speech detected. Please try again.')),
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
                color: _isListening ? Colors.red : const Color(0xFF6B5B95),
                boxShadow: _isListening
                    ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ]
                    : [],
              ),
              child: _isListening
                  ? RotationTransition(
                      turns: _animationController,
                      child: const Icon(Icons.mic, color: Colors.white, size: 50),
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