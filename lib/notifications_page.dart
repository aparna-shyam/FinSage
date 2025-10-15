import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'recurring_payments.dart'; // Import to use RecurringPayment model

// Define the consistent primary color and the gradient colors
const Color _primaryColor = Color(0xFF008080); // Deep Teal
const Color _roseGold = Color(0xFFB76E79); // Secondary: Rose Gold
const Color _gradientStart = Color(0xFF2C3E50); // Dark Blue-Purple
const Color _gradientEnd = Color(0xFF4CA1AF); // Lighter Blue-Teal
const Color _cardBoxColor = Color(0xFFFFFFFF); // Pure White

// ⭐️ MODIFIED: Removed the redundant 'isRead' field from the model ⭐️
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime notificationDate;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.notificationDate,
  });
}

class NotificationsPage extends StatefulWidget {
  final List<RecurringPayment> recurringPayments;

  const NotificationsPage({super.key, required this.recurringPayments});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Now only stores the items themselves, read status is managed by the Set
  late List<NotificationItem> _generatedNotifications;

  // Set to track which reminders have been dismissed *in the current session*.
  final Set<String> _dismissedNotificationIds = <String>{};

  @override
  void initState() {
    super.initState();
    // Generate the initial list of notifications
    _generatedNotifications = _generateMockNotifications(
      widget.recurringPayments,
    );
  }

  // ⭐️ GENERATION FUNCTION: Creates mock notifications based on payment data ⭐️
  List<NotificationItem> _generateMockNotifications(
    List<RecurringPayment> payments,
  ) {
    List<NotificationItem> generated = [];
    final now = DateTime.now();
    // Normalize 'now' to today midnight for consistent date comparisons
    final DateTime today = DateTime(now.year, now.month, now.day);

    for (var payment in payments) {
      if (!payment.isActive) continue;

      // 1. Calculate the theoretical notification date
      final DateTime notificationTime = payment.firstDueDate.subtract(
        Duration(days: payment.notifyDaysBefore),
      );

      // Use a unique ID combining payment ID and the due date
      final String uniqueNotificationId =
          '${payment.id}_${DateFormat('yyyyMMdd').format(payment.firstDueDate)}';

      // ⭐️ ALARM CLOCK LOGIC: Only generate a notification if its notification time
      // is within the last 7 days AND the payment is not DUE YET (or is due today). ⭐️
      if (notificationTime.isAfter(today.subtract(const Duration(days: 7))) &&
          payment.firstDueDate.isAfter(
            today.subtract(const Duration(days: 1)),
          )) {
        // 2. Generate the message body
        String notificationBody = '';
        if (payment.notifyDaysBefore == 0) {
          notificationBody =
              'Your ${payment.name} payment of ₹${payment.amount.toStringAsFixed(2)} is due TODAY!';
        } else {
          notificationBody =
              'Your ${payment.name} payment of ₹${payment.amount.toStringAsFixed(2)} is due in ${payment.notifyDaysBefore} days (${DateFormat('MMM dd, yyyy').format(payment.firstDueDate)}).';
        }

        generated.add(
          NotificationItem(
            id: uniqueNotificationId, // Use the unique ID
            title: 'Bill Reminder: ${payment.name}',
            body: notificationBody,
            // Use notificationTime as the "received" time
            notificationDate: notificationTime.isBefore(now)
                ? notificationTime
                : now.subtract(const Duration(minutes: 5)),
          ),
        );
      }
    }

    // Add dummy notifications (using static IDs)
    const String dummyId1 = 'dummy_payment_alert';
    const String dummyId2 = 'dummy_app_update';

    generated.add(
      NotificationItem(
        id: dummyId1,
        title: 'Payment System Alert',
        body: 'Your last electricity bill payment was successfully recorded.',
        notificationDate: now.subtract(const Duration(days: 5)),
      ),
    );
    generated.add(
      NotificationItem(
        id: dummyId2,
        title: 'App Update',
        body: 'Welcome! You successfully set up recurring payments tracking.',
        notificationDate: now.subtract(const Duration(days: 30)),
      ),
    );

    // Sort to show unread/most recent first
    generated.sort((a, b) => b.notificationDate.compareTo(a.notificationDate));

    return generated;
  }

  // ⭐️ MARK AS READ FUNCTION (Temporarily dismisses for current session) ⭐️
  void _markAsRead(String id) {
    setState(() {
      _dismissedNotificationIds.add(id);
      // We don't need to re-generate the list here, as the build method will check
      // the dismissed set against the existing _generatedNotifications.
      // However, re-generating ensures the list order is checked against new state.
      _generatedNotifications = _generateMockNotifications(
        widget.recurringPayments,
      );
    });
  }

  // ⭐️ MARK ALL AS READ FUNCTION ⭐️
  void _markAllAsRead() {
    setState(() {
      for (var notification in _generatedNotifications) {
        _dismissedNotificationIds.add(notification.id);
      }
      // Re-generate to refresh UI based on new dismissed set
      _generatedNotifications = _generateMockNotifications(
        widget.recurringPayments,
      );
    });
  }

  Widget _buildNotificationTile(NotificationItem notification) {
    // ⭐️ FIX: Check the state set directly for dismissal status ⭐️
    final bool isDismissed = _dismissedNotificationIds.contains(
      notification.id,
    );

    return Card(
      color: _cardBoxColor,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: Icon(
          Icons.notifications_active,
          color: isDismissed ? Colors.grey : _primaryColor,
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: isDismissed ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 4),
            Text(
              DateFormat(
                'dd MMM yyyy - hh:mm a',
              ).format(notification.notificationDate),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: isDismissed
            ? null
            : const Icon(
                Icons.circle,
                color: _roseGold,
                size: 10,
              ), // Use Rose Gold for unread indicator
        // ⭐️ ON TAP: Marks the notification as dismissed for the session ⭐️
        onTap: () {
          if (!isDismissed) {
            _markAsRead(notification.id);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use the re-generated list
    final List<NotificationItem> currentNotifications = _generatedNotifications;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read, color: Colors.white),
            onPressed: _markAllAsRead, // Use the new mark all function
            tooltip: 'Mark all as read',
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
        child: currentNotifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_off,
                      size: 80,
                      color: Colors.white54,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.recurringPayments.isEmpty
                          ? 'Add a recurring payment to start getting reminders.'
                          : 'No recent payment reminders or notifications.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: currentNotifications.length,
                itemBuilder: (context, index) {
                  return _buildNotificationTile(currentNotifications[index]);
                },
              ),
      ),
    );
  }
}
