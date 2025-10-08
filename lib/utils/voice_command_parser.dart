class TransactionData {
  final double? amount;
  final String? category;
  final String? description;

  TransactionData({this.amount, this.category, this.description});
}

class BudgetData {
  final double? amount;
  final String? category;

  BudgetData({this.amount, this.category});
}

class GoalData {
  final String? name;
  final double? targetAmount;
  final DateTime? targetDate;

  GoalData({this.name, this.targetAmount, this.targetDate});
}

class VoiceCommandParser {
  // Parse transaction commands
  // Examples: "spent 500 rupees on food", "paid 1000 for rent"
  static TransactionData? parseTransaction(String text) {
    text = text.toLowerCase().trim();
    
    double? amount;
    String? category;
    String? description = text;

    // Extract amount
    final amountPatterns = [
      RegExp(r'(\d+(?:\.\d+)?)\s*(?:rupees?|rs|₹|inr)?'),
    ];

    for (var pattern in amountPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        amount = double.tryParse(match.group(1)!);
        break;
      }
    }

    // Extract category keywords
    final categoryKeywords = {
      'food': ['food', 'meal', 'lunch', 'dinner', 'breakfast', 'restaurant'],
      'transport': ['transport', 'taxi', 'uber', 'ola', 'petrol', 'fuel', 'bus', 'metro'],
      'shopping': ['shopping', 'clothes', 'shirt', 'shoes', 'purchase'],
      'entertainment': ['movie', 'entertainment', 'game', 'cinema'],
      'bills': ['bill', 'electricity', 'water', 'rent', 'utility'],
      'groceries': ['grocery', 'groceries', 'vegetables', 'market'],
      'health': ['medicine', 'doctor', 'hospital', 'health', 'medical'],
      'education': ['education', 'course', 'book', 'tuition'],
      'other': ['other', 'miscellaneous'],
    };

    for (var entry in categoryKeywords.entries) {
      for (var keyword in entry.value) {
        if (text.contains(keyword)) {
          category = entry.key;
          break;
        }
      }
      if (category != null) break;
    }

    if (amount != null) {
      return TransactionData(
        amount: amount,
        category: category ?? 'other',
        description: description,
      );
    }

    return null;
  }

  // Parse budget commands
  // Examples: "set budget 5000 for food", "budget 10000 rupees for shopping"
  static BudgetData? parseBudget(String text) {
    text = text.toLowerCase().trim();
    
    if (!text.contains('budget')) return null;

    double? amount;
    String? category;

    // Extract amount
    final amountMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(?:rupees?|rs|₹|inr)?')
        .firstMatch(text);
    if (amountMatch != null) {
      amount = double.tryParse(amountMatch.group(1)!);
    }

    // Extract category
    final categoryKeywords = {
      'food': ['food'],
      'transport': ['transport'],
      'shopping': ['shopping'],
      'entertainment': ['entertainment'],
      'bills': ['bills'],
      'groceries': ['groceries'],
      'health': ['health'],
      'education': ['education'],
      'other': ['other'],
    };

    for (var entry in categoryKeywords.entries) {
      for (var keyword in entry.value) {
        if (text.contains(keyword)) {
          category = entry.key;
          break;
        }
      }
      if (category != null) break;
    }

    if (amount != null) {
      return BudgetData(amount: amount, category: category);
    }

    return null;
  }

  // Parse goal commands
  // Examples: "save 50000 for vacation by december", "goal to save 100000 for bike"
  static GoalData? parseGoal(String text) {
    text = text.toLowerCase().trim();
    
    double? amount;
    String? name;
    DateTime? targetDate;

    // Extract amount
    final amountMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(?:rupees?|rs|₹|inr)?')
        .firstMatch(text);
    if (amountMatch != null) {
      amount = double.tryParse(amountMatch.group(1)!);
    }

    // Extract goal name (words after "for" or "to buy")
    final forMatch = RegExp(r'for\s+(\w+(?:\s+\w+)*?)(?:\s+by|\s*$)')
        .firstMatch(text);
    if (forMatch != null) {
      name = forMatch.group(1)?.trim();
    }

    // Extract date (basic month recognition)
    final months = {
      'january': 1, 'february': 2, 'march': 3, 'april': 4,
      'may': 5, 'june': 6, 'july': 7, 'august': 8,
      'september': 9, 'october': 10, 'november': 11, 'december': 12,
    };

    for (var entry in months.entries) {
      if (text.contains(entry.key)) {
        final now = DateTime.now();
        int year = now.year;
        if (entry.value < now.month) year++;
        targetDate = DateTime(year, entry.value, 1);
        break;
      }
    }

    if (amount != null) {
      return GoalData(
        name: name ?? 'Savings Goal',
        targetAmount: amount,
        targetDate: targetDate,
      );
    }

    return null;
  }
}