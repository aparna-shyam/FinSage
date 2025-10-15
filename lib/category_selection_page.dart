import 'package:flutter/material.dart';
import 'item_selection_page.dart';
import 'receipt_scanner_page.dart';

class CategorySelectionPage extends StatelessWidget {
  const CategorySelectionPage({super.key});

  // Updated color constants to match dashboard_page.dart
  static const Color primaryColor = Color(0xFF008080); // Deep Teal
  static const Color secondaryColor = Color(0xFFB76E79); // Rose Gold
  static const Color gradientStartColor = Color(0xFF2C3E50); // Dark Blue-Purple
  static const Color gradientEndColor = Color(0xFF4CA1AF); // Lighter Blue-Teal
  static const Color cardColor = Color(0xFFFFFFFF); // Pure White

  // Define the list of categories and their icons
  final List<Map<String, dynamic>> categories = const [
    {
      'name': 'Grocery',
      'icon': Icons.local_grocery_store,
      'color': Color(0xFF2E7D32), // Darker Green
    },
    {
      'name': 'Medicines',
      'icon': Icons.local_hospital,
      'color': Color(0xFFC62828), // Darker Red
    },
    {
      'name': 'Food',
      'icon': Icons.restaurant,
      'color': Color(0xFFEF6C00), // Darker Orange
    },
    {
      'name': 'Drinks',
      'icon': Icons.local_bar,
      'color': Color(0xFF1565C0), // Darker Blue
    },
    {
      'name': 'Bill Payments',
      'icon': Icons.receipt,
      'color': Color(0xFF6A1B9A), // Darker Purple
    },
    {
      'name': 'Apparel',
      'icon': Icons.shopping_bag,
      'color': Color(0xFFAD1457), // Darker Pink
    },
    {
      'name': 'Electronics',
      'icon': Icons.devices,
      'color': Color(0xFF00695C), // Darker Teal
    },
    {
      'name': 'Cosmetics',
      'icon': Icons.palette,
      'color': Color(0xFF4E342E), // Darker Brown
    },
    {
      'name': 'Sports',
      'icon': Icons.sports_tennis,
      'color': Color(0xFF283593), // Darker Indigo
    },
    {
      'name': 'Stationary',
      'icon': Icons.school,
      'color': Color(0xFF00838F), // Darker Cyan
    },
    {
      'name': 'Books',
      'icon': Icons.menu_book,
      'color': Color(0xFFFF8F00), // Darker Amber
    },
    {
      'name': 'Memberships',
      'icon': Icons.card_membership,
      'color': Color(0xFFD84315), // Darker Deep Orange
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Choose a Spending Category',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor, // Deep Teal
        elevation: 0,
        automaticallyImplyLeading: true,
      ),
      body: Container(
        // Apply gradient background like dashboard_page.dart
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStartColor, gradientEndColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scan Receipt Button Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
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
                  backgroundColor: secondaryColor, // Rose Gold
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  minimumSize: const Size(double.infinity, 60),
                ),
              ),
            ),

            // Divider for visual separation
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Divider(
                height: 1,
                thickness: 1,
                color:
                    Colors.white54, // Lighter divider for gradient background
              ),
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
                  color: Colors.white, // White text on gradient background
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
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _buildCategoryCard(
                      context,
                      category['name'] as String,
                      category['icon'] as IconData,
                      category['color'] as Color,
                    );
                  },
                ),
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
        color: cardColor, // Pure White Card Color
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
