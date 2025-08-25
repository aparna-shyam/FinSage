import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ItemSelectionPage extends StatefulWidget {
  final String category;

  const ItemSelectionPage({super.key, required this.category});

  @override
  State<ItemSelectionPage> createState() => _ItemSelectionPageState();
}

class _ItemSelectionPageState extends State<ItemSelectionPage> {
  // Dummy data for each category. In a real app, this would be fetched from a database.
  final Map<String, List<Map<String, dynamic>>> _items = {
    'Grocery': [
      {
        'name': 'Milk',
        'image': 'https://placehold.co/150x150/e8f5e9/000?text=Milk',
      },
      {
        'name': 'Bread',
        'image': 'https://placehold.co/150x150/e8f5e9/000?text=Bread',
      },
      {
        'name': 'Eggs',
        'image': 'https://placehold.co/150x150/e8f5e9/000?text=Eggs',
      },
    ],
    'Medicines': [
      {
        'name': 'Painkillers',
        'image': 'https://placehold.co/150x150/fbe9e7/000?text=Pills',
      },
      {
        'name': 'Band-Aids',
        'image': 'https://placehold.co/150x150/fbe9e7/000?text=Band-Aids',
      },
      {
        'name': 'Cough Syrup',
        'image': 'https://placehold.co/150x150/fbe9e7/000?text=Syrup',
      },
    ],
    'Food': [
      {
        'name': 'Burger',
        'image': 'https://placehold.co/150x150/fff3e0/000?text=Burger',
      },
      {
        'name': 'Pizza',
        'image': 'https://placehold.co/150x150/fff3e0/000?text=Pizza',
      },
      {
        'name': 'Sushi',
        'image': 'https://placehold.co/150x150/fff3e0/000?text=Sushi',
      },
    ],
    'Drinks': [
      {
        'name': 'Soda',
        'image': 'https://placehold.co/150x150/e3f2fd/000?text=Soda',
      },
      {
        'name': 'Coffee',
        'image': 'https://placehold.co/150x150/e3f2fd/000?text=Coffee',
      },
      {
        'name': 'Juice',
        'image': 'https://placehold.co/150x150/e3f2fd/000?text=Juice',
      },
    ],
    'Bill Payments': [
      {
        'name': 'Electricity Bill',
        'image': 'https://placehold.co/150x150/e1f5fe/000?text=Electricity',
      },
      {
        'name': 'Phone Bill',
        'image': 'https://placehold.co/150x150/e1f5fe/000?text=Phone',
      },
      {
        'name': 'Water Bill',
        'image': 'https://placehold.co/150x150/e1f5fe/000?text=Water',
      },
    ],
    'Apparel': [
      {
        'name': 'Shirt',
        'image': 'https://placehold.co/150x150/f8bbd0/000?text=Shirt',
      },
      {
        'name': 'T-Shirt',
        'image': 'https://placehold.co/150x150/f8bbd0/000?text=T-Shirt',
      },
      {
        'name': 'Skirt',
        'image': 'https://placehold.co/150x150/f8bbd0/000?text=Skirt',
      },
      {
        'name': 'Blouse',
        'image': 'https://placehold.co/150x150/f8bbd0/000?text=Blouse',
      },
      {
        'name': 'Pants',
        'image': 'https://placehold.co/150x150/f8bbd0/000?text=Pants',
      },
    ],
    'Electronics': [
      {
        'name': 'Smartphone',
        'image': 'https://placehold.co/150x150/b2ebf2/000?text=Phone',
      },
      {
        'name': 'Headphones',
        'image': 'https://placehold.co/150x150/b2ebf2/000?text=Headphones',
      },
      {
        'name': 'Laptop',
        'image': 'https://placehold.co/150x150/b2ebf2/000?text=Laptop',
      },
    ],
    'Cosmetics': [
      {
        'name': 'Lipstick',
        'image': 'https://placehold.co/150x150/d7ccc8/000?text=Lipstick',
      },
      {
        'name': 'Mascara',
        'image': 'https://placehold.co/150x150/d7ccc8/000?text=Mascara',
      },
      {
        'name': 'Foundation',
        'image': 'https://placehold.co/150x150/d7ccc8/000?text=Foundation',
      },
    ],
    'Sports': [
      {
        'name': 'Basketball',
        'image': 'https://placehold.co/150x150/e8f5e9/000?text=Ball',
      },
      {
        'name': 'Running Shoes',
        'image': 'https://placehold.co/150x150/e8f5e9/000?text=Shoes',
      },
      {
        'name': 'Yoga Mat',
        'image': 'https://placehold.co/150x150/e8f5e9/000?text=Yoga',
      },
    ],
    'Stationary': [
      {
        'name': 'Notebook',
        'image': 'https://placehold.co/150x150/c5e1a5/000?text=Notebook',
      },
      {
        'name': 'Pen Set',
        'image': 'https://placehold.co/150x150/c5e1a5/000?text=Pens',
      },
      {
        'name': 'Highlighters',
        'image': 'https://placehold.co/150x150/c5e1a5/000?text=Markers',
      },
    ],
    'Books': [
      {
        'name': 'Fiction Novel',
        'image': 'https://placehold.co/150x150/fbc02d/000?text=Novel',
      },
      {
        'name': 'Textbook',
        'image': 'https://placehold.co/150x150/fbc02d/000?text=Textbook',
      },
    ],
  };

  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction(String itemName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not logged in.')));
      }
      return;
    }

    final priceText = _priceController.text;
    final quantityText = _quantityController.text;

    if (priceText.isEmpty || quantityText.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter both price and quantity.'),
          ),
        );
      }
      return;
    }

    final price = double.tryParse(priceText);
    final quantity = int.tryParse(quantityText);

    if (price == null || quantity == null || price <= 0 || quantity <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter valid numbers.')),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final totalAmount = price * quantity;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .add({
            'description': '$quantity x $itemName',
            'category': widget.category,
            'amount': totalAmount,
            'timestamp': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        Navigator.of(context).pop(); // Close dialog on success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaction for $itemName saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save transaction: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showItemDetailsDialog(String itemName, String itemImage) {
    _priceController.clear();
    _quantityController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Add $itemName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    itemImage,
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 100),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Price',
                    prefixText: '\$',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isSaving ? null : () => _saveTransaction(itemName),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B5B95),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> itemsList = _items[widget.category] ?? [];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        backgroundColor: const Color(0xFF6B5B95),
        elevation: 0,
      ),
      body: Column(
        children: [
          // New eye-catching banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.yellow.shade400, Colors.orange.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exclusive Offers',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Flat 40% OFF on all items!',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.8,
              ),
              itemCount: itemsList.length,
              itemBuilder: (context, index) {
                final item = itemsList[index];
                return _buildItemGridCard(context, item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemGridCard(BuildContext context, Map<String, dynamic> item) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return InkWell(
      onTap: () => _showItemDetailsDialog(item['name'], item['image']),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    item['image'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 70),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['name']!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
