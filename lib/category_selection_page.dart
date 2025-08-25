import 'package:flutter/material.dart';
import 'item_selection_page.dart';

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
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Category'),
        backgroundColor: const Color(0xFF6B5B95),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Browse by Category',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 20),
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
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Text(
              name,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
