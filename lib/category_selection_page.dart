import 'package:flutter/material.dart';
import 'item_selection_page.dart';
import 'receipt_scanner_page.dart'; // Add this import

class CategorySelectionPage extends StatelessWidget {
  const CategorySelectionPage({super.key});

  // Define the orange color constant for the theme
  static const Color orangeColor = Color(0xFFD9641E);

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
      backgroundColor: const Color(0xFFECE2D2), // Light Beige Background
      appBar: AppBar(
        title: const Text(
          'Choose a Spending Category',
          style: TextStyle(color: Colors.white), // White text for orange AppBar
        ),
        backgroundColor: orangeColor,
        elevation: 0,
        automaticallyImplyLeading: true, // Allow user to navigate back
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scan Receipt Button Section
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16.0,
              16.0,
              16.0,
              0.0,
            ), // Top margin only
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
                backgroundColor: orangeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                minimumSize: const Size(
                  double.infinity,
                  60,
                ), // Ensure full width
              ),
            ),
          ),

          // Divider for visual separation
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Divider(height: 1, thickness: 1, color: Colors.grey),
          ),

          // Grid View Section Title
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 8.0,
            ),
            child: Text(
              'Or Select a Category Manually:',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),

          // Category Grid View
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12.0, // Reduced spacing slightly
                  mainAxisSpacing: 12.0, // Reduced spacing slightly
                  childAspectRatio:
                      0.9, // Adjusted ratio to fit more content better
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
          ),
        ],
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
        child: Padding(
          // Added padding for card content
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color), // Slightly smaller icon
              const SizedBox(height: 8),
              Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
