import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ReceiptScannerPage extends StatefulWidget {
  const ReceiptScannerPage({super.key});

  @override
  State<ReceiptScannerPage> createState() => _ReceiptScannerPageState();
}

class _ReceiptScannerPageState extends State<ReceiptScannerPage> {
  File? _image;
  bool _isProcessing = false;
  String _extractedText = '';

  // Parsed data
  double? _detectedAmount;
  String? _detectedMerchant;
  DateTime? _detectedDate;

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = 'Grocery';

  final List<String> _categories = [
    'Grocery',
    'Transportation',
    'Entertainment',
    'Shopping',
    'Food & Dining',
    'Bills & Utilities',
    'Healthcare',
    'Other',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _isProcessing = true;
        });
        await _processImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _processImage() async {
    if (_image == null) return;

    try {
      final inputImage = InputImage.fromFile(_image!);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      setState(() {
        _extractedText = recognizedText.text;
      });

      // Parse the extracted text
      _parseReceiptData(recognizedText.text);

      await textRecognizer.close();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing image: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// 🔍 Auto-categorization function
  String _detectCategory(String text) {
    text = text.toLowerCase();

    if (text.contains("milk") || text.contains("bread") || text.contains("supermarket") || text.contains("grocery")) {
      return "Grocery";
    } else if (text.contains("uber") || text.contains("ola") || text.contains("bus") || text.contains("train")) {
      return "Transportation";
    } else if (text.contains("movie") || text.contains("theatre") || text.contains("netflix")) {
      return "Entertainment";
    } else if (text.contains("restaurant") || text.contains("cafe") || text.contains("food")) {
      return "Food & Dining";
    } else if (text.contains("hospital") || text.contains("pharmacy") || text.contains("clinic")) {
      return "Healthcare";
    } else if (text.contains("electricity") || text.contains("water bill") || text.contains("internet")) {
      return "Bills & Utilities";
    } else if (text.contains("mall") || text.contains("shopping") || text.contains("store")) {
      return "Shopping";
    } else {
      return "Other";
    }
  }

  void _parseReceiptData(String text) {
    // Extract amount
    final amountRegex = RegExp(r'(?:₹|rs\.?|inr)?\s*(\d{1,6}(?:[.,]\d{2})?)', caseSensitive: false);
    final matches = amountRegex.allMatches(text);
    double? foundAmount;

    final lines = text.toLowerCase().split('\n');
    for (var line in lines) {
      if (line.contains('total') || line.contains('amount') || line.contains('grand')) {
        final amountMatch = amountRegex.firstMatch(line);
        if (amountMatch != null) {
          final amountStr = amountMatch.group(1)?.replaceAll(',', '.');
          foundAmount = double.tryParse(amountStr ?? '');
          if (foundAmount != null) break;
        }
      }
    }

    if (foundAmount == null && matches.isNotEmpty) {
      List<double> amounts = [];
      for (var match in matches) {
        final amountStr = match.group(1)?.replaceAll(',', '.');
        final amount = double.tryParse(amountStr ?? '');
        if (amount != null && amount > 10) {
          amounts.add(amount);
        }
      }
      if (amounts.isNotEmpty) {
        amounts.sort();
        foundAmount = amounts.last;
      }
    }

    // Extract date
    final dateRegex = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})');
    final dateMatch = dateRegex.firstMatch(text);
    DateTime? foundDate;

    if (dateMatch != null) {
      try {
        int day = int.parse(dateMatch.group(1)!);
        int month = int.parse(dateMatch.group(2)!);
        int year = int.parse(dateMatch.group(3)!);
        if (year < 100) year += 2000;
        foundDate = DateTime(year, month, day);
      } catch (e) {
        foundDate = null;
      }
    }

    // Extract merchant
    String? merchantName;
    final firstLines = text.split('\n').take(3).toList();
    if (firstLines.isNotEmpty) {
      merchantName = firstLines[0].trim();
      if (merchantName.length < 3) {
        merchantName = firstLines.length > 1 ? firstLines[1].trim() : null;
      }
    }

    setState(() {
      _detectedAmount = foundAmount;
      _detectedDate = foundDate ?? DateTime.now();
      _detectedMerchant = merchantName;

      if (_detectedAmount != null) {
        _amountController.text = _detectedAmount!.toStringAsFixed(2);
      }
      if (_detectedMerchant != null) {
        _descriptionController.text = _detectedMerchant!;
      }

      // ✅ Auto-set category using extracted text
      _selectedCategory = _detectCategory(text);
    });
  }

  Future<void> _saveTransaction() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('spending').add({
        'userId': user.uid,
        'amount': amount,
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'date': Timestamp.fromDate(_detectedDate ?? DateTime.now()),
        'isFromReceipt': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving transaction: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        backgroundColor: const Color(0xFF6B5B95),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_image != null)
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_image!, fit: BoxFit.cover),
                ),
              )
            else
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                ),
              ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B5B95),
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B5B95),
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (_isProcessing)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Processing receipt...'),
                  ],
                ),
              ),

            if (_image != null && !_isProcessing) ...[
              const Text(
                'Transaction Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              ListTile(
                title: const Text('Date'),
                subtitle: Text(
                  DateFormat('MMM d, y').format(_detectedDate ?? DateTime.now()),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _detectedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _detectedDate = picked;
                    });
                  }
                },
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B5B95),
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text(
                  'Save Transaction',
                  style: TextStyle(fontSize: 16),
                ),
              ),

              if (_extractedText.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Extracted Text',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _extractedText,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
