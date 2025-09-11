import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // A method to get the current user's ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Adds a new transaction to the 'spending' collection for the current user.
  Future<void> addTransaction({
    required String description,
    required String category,
    required double amount,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not logged in.');
    }

    try {
      await _db.collection('spending').add({
        'userId': userId,
        'description': description,
        'category': category,
        'amount': amount,
        'date': FieldValue.serverTimestamp(),
      });
      print('Transaction saved successfully.');
    } catch (e) {
      print('Error saving transaction: $e');
      rethrow;
    }
  }

  /// Fetches a list of the most recent transactions for the current user.
  Future<List<Map<String, dynamic>>> fetchRecentTransactions() async {
    final userId = currentUserId;
    if (userId == null) {
      return [];
    }

    try {
      final querySnapshot = await _db
          .collection('spending')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(10)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching transaction history: $e');
      rethrow;
    }
  }
}
