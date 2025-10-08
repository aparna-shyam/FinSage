import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Import your voice input files
import '../services/voice_input_service.dart';
import '../utils/voice_command_parser.dart';

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
      // ✅ Save inside user’s subcollection for consistent querying
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('goals')
          .add({
        'goal': _goalController.text,
        'targetAmount': double.tryParse(_amountController.text) ?? 0,
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
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
                        await _pickDate();
                        setDialogState(() {});
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
                            color:
                                _selectedDate == null ? Colors.grey : Colors.black,
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
                  content:
                      Text('Could not understand. Try: "Save 50000 for vacation"'),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B5B95),
            ),
            child: const Text('Save Goal'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // ✅ Store voice goal inside user’s subcollection
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('goals')
            .add({
          'goal': data.name ?? 'Savings Goal',
          'targetAmount': data.targetAmount,
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving goal: $e')),
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
        title: const Text('My Goals'),
        backgroundColor: const Color(0xFF6B5B95),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'voice_goal',
            onPressed: _showVoiceInputDialog,
            backgroundColor: const Color(0xFF8B7BA8),
            child: const Icon(Icons.mic, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'add_goal',
            onPressed: _showAddGoalDialog,
            backgroundColor: const Color(0xFF6B5B95),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // ✅ Stream now reads from the same user subcollection
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('goals')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No goals added yet.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add a goal or 🎤 for voice input',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
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
                final goalName = goalData['goal'] ?? 'Unnamed Goal';
                final targetAmount =
                    (goalData['targetAmount'] as num?)?.toDouble() ?? 0;
                final targetDate = goalData['targetDate'] != null
                    ? (goalData['targetDate'] as Timestamp).toDate()
                    : null;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B5B95).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.flag,
                        color: Color(0xFF6B5B95),
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
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.currency_rupee,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Target: ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(targetAmount)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (targetDate != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'By ${DateFormat('d MMM y').format(targetDate)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Goal'),
                            content:
                                Text('Are you sure you want to delete "$goalName"?'),
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
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(currentUser.uid)
                              .collection('goals')
                              .doc(goals[index].id)
                              .delete();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Goal deleted'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// Voice Input Dialog Widget (unchanged)
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
    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
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
