import 'package:flutter/material.dart';
import 'item_selection_page.dart';
import 'receipt_scanner_page.dart'; // Add this import

class CategorySelectionPage extends StatelessWidget {
  const CategorySelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the list of categories and their icons
    final List<Map<String, dynamic>> categories = [
      {
        'name': 'Grocery',
        'icon': Icons.local_grocery_store,
        'color': Colors.green.shade400,
      },
      {
        'name': 'Medicines',
        'icon': Icons.local_hospital,
        'color': Colors.red.shade400,
      },
      {
        'name': 'Food',
        'icon': Icons.restaurant,
        'color': Colors.orange.shade400,
      },
      {
        'name': 'Drinks',
        'icon': Icons.local_bar,
        'color': Colors.blue.shade400,
      },
      {
        'name': 'Bill Payments',
        'icon': Icons.receipt,
        'color': Colors.purple.shade400,
      },
      {
        'name': 'Apparel',
        'icon': Icons.shopping_bag,
        'color': Colors.pink.shade400,
      },
      {
        'name': 'Electronics',
        'icon': Icons.devices,
        'color': Colors.teal.shade400,
      },
      {
        'name': 'Cosmetics',
        'icon': Icons.palette,
        'color': Colors.brown.shade400,
      },
      {
        'name': 'Sports',
        'icon': Icons.sports_tennis,
        'color': Colors.indigo.shade400,
      },
      {
        'name': 'Stationary',
        'icon': Icons.school,
        'color': Colors.cyan.shade400,
      },
      {
        'name': 'Books',
        'icon': Icons.menu_book,
        'color': Colors.amber.shade400,
      },
      {
        'name': 'Memberships',
        'icon': Icons.card_membership,
        'color': Colors.deepOrange.shade400,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFECE2D2),
      appBar: AppBar(
        title: const Text('Choose a Spending Category'),
        backgroundColor: const Color(0xFFD9641E),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a Spending Category',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            
            // Scan Receipt Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReceiptScannerPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.document_scanner, size: 28),
                label: const Text(
                  'Scan Receipt',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B5B95),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            
            const Divider(height: 24, thickness: 2),
            
            const SizedBox(height: 8),
            
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.8,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _buildCategoryCard(
                    context,
                    category['name']!,
                    category['icon']!,
                    category['color']!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String name,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemSelectionPage(category: name),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Text(
              name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.black),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}