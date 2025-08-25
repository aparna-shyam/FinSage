// home_wrapper.dart
import 'package:flutter/material.dart';
import 'package:finsage/main_app_page.dart';
import 'package:finsage/profile_page.dart';
import 'package:finsage/insights_page.dart'; // Import the new InsightsPage
import 'package:finsage/category_selection_page.dart'; // Import the new Category Selection page

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const CategorySelectionPage(), // New landing page for categories
    const MainAppPage(), // Now the transactions page
    const InsightsPage(), // For news and suggestions
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Shop'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Insights',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF6B5B95),
        unselectedItemColor:
            Colors.grey, // Add unselected color for better visibility
        showUnselectedLabels: true, // Show labels for all items
        onTap: _onItemTapped,
      ),
    );
  }
}
