import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

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
      await FirebaseFirestore.instance.collection('goals').add({
        'userId': currentUser.uid,
        'goal': _goalController.text,
        'targetAmount': double.tryParse(_amountController.text) ?? 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _goalController.clear();
      _amountController.clear();
    } catch (e) {
      debugPrint('Error adding goal: $e');
    }
  }

  void _showAddGoalDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _goalController,
                decoration: const InputDecoration(
                  labelText: 'Goal Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Amount',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        backgroundColor: const Color(0xFF6B5B95),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('goals')
              .where('userId', isEqualTo: currentUser.uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No goals added yet.'));
            }

            final goals = snapshot.data!.docs;

            return ListView.builder(
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goalData = goals[index].data() as Map<String, dynamic>;
                final goalName = goalData['goal'] ?? 'Unnamed Goal';
                final targetAmount =
                    (goalData['targetAmount'] as num?)?.toDouble() ?? 0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(goalName),
                    subtitle: Text('Target: ₹$targetAmount'),
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
