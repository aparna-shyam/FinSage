// lib/recurring_payments_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ⭐️ NEW IMPORT: Import the NotificationsPage ⭐️
import 'notifications_page.dart';

// Define new colors based on the theme constants
const Color _deepTeal = Color(0xFF008080); // Primary: Deep Teal
const Color _roseGold = Color(0xFFB76E79); // Secondary: Rose Gold
const Color _gradientStart = Color(0xFF2C3E50); // Dark Blue-Purple
const Color _gradientEnd = Color(0xFF4CA1AF); // Lighter Blue-Teal
const Color _cardBoxColor = Color(0xFFFFFFFF); // Pure White
const Color _backgroundColor = Color(
  0xFFF5F7FA,
); // Soft Light Grey background for fixed pages

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
      'createdAt':
          FieldValue.serverTimestamp(), // NOTE: Only for initial save, not for update
    };
  }

  // Convert to a map for Firestore UPDATE
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'amount': amount,
      'frequency': frequency,
      'firstDueDate': Timestamp.fromDate(firstDueDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'dueDetail': dueDetail,
      'isActive': isActive,
      'notes': notes,
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

  // ⭐️ NEW: Update function ⭐️
  Future<void> _updatePayment(RecurringPayment payment) async {
    if (currentUser == null) return;
    try {
      await _paymentsCollection.doc(payment.id).update(payment.toUpdateMap());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating payment: $e')));
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
  // DIALOG FUNCTION - ADD
  // ---------------------------------------------------------------------------
  void _showAddRecurringPaymentDialog() {
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

    _showPaymentDialog(
      paymentToEdit: null,
      selectedFrequency: selectedFrequency,
      dueDate: dueDate,
      endDate: endDate,
      selectedDayOfMonth: selectedDayOfMonth,
      selectedDayOfWeek: selectedDayOfWeek,
      isActive: isActive,
      nameController: nameController,
      amountController: amountController,
      notesController: notesController,
      dialogTitle: 'Add Recurring Payment',
      saveFunction: _savePayment,
    );
  }

  // ---------------------------------------------------------------------------
  // DIALOG FUNCTION - EDIT (Calls the unified dialog)
  // ---------------------------------------------------------------------------
  void _showEditRecurringPaymentDialog(RecurringPayment payment) {
    // Initial values taken from the existing payment
    String? selectedFrequency = payment.frequency;
    DateTime dueDate = payment.firstDueDate;
    DateTime? endDate = payment.endDate;
    bool isActive = payment.isActive;

    // Controllers for text fields
    final nameController = TextEditingController(text: payment.name);
    final amountController = TextEditingController(
      text: payment.amount.toString(),
    );
    final notesController = TextEditingController(text: payment.notes ?? '');

    // Determine due detail for initial state
    int selectedDayOfMonth = 1;
    String selectedDayOfWeek = 'Monday';

    if (payment.frequency == 'Monthly' ||
        payment.frequency == 'Quarterly' ||
        payment.frequency == 'Annually') {
      selectedDayOfMonth =
          int.tryParse(payment.dueDetail) ?? dueDate.day.clamp(1, 28);
    } else if (payment.frequency == 'Weekly' ||
        payment.frequency == 'Bi-Weekly') {
      selectedDayOfWeek = payment.dueDetail;
    }

    _showPaymentDialog(
      paymentToEdit: payment,
      selectedFrequency: selectedFrequency,
      dueDate: dueDate,
      endDate: endDate,
      selectedDayOfMonth: selectedDayOfMonth,
      selectedDayOfWeek: selectedDayOfWeek,
      isActive: isActive,
      nameController: nameController,
      amountController: amountController,
      notesController: notesController,
      dialogTitle: 'Edit Recurring Payment',
      saveFunction: _updatePayment,
    );
  }

  // ---------------------------------------------------------------------------
  // UNIFIED DIALOG BUILDER
  // ---------------------------------------------------------------------------
  void _showPaymentDialog({
    RecurringPayment? paymentToEdit,
    required String? selectedFrequency,
    required DateTime dueDate,
    required DateTime? endDate,
    required int selectedDayOfMonth,
    required String selectedDayOfWeek,
    required bool isActive,
    required TextEditingController nameController,
    required TextEditingController amountController,
    required TextEditingController notesController,
    required String dialogTitle,
    required Future<void> Function(RecurringPayment) saveFunction,
  }) {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in. Cannot save payment.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            // --- Helper Functions in Dialog Scope ---

            Future<void> _selectDate(bool isDueDate) async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: isDueDate
                    ? dueDate
                    : (endDate ??
                          DateTime.now().add(const Duration(days: 365))),
                firstDate: DateTime.now().subtract(
                  const Duration(days: 365 * 5),
                ), // Allow past dates for edit
                lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: _deepTeal, // Use primary color (Deep Teal)
                        onPrimary: Colors.white,
                        onSurface: Colors.black,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: _deepTeal, // Use primary color
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

            // --- Dialog Content ---

            return AlertDialog(
              title: Text(dialogTitle),
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
                          // Reset day detail based on new frequency
                          if (newValue == 'Monthly' ||
                              newValue == 'Quarterly' ||
                              newValue == 'Annually') {
                            selectedDayOfMonth = dueDate.day.clamp(1, 28);
                          } else if (newValue == 'Weekly' ||
                              newValue == 'Bi-Weekly') {
                            selectedDayOfWeek = DateFormat(
                              'EEEE',
                            ).format(dueDate);
                          }
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
                        color: _deepTeal, // Use primary color
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
                              color: _deepTeal, // Use primary color
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
                      activeColor: _deepTeal, // Use primary color
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
                      id:
                          paymentToEdit?.id ??
                          'temp', // Use existing ID or 'temp'
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
                    await saveFunction(
                      newPayment,
                    ); // Use the provided save/update function

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✅ Recurring payment "${newPayment.name}" ${paymentToEdit == null ? 'saved' : 'updated'}!',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _deepTeal, // Use primary color
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
  // DISPLAY WIDGET (Wrapped in Dismissible and GestureDetector)
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
      padding: const EdgeInsets.symmetric(
        vertical: 4,
        horizontal: 8,
      ), // Added horizontal padding for spacing from gradient
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
        // ⭐️ WRAP IN GESTURE DETECTOR FOR DOUBLE TAP ⭐️
        child: GestureDetector(
          onDoubleTap: () => _showEditRecurringPaymentDialog(payment),
          child: Card(
            color: _cardBoxColor, // Ensure card color is explicitly white
            margin: EdgeInsets
                .zero, // Card needs margin of zero here since parent Padding handles it
            elevation: 2,
            child: ListTile(
              leading: Icon(
                Icons.calendar_month,
                color: payment.isActive
                    ? _deepTeal
                    : Colors.grey, // Use primary color
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
                      color: _deepTeal, // Use primary color
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
              // Removed onTap to prevent conflict, now using onDoubleTap
              onTap: null,
            ),
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
      backgroundColor:
          Colors.transparent, // Set Scaffold background to transparent
      appBar: AppBar(
        title: const Text('Current Payments'),
        backgroundColor: _deepTeal, // Use primary color
        foregroundColor: Colors.white,
        // 🔔 The bell icon is already correctly placed in the actions list 🔔
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              // Navigate to NotificationsPage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsPage(),
                ),
              );
            },
          ),
        ],
      ),
      // 🎯 Use StreamBuilder to load data from Firestore
      body: Container(
        // ⭐️ GRADIENT IMPLEMENTATION START ⭐️
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_gradientStart, _gradientEnd],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _paymentsCollection
              .where('userId', isEqualTo: currentUser!.uid)
              .orderBy('firstDueDate', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _roseGold),
              );
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
                    const Icon(
                      Icons.autorenew,
                      size: 80,
                      color: _roseGold, // Used secondary color for contrast
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No subscriptions or bills found.', // Title redundancy removed
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    const Text(
                      'Tap the + button to add a new recurring payment.',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
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
      ), // ⭐️ GRADIENT IMPLEMENTATION END ⭐️
      // Floating action button for adding recurring payments
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecurringPaymentDialog,
        backgroundColor: _roseGold, // Use secondary color (Rose Gold)
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
