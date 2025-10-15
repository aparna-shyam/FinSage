// lib/recurring_payments_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// -----------------------------------------------------------------------------
// 1. DATA MODEL (Now maps to Firestore structure)
// -----------------------------------------------------------------------------
class RecurringPayment {
  final String id;
  final String name;
  final double amount;
  final String frequency;
  final DateTime firstDueDate;
  final DateTime? endDate;
  final String dueDetail;
  final bool isActive;
  final String? notes;

  RecurringPayment({
    required this.id,
    required this.name,
    required this.amount,
    required this.frequency,
    required this.firstDueDate,
    this.endDate,
    required this.dueDetail,
    this.isActive = true,
    this.notes,
  });

  // Factory constructor to create a RecurringPayment from a Firestore Document
  factory RecurringPayment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecurringPayment(
      id: doc.id,
      name: data['name'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      frequency: data['frequency'] ?? 'Monthly',
      firstDueDate: (data['firstDueDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      dueDetail: data['dueDetail'] ?? '',
      isActive: data['isActive'] ?? true,
      notes: data['notes'],
    );
  }

  // Convert to a map for Firestore storage
  Map<String, dynamic> toMap(String userId) {
    return {
      'userId': userId,
      'name': name,
      'amount': amount,
      'frequency': frequency,
      'firstDueDate': Timestamp.fromDate(firstDueDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'dueDetail': dueDetail,
      'isActive': isActive,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

// -----------------------------------------------------------------------------
// 2. MAIN PAGE WIDGET
// -----------------------------------------------------------------------------
class RecurringPaymentsPage extends StatefulWidget {
  const RecurringPaymentsPage({super.key});

  @override
  State<RecurringPaymentsPage> createState() => _RecurringPaymentsPageState();
}

class _RecurringPaymentsPageState extends State<RecurringPaymentsPage> {
  // Orange color defined in dashboard_page.dart
  static const Color _orangeColor = Color(0xFFD9641E);
  static const Color _lightBackgroundColor = Color(0xFFECE2D2);

  // Expanded list of frequency options
  final List<String> _frequencies = [
    'Daily',
    'Weekly',
    'Bi-Weekly',
    'Monthly',
    'Quarterly',
    'Annually',
  ];

  // List of days of the week for weekly selection
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(amount);
  }

  // ---------------------------------------------------------------------------
  // FIREBASE ACTIONS
  // ---------------------------------------------------------------------------
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final CollectionReference _paymentsCollection = FirebaseFirestore.instance
      .collection('recurring_payments');

  Future<void> _savePayment(RecurringPayment payment) async {
    if (currentUser == null) return;
    try {
      await _paymentsCollection.add(payment.toMap(currentUser!.uid));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving payment: $e')));
      }
    }
  }

  Future<void> _deletePaymentFromFirestore(String id) async {
    if (currentUser == null) return;
    try {
      await _paymentsCollection.doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Payment deleted from cloud!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting payment: $e')));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // DIALOG FUNCTION (Updated Save Logic)
  // ---------------------------------------------------------------------------
  void _showAddRecurringPaymentDialog() {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in. Cannot add payment.'),
        ),
      );
      return;
    }

    // Initial values for the dialog state
    String? selectedFrequency = 'Monthly';
    DateTime dueDate = DateTime.now();
    DateTime? endDate;
    int selectedDayOfMonth = dueDate.day.clamp(1, 28);
    String selectedDayOfWeek = DateFormat('EEEE').format(dueDate);
    bool isActive = true;

    // Controllers for text fields
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            // Date picker function remains the same
            Future<void> _selectDate(bool isDueDate) async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: isDueDate
                    ? dueDate
                    : (endDate ??
                          DateTime.now().add(const Duration(days: 365))),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: _orangeColor,
                        onPrimary: Colors.white,
                        onSurface: Colors.black,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: _orangeColor,
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null) {
                setStateInDialog(() {
                  if (isDueDate) {
                    dueDate = picked;
                    selectedDayOfMonth = picked.day.clamp(1, 28);
                  } else {
                    endDate = picked;
                  }
                });
              }
            }

            // Day selector widget remains the same
            Widget _buildDueDaySelector() {
              if (selectedFrequency == 'Monthly' ||
                  selectedFrequency == 'Quarterly' ||
                  selectedFrequency == 'Annually') {
                return DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Day of Month Due',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(),
                  ),
                  value: selectedDayOfMonth.clamp(1, 28),
                  items: List.generate(28, (i) => i + 1)
                      .map(
                        (day) => DropdownMenuItem<int>(
                          value: day,
                          child: Text(
                            '$day${(day > 10 && day < 20)
                                ? 'th'
                                : (day % 10 == 1)
                                ? 'st'
                                : (day % 10 == 2)
                                ? 'nd'
                                : (day % 10 == 3)
                                ? 'rd'
                                : 'th'}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setStateInDialog(() {
                        selectedDayOfMonth = newValue;
                      });
                    }
                  },
                );
              } else if (selectedFrequency == 'Weekly' ||
                  selectedFrequency == 'Bi-Weekly') {
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Day of Week Due',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(),
                  ),
                  value: selectedDayOfWeek,
                  items: _daysOfWeek.map((day) {
                    return DropdownMenuItem<String>(
                      value: day,
                      child: Text('Every $day'),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setStateInDialog(() {
                        selectedDayOfWeek = newValue;
                      });
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            }

            return AlertDialog(
              title: const Text('Add Recurring Payment'),
              contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              actionsPadding: const EdgeInsets.all(8),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Payment Name (e.g., Netflix, Rent)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Reminder Frequency',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(),
                      ),
                      value: selectedFrequency,
                      items: _frequencies.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setStateInDialog(() {
                          selectedFrequency = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildDueDaySelector(),
                    const SizedBox(height: 15),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('First Reminder Date'),
                      subtitle: Text(
                        DateFormat('dd MMMM yyyy').format(dueDate),
                      ),
                      trailing: const Icon(
                        Icons.calendar_today,
                        color: _orangeColor,
                      ),
                      onTap: () => _selectDate(true),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        endDate == null
                            ? 'Set End Date (Optional)'
                            : 'Stop Reminders After',
                      ),
                      subtitle: Text(
                        endDate == null
                            ? 'Continuous'
                            : DateFormat('dd MMMM yyyy').format(endDate!),
                      ),
                      trailing: endDate == null
                          ? const Icon(
                              Icons.add_circle_outline,
                              color: _orangeColor,
                            )
                          : IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () =>
                                  setStateInDialog(() => endDate = null),
                            ),
                      onTap: () => _selectDate(false),
                    ),
                    const Divider(),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes/Description',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 15),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Payment Status'),
                      subtitle: Text(isActive ? 'Active' : 'Paused'),
                      value: isActive,
                      onChanged: (bool value) {
                        setStateInDialog(() {
                          isActive = value;
                        });
                      },
                      activeColor: _orangeColor,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty ||
                        amountController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Name and Amount are required.'),
                        ),
                      );
                      return;
                    }

                    final newPayment = RecurringPayment(
                      id: 'temp', // ID will be assigned by Firestore
                      name: nameController.text,
                      amount: double.tryParse(amountController.text) ?? 0.0,
                      frequency: selectedFrequency!,
                      firstDueDate: dueDate,
                      endDate: endDate,
                      dueDetail:
                          (selectedFrequency == 'Monthly' ||
                              selectedFrequency == 'Quarterly' ||
                              selectedFrequency == 'Annually')
                          ? '$selectedDayOfMonth'
                          : selectedDayOfWeek,
                      isActive: isActive,
                      notes: notesController.text.isEmpty
                          ? null
                          : notesController.text,
                    );

                    Navigator.of(context).pop();
                    await _savePayment(newPayment); // Save to Firestore

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✅ Recurring payment "${newPayment.name}" saved!',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orangeColor,
                  ),
                  child: const Text(
                    'Save',
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

  // ---------------------------------------------------------------------------
  // DISPLAY WIDGET (Wrapped in Dismissible)
  // ---------------------------------------------------------------------------
  Widget _buildPaymentTile(RecurringPayment payment) {
    final statusColor = payment.isActive
        ? Colors.green.shade700
        : Colors.red.shade700;
    final statusText = payment.isActive ? 'Active' : 'Paused';
    final dueInfo =
        payment.frequency == 'Monthly' ||
            payment.frequency == 'Quarterly' ||
            payment.frequency == 'Annually'
        ? 'Due on day ${payment.dueDetail}'
        : 'Due every ${payment.dueDetail}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      // WRAP THE TILE IN DISMISSIBLE
      child: Dismissible(
        key: Key(payment.id),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Icon(Icons.delete, color: Colors.white, size: 32),
        ),
        // Action when the dismissal is confirmed
        onDismissed: (direction) {
          _deletePaymentFromFirestore(payment.id);
        },
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Confirm Delete'),
                content: Text(
                  'Are you sure you want to delete the payment for "${payment.name}"?',
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          );
        },
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          elevation: 2,
          child: ListTile(
            leading: Icon(
              Icons.calendar_month,
              color: payment.isActive ? _orangeColor : Colors.grey,
            ),
            title: Text(
              payment.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${payment.frequency} - $dueInfo'),
                Text(
                  'Next: ${DateFormat('dd MMM yyyy').format(payment.firstDueDate)}',
                ),
              ],
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(payment.amount),
                  style: TextStyle(
                    color: _orangeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Tapped on ${payment.name} for editing! (TODO: Implement Edit)',
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to manage recurring payments.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _lightBackgroundColor,
      appBar: AppBar(
        title: const Text('Recurring Payments'),
        backgroundColor: _orangeColor,
        // 🔔 ADDED NOTIFICATION BELL ICON 🔔
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications tapped on Recurring Payments'),
                ),
              );
            },
          ),
        ],
      ),
      // 🎯 Use StreamBuilder to load data from Firestore
      body: StreamBuilder<QuerySnapshot>(
        stream: _paymentsCollection
            .where('userId', isEqualTo: currentUser!.uid)
            .orderBy('firstDueDate', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading payments: ${snapshot.error}'),
            );
          }

          final payments = snapshot.data!.docs
              .map((doc) => RecurringPayment.fromFirestore(doc))
              .toList();

          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.autorenew, size: 80, color: _orangeColor),
                  const SizedBox(height: 16),
                  const Text(
                    'No recurring payments set up yet.',
                    style: TextStyle(fontSize: 18),
                  ),
                  const Text(
                    'Tap the + button to add a new subscription or bill.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Display the list of payments
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              return _buildPaymentTile(payments[index]);
            },
          );
        },
      ),

      // Floating action button for adding recurring payments
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecurringPaymentDialog,
        backgroundColor: _orangeColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
