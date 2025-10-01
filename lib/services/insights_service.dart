// lib/services/insights_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InsightsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper to parse amount robustly
  double _parseAmount(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) {
      final cleaned = v.replaceAll(',', '').trim();
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  // Helper to check if a doc's date falls in [start, end)
  bool _docDateInRange(Map<String, dynamic> data, DateTime start, DateTime end) {
    final d = data['date'];
    if (d == null) return false;
    if (d is Timestamp) {
      final dt = d.toDate();
      return !dt.isBefore(start) && dt.isBefore(end);
    }
    if (d is DateTime) {
      return !d.isBefore(start) && d.isBefore(end);
    }
    if (d is String) {
      // try ISO parse
      try {
        final parsed = DateTime.parse(d);
        return !parsed.isBefore(start) && parsed.isBefore(end);
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  // Fetch docs from spending(collection) for the user in a date range.
  // Attempts server-side date query first; if that fails (or returns none),
  // falls back to fetching all user docs and filtering client-side.
  Future<List<QueryDocumentSnapshot>> _fetchSpendingDocsInRange(
      String userId, DateTime start, DateTime end) async {
    final base = _firestore.collection('spending').where('userId', isEqualTo: userId);

    try {
      // Try server-side range query (fast & efficient if `date` is a Timestamp)
      final snap = await base
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end))
          .get();
      return snap.docs;
    } catch (_) {
      // If range query fails (e.g., date stored as string, or index needed), fallback:
      final snap = await base.get();
      final filtered = snap.docs.where((d) {
        final data = d.data() as Map<String, dynamic>;
        return _docDateInRange(data, start, end);
      }).toList();
      return filtered;
    }
  }

  /// Main method: returns a map containing:
  /// - totalThisMonth, totalLastMonth,
  /// - percentChange, categoryTotals (this month),
  /// - suggestions (list of strings), docCount
  Future<Map<String, dynamic>> analyzeSpending({bool debug = false}) async {
    final user = _auth.currentUser;
    if (user == null) {
      return {
        "totalThisMonth": 0.0,
        "totalLastMonth": 0.0,
        "percentChange": 0.0,
        "categoryTotals": <String, double>{},
        "suggestions": ["Please sign in to see insights."],
        "docCount": 0,
      };
    }

    final now = DateTime.now();
    final startOfThisMonth = DateTime(now.year, now.month, 1);
    final startOfNextMonth = (now.month < 12)
        ? DateTime(now.year, now.month + 1, 1)
        : DateTime(now.year + 1, 1, 1);
    final startOfLastMonth = (now.month > 1)
        ? DateTime(now.year, now.month - 1, 1)
        : DateTime(now.year - 1, 12, 1);

    try {
      // fetch docs for this month and last month
      final docsThisMonth =
          await _fetchSpendingDocsInRange(user.uid, startOfThisMonth, startOfNextMonth);
      final docsLastMonth =
          await _fetchSpendingDocsInRange(user.uid, startOfLastMonth, startOfThisMonth);

      double totalThis = 0.0;
      double totalLast = 0.0;
      final Map<String, double> categoryTotals = {};

      for (var d in docsThisMonth) {
        final data = d.data() as Map<String, dynamic>;
        final amt = _parseAmount(data['amount']);
        totalThis += amt;
        final cat = (data['category'] ?? 'Other').toString();
        categoryTotals[cat] = (categoryTotals[cat] ?? 0.0) + amt;
      }

      for (var d in docsLastMonth) {
        final data = d.data() as Map<String, dynamic>;
        totalLast += _parseAmount(data['amount']);
      }

      double percentChange = 0.0;
      if (totalLast > 0) {
        percentChange = ((totalThis - totalLast) / totalLast) * 100;
      } else if (totalThis > 0) {
        percentChange = 100.0; // arbitrary: first-month activity
      }

      // Suggestions (simple rules; you can expand)
      final List<String> suggestions = [];
      if (totalThis == 0.0) {
        suggestions.add("No transactions this month. Add some to get insights.");
      } else {
        final biggestCategory = categoryTotals.entries.fold<MapEntry<String, double>?>(null,
            (prev, e) => prev == null || e.value > prev.value ? MapEntry(e.key, e.value) : prev);
        if (biggestCategory != null) {
          suggestions.add(
              "You spent the most on ${biggestCategory.key} (₹${biggestCategory.value.toStringAsFixed(2)}). Consider reviewing this category.");
        }
        if (percentChange > 20) {
          suggestions.add(
              "Spending increased by ${percentChange.toStringAsFixed(0)}% vs last month. Look for one-time or recurring spikes.");
        } else if (percentChange < -20) {
          suggestions.add("Nice — spending decreased compared to last month.");
        } else {
          suggestions.add("Spending is stable compared to last month.");
        }
      }

      if (debug) {
        suggestions.add("DEBUG: thisMonthDocs=${docsThisMonth.length}, lastMonthDocs=${docsLastMonth.length}");
      }

      return {
        "totalThisMonth": totalThis,
        "totalLastMonth": totalLast,
        "percentChange": percentChange,
        "categoryTotals": categoryTotals,
        "suggestions": suggestions,
        "docCount": docsThisMonth.length,
      };
    } catch (e) {
      return {
        "totalThisMonth": 0.0,
        "totalLastMonth": 0.0,
        "percentChange": 0.0,
        "categoryTotals": <String, double>{},
        "suggestions": ["Error loading insights: $e"],
        "docCount": 0,
      };
    }
  }
}
