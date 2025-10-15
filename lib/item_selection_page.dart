import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finsage/services/firestore_service.dart';

// Theme Colors from DashboardPage
// 💠 Define the Primary/Accent color: Deep Teal ⭐️
const Color _primaryColor = Color(0xFF008080);
// 🔵 Gradient Start Color: Dark Blue-Purple
const Color _gradientStartColor = Color(0xFF2C3E50);
// 🔷 Gradient End Color: Lighter Blue-Teal
const Color _gradientEndColor = Color(0xFF4CA1AF);
// ⬜ Define the Card/Box color: Pure White ⭐️
const Color _cardColor = Color(0xFFFFFFFF);
// 🌹 Secondary/Accent Color (Used for highlights if needed, but sticking to primary for actions)
const Color _secondaryColor = Color(0xFFB76E79);

class ItemSelectionPage extends StatefulWidget {
  final String category;

  const ItemSelectionPage({super.key, required this.category});

  @override
  State<ItemSelectionPage> createState() => _ItemSelectionPageState();
}

class _ItemSelectionPageState extends State<ItemSelectionPage> {
  final FirestoreService _firestoreService = FirestoreService();

  // Dummy data for each category. Using local assets for reliable loading.
  final Map<String, List<Map<String, dynamic>>> _items = {
    'Grocery': [
      {'name': 'Milk', 'image': 'assets/images/milk.jpg'},
      {'name': 'Bread', 'image': 'assets/images/bread.jpg'},
      {'name': 'Eggs', 'image': 'assets/images/eggs.jpg'},
      {'name': 'Fruits', 'image': 'assets/images/fruits.jpg'},
      {'name': 'Vegetables', 'image': 'assets/images/vegetables.jpg'},
      {'name': 'Cheese', 'image': 'assets/images/cheese.jpg'},
      {'name': 'Yogurt', 'image': 'assets/images/yogurt.jpg'},
      {'name': 'Chicken', 'image': 'assets/images/chicken.jpg'},
      {'name': 'Fish', 'image': 'assets/images/fish.jpg'},
      {'name': 'Rice', 'image': 'assets/images/rice.jpg'},
      {'name': 'Pasta', 'image': 'assets/images/pasta.jpg'},
      {'name': 'Cereal', 'image': 'assets/images/cereal.jpg'},
      {'name': 'Snacks', 'image': 'assets/images/snacks.jpg'},
      {'name': 'Frozen Foods', 'image': 'assets/images/frozen_foods.jpg'},
      {'name': 'Beverages', 'image': 'assets/images/beverages.jpg'},
      {'name': 'Condiments', 'image': 'assets/images/condiments.jpg'},
      {'name': 'Spices', 'image': 'assets/images/spices.jpg'},
      {'name': 'Oils', 'image': 'assets/images/oils.jpg'},
      {'name': 'Baking Supplies', 'image': 'assets/images/baking_supplies.jpg'},
      {'name': 'Canned Goods', 'image': 'assets/images/canned_goods.jpg'},
      {'name': 'Dairy Products', 'image': 'assets/images/dairy_products.jpg'},
      {'name': 'Meat', 'image': 'assets/images/meat.jpg'},
      {'name': 'Seafood', 'image': 'assets/images/seafood.jpg'},
      {'name': 'Bread & Bakery', 'image': 'assets/images/bread_bakery.jpg'},
      {'name': 'Breakfast Foods', 'image': 'assets/images/breakfast_foods.jpg'},
      {
        'name': 'Sweets & Desserts',
        'image': 'assets/images/sweets_desserts.jpg',
      },
      {'name': 'Health Foods', 'image': 'assets/images/health_foods.jpg'},
      {'name': 'Organic Foods', 'image': 'assets/images/organic_foods.jpg'},
      {
        'name': 'International Foods',
        'image': 'assets/images/international_foods.jpg',
      },
      {'name': 'Baby Products', 'image': 'assets/images/baby_products.jpg'},
      {'name': 'Pet Supplies', 'image': 'assets/images/pet_supplies.jpg'},
    ],
    'Medicines': [
      {'name': 'Painkillers', 'image': 'assets/images/painkillers.jpg'},
      {'name': 'Band-Aids', 'image': 'assets/images/bandaids.jpg'},
      {'name': 'Cough Syrup', 'image': 'assets/images/cough_syrup.jpg'},
      {'name': 'Vitamins', 'image': 'assets/images/vitamins.jpg'},
      {'name': 'Antibiotics', 'image': 'assets/images/antibiotics.jpg'},
      {
        'name': 'Allergy Medicine',
        'image': 'assets/images/allergy_medicine.jpg',
      },
      {'name': 'Cold Medicine', 'image': 'assets/images/cold_medicine.jpg'},
      {'name': 'Digestive Aid', 'image': 'assets/images/digestive_aid.jpg'},
      {'name': 'First Aid Kit', 'image': 'assets/images/first_aid_kit.jpg'},
      {'name': 'Thermometer', 'image': 'assets/images/thermometer.jpg'},
      {
        'name': 'Prescription Glasses',
        'image': 'assets/images/prescription_glasses.jpg',
      },
      {'name': 'Contact Lenses', 'image': 'assets/images/contact_lenses.jpg'},
      {'name': 'Eye Drops', 'image': 'assets/images/eye_drops.jpg'},
      {'name': 'Ear Drops', 'image': 'assets/images/ear_drops.jpg'},
      {'name': 'Nasal Spray', 'image': 'assets/images/nasal_spray.jpg'},
      {
        'name': 'Antiseptic Cream',
        'image': 'assets/images/antiseptic_cream.jpg',
      },
      {
        'name': 'Hydrocortisone Cream',
        'image': 'assets/images/hydrocortisone_cream.jpg',
      },
      {
        'name': 'Insect Repellent',
        'image': 'assets/images/insect_repellent.jpg',
      },
      {'name': 'Sunscreen', 'image': 'assets/images/sunscreen.jpg'},
    ],
    'Food': [
      {'name': 'Idli', 'image': 'assets/images/idli.jpg'},
      {'name': 'Upma', 'image': 'assets/images/upma.jpg'},
      {'name': 'Dosa', 'image': 'assets/images/dosa.jpg'},
      {'name': 'Burger', 'image': 'assets/images/burger.png'},
      {'name': 'Pizza', 'image': 'assets/images/pizza.jpg'},
      {'name': 'Sushi', 'image': 'assets/images/sushi.jpg'},
      {'name': 'Pasta', 'image': 'assets/images/pasta.jpg'},
      {'name': 'Salad', 'image': 'assets/images/salad.jpg'},
      {'name': 'Steak', 'image': 'assets/images/steak.jpg'},
      {'name': 'Tacos', 'image': 'assets/images/tacos.jpg'},
      {'name': 'Ice Cream', 'image': 'assets/images/ice_cream.png'},
      {'name': 'Sandwich', 'image': 'assets/images/sandwich.jpg'},
      {'name': 'Soup', 'image': 'assets/images/soup.jpg'},
      {'name': 'Fries', 'image': 'assets/images/fries.jpg'},
      {'name': 'Dumplings', 'image': 'assets/images/dumplings.jpg'},
      {'name': 'Biriyani', 'image': 'assets/images/biriyani.jpg'},
      {'name': 'Mandi', 'image': 'assets/images/mandi.jpg'},
      {'name': 'Chicken Curry', 'image': 'assets/images/chicken_curry.jpg'},
      {'name': 'Noodles', 'image': 'assets/images/noodles.jpg'},
      {'name': 'BBQ', 'image': 'assets/images/bbq.jpg'},
      {'name': 'Seafood', 'image': 'assets/images/seafood.jpg'},
      {'name': 'Dessert', 'image': 'assets/images/dessert.jpg'},
    ],
    'Drinks': [
      {'name': 'Soda', 'image': 'assets/images/soda.jpg'},
      {'name': 'Coffee', 'image': 'assets/images/coffee.jpg'},
      {'name': 'Juice', 'image': 'assets/images/juice.jpg'},
      {'name': 'Tea', 'image': 'assets/images/tea.jpg'},
      {'name': 'Milkshakes', 'image': 'assets/images/milkshakes.jpg'},
      {'name': 'Energy Drinks', 'image': 'assets/images/energydrinks.png'},
      {'name': 'Water', 'image': 'assets/images/water.jpg'},
      {'name': 'Soft Drinks', 'image': 'assets/images/softdrinks.jpg'},
    ],
    'Bill Payments': [],
    'Apparel': [
      {'name': 'Shirt', 'image': 'assets/images/shirt.jpg'},
      {'name': 'T-Shirt', 'image': 'assets/images/t-shirt.jpg'},
      {'name': 'Skirt', 'image': 'assets/images/skirt.jpg'},
      {'name': 'Blouse', 'image': 'assets/images/blouse.jpg'},
      {'name': 'Pants', 'image': 'assets/images/pants.jpg'},
      {'name': 'Jeans', 'image': 'assets/images/jeans.jpg'},
      {'name': 'Shorts', 'image': 'assets/images/shorts.png'},
      {'name': 'Varsity Jacket', 'image': 'assets/images/varsity.jpg'},
      {'name': 'Jacket', 'image': 'assets/images/jacket.jpg'},
      {'name': 'Coat', 'image': 'assets/images/coat.jpg'},
      {'name': 'Sweater', 'image': 'assets/images/sweater.jpg'},
      {'name': 'Hoodie', 'image': 'assets/images/hoodie.jpg'},
      {'name': 'Suit', 'image': 'assets/images/suit.jpg'},
      {'name': 'Tie', 'image': 'assets/images/tie.jpg'},
      {'name': 'Scarf', 'image': 'assets/images/scarf.jpg'},
      {'name': 'Gloves', 'image': 'assets/images/gloves.jpg'},
      {'name': 'Hat', 'image': 'assets/images/hat.jpg'},
      {'name': 'Belt', 'image': 'assets/images/belt.jpg'},
      {'name': 'Socks', 'image': 'assets/images/socks.png'},
      {'name': 'Shoes', 'image': 'assets/images/shoes.jpg'},
      {'name': 'Sneakers', 'image': 'assets/images/sneakers.jpg'},
      {'name': 'Boots', 'image': 'assets/images/boots.jpg'},
      {'name': 'Sandals', 'image': 'assets/images/sandals.jpg'},
      {'name': 'Slippers', 'image': 'assets/images/slippers.jpg'},
      {'name': 'Sleepwear', 'image': 'assets/images/sleepwear.png'},
      {'name': 'Accessories', 'image': 'assets/images/accessories.jpg'},
      {'name': 'Jewelry', 'image': 'assets/images/jewelry.jpg'},
    ],
    'Electronics': [
      {'name': 'Smartphone', 'image': 'assets/images/smartphone.jpg'},
      {'name': 'Headphones', 'image': 'assets/images/headphones.jpg'},
      {'name': 'Laptop', 'image': 'assets/images/laptop.jpg'},
      {'name': 'Smartwatch', 'image': 'assets/images/smartwatch.jpg'},
      {'name': 'Tablet', 'image': 'assets/images/tablet.jpg'},
      {'name': 'Camera', 'image': 'assets/images/camera.jpg'},
      {'name': 'Speaker', 'image': 'assets/images/speaker.png'},
      {'name': 'Monitor', 'image': 'assets/images/monitor.jpg'},
      {'name': 'Keyboard', 'image': 'assets/images/keyboard.jpg'},
      {'name': 'Mouse', 'image': 'assets/images/mouse.jpg'},
      {'name': 'Printer', 'image': 'assets/images/printer.jpg'},
      {'name': 'Scanner', 'image': 'assets/images/scanner.jpg'},
      {'name': 'TV Remote', 'image': 'assets/images/tv_remote.jpg'},
      {'name': 'Projector', 'image': 'assets/images/projector.jpg'},
      {'name': 'Game Controller', 'image': 'assets/images/game_controller.jpg'},
      {'name': 'Charger', 'image': 'assets/images/charger.jpg'},
      {'name': 'USB Cable', 'image': 'assets/images/usb_cable.jpg'},
      {'name': 'Power Bank', 'image': 'assets/images/power_bank.jpg'},
      {
        'name': 'External Hard Drive',
        'image': 'assets/images/external_hard_drive.jpg',
      },
      {'name': 'Router', 'image': 'assets/images/router.jpg'},
      {
        'name': 'Smart Home Device',
        'image': 'assets/images/smart_home_device.jpg',
      },
      {'name': 'TV', 'image': 'assets/images/tv.jpg'},
      {'name': 'Drone', 'image': 'assets/images/drone.jpg'},
      {'name': 'Fitness Tracker', 'image': 'assets/images/fitness_tracker.jpg'},
    ],
    'Cosmetics': [
      {'name': 'Lipstick', 'image': 'assets/images/lipstick.jpg'},
      {'name': 'Mascara', 'image': 'assets/images/mascara.jpg'},
      {'name': 'Foundation', 'image': 'assets/images/foundation.jpg'},
      {'name': 'Lip Balm', 'image': 'assets/images/lip_balm.jpg'},
      {'name': 'Nail Polish', 'image': 'assets/images/nail_polish.jpg'},
      {'name': 'Blush', 'image': 'assets/images/blush.jpg'},
      {'name': 'Eyeshadow', 'image': 'assets/images/eyeshadow.jpg'},
      {'name': 'Eyeliner', 'image': 'assets/images/eyeliner.jpg'},
      {'name': 'Concealer', 'image': 'assets/images/concealer.jpg'},
      {'name': 'Makeup Remover', 'image': 'assets/images/makeup_remover.jpg'},
      {'name': 'Face Wash', 'image': 'assets/images/face_wash.jpg'},
      {'name': 'Moisturizer', 'image': 'assets/images/moisturizer.jpg'},
      {'name': 'Sunscreen', 'image': 'assets/images/sunscreen.jpg'},
      {'name': 'Perfume', 'image': 'assets/images/perfume.jpg'},
      {'name': 'Body Lotion', 'image': 'assets/images/body_lotion.png'},
      {'name': 'Hair Spray', 'image': 'assets/images/hair_spray.jpg'},
      {'name': 'Comb', 'image': 'assets/images/comb.jpg'},
      {'name': 'Brush', 'image': 'assets/images/brush.jpg'},
      {'name': 'Shampoo', 'image': 'assets/images/shampoo.jpg'},
      {'name': 'Conditioner', 'image': 'assets/images/conditioner.jpg'},
      {'name': 'Hair Gel', 'image': 'assets/images/hair_gel.png'},
      {'name': 'Deodorant', 'image': 'assets/images/deodorant.png'},
    ],
    'Sports': [
      {'name': 'Basketball', 'image': 'assets/images/basketball.jpg'},
      {'name': 'Running Shoes', 'image': 'assets/images/running_shoes.jpg'},
      {'name': 'Yoga Mat', 'image': 'assets/images/yoga_mat.jpg'},
      {'name': 'Tennis Racket', 'image': 'assets/images/tennis_racket.jpg'},
      {'name': 'Football', 'image': 'assets/images/football.jpg'},
      {'name': 'Cycling Helmet', 'image': 'assets/images/cycling_helmet.jpg'},
      {'name': 'Swimwear', 'image': 'assets/images/swimwear.jpg'},
      {'name': 'Dumbbells', 'image': 'assets/images/dumbbells.jpg'},
      {'name': 'Jump Rope', 'image': 'assets/images/jump_rope.jpg'},
      {'name': 'Fitness Tracker', 'image': 'assets/images/fitness_tracker.jpg'},
      {'name': 'Golf Clubs', 'image': 'assets/images/golf_clubs.jpg'},
      {'name': 'Baseball Glove', 'image': 'assets/images/baseball_glove.jpg'},
      {'name': 'Hiking Boots', 'image': 'assets/images/hiking_boots.jpg'},
      {'name': 'Ski Goggles', 'image': 'assets/images/ski_goggles.jpg'},
      {'name': 'Boxing Gloves', 'image': 'assets/images/boxing_gloves.jpg'},
      {'name': 'Skateboard', 'image': 'assets/images/skateboard.jpg'},
      {'name': 'Surfboard', 'image': 'assets/images/surfboard.jpg'},
      {'name': 'Treadmill', 'image': 'assets/images/treadmill.jpg'},
      {'name': 'Exercise Bike', 'image': 'assets/images/exercise_bike.jpg'},
      {'name': 'Rowing Machine', 'image': 'assets/images/rowing_machine.jpg'},
    ],
    'Stationary': [
      {'name': 'Notebook', 'image': 'assets/images/notebook.jpg'},
      {'name': 'Pen Set', 'image': 'assets/images/pen_set.jpg'},
      {'name': 'Highlighters', 'image': 'assets/images/highlighters.jpg'},
      {'name': 'Sticky Notes', 'image': 'assets/images/sticky_notes.jpg'},
      {'name': 'Paper Clips', 'image': 'assets/images/paper_clips.jpeg'},
      {'name': 'Stapler', 'image': 'assets/images/stapler.jpg'},
      {'name': 'Eraser', 'image': 'assets/images/eraser.jpg'},
      {'name': 'Ruler', 'image': 'assets/images/ruler.jpg'},
      {'name': 'Glue Stick', 'image': 'assets/images/glue_stick.jpg'},
      {'name': 'Scissors', 'image': 'assets/images/scissors.jpg'},
      {'name': 'Calculator', 'image': 'assets/images/calculator.jpg'},
      {'name': 'File Folders', 'image': 'assets/images/file_folders.jpg'},
      {'name': 'Desk Organizer', 'image': 'assets/images/desk_organizer.jpg'},
    ],
    'Books': [
      {'name': 'Fiction Novel', 'image': 'assets/images/fiction_novel.jpg'},
      {'name': 'Textbook', 'image': 'assets/images/textbook.jpg'},
      {'name': 'Magazine', 'image': 'assets/images/magazine.jpg'},
      {'name': 'Comic Book', 'image': 'assets/images/comic_book.jpg'},
      {'name': 'Biography', 'image': 'assets/images/biography.jpg'},
      {'name': 'Science Book', 'image': 'assets/images/science_book.jpg'},
      {'name': 'History Book', 'image': 'assets/images/history_book.jpg'},
      {'name': 'Children\'s Book', 'image': 'assets/images/childrens_book.jpg'},
      {'name': 'Cookbook', 'image': 'assets/images/cookbook.jpg'},
      {'name': 'Travel Guide', 'image': 'assets/images/travel_guide.jpg'},
      {'name': 'Self-Help Book', 'image': 'assets/images/self_help_book.jpg'},
      {'name': 'Art Book', 'image': 'assets/images/art_book.jpg'},
      {
        'name': 'Photography Book',
        'image': 'assets/images/photography_book.jpg',
      },
      {'name': 'Poetry Book', 'image': 'assets/images/poetry_book.jpg'},
      {'name': 'Graphic Novel', 'image': 'assets/images/graphic_novel.jpg'},
      {'name': 'Mystery Novel', 'image': 'assets/images/mystery_novel.jpg'},
      {'name': 'Romance Novel', 'image': 'assets/images/romance_novel.jpg'},
      {'name': 'Fantasy Novel', 'image': 'assets/images/fantasy_novel.jpg'},
      {'name': 'Horror Novel', 'image': 'assets/images/horror_novel.jpg'},
      {'name': 'Thriller Novel', 'image': 'assets/images/thriller_novel.jpg'},
    ],
    'Memberships': [], // Add an empty list for Memberships
  };

  // Controllers for generic price and quantity input
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  // Controllers for specific inputs
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _billAmountController = TextEditingController();
  String? _selectedBillType;

  bool _isSaving = false;

  @override
  void dispose() {
    _priceController.dispose();
    _quantityController.dispose();
    _itemNameController.dispose();
    _billAmountController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction(String itemName, String itemImage) async {
    String description;
    double amount;

    // ignore: use_build_context_synchronously
    if (!mounted) return;

    switch (widget.category) {
      case 'Books':
      case 'Electronics':
      case 'Cosmetics':
        final itemDetails = _itemNameController.text;
        final price = double.tryParse(_priceController.text);
        if (itemDetails.isEmpty || price == null || price <= 0) {
          _showError('Please enter a valid item name/brand and price.');
          return;
        }
        description = '1 x $itemDetails';
        amount = price;
        break;
      case 'Bill Payments':
        final billAmount = double.tryParse(_billAmountController.text);
        if (billAmount == null ||
            billAmount <= 0 ||
            _selectedBillType == null) {
          _showError(
            'Please enter a valid bill amount and select a bill type.',
          );
          return;
        }
        description = 'Bill Payment: $_selectedBillType';
        amount = billAmount;
        break;
      default:
        // Default case for categories with price and quantity
        final price = double.tryParse(_priceController.text);
        final quantity = int.tryParse(_quantityController.text);
        if (price == null || quantity == null || price <= 0 || quantity <= 0) {
          _showError('Please enter valid numbers for price and quantity.');
          return;
        }
        description = '$quantity x $itemName';
        amount = price * quantity;
        break;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _firestoreService.addTransaction(
        description: description,
        category: widget.category,
        amount: amount,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close dialog on success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaction saved for $description!')),
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

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  // Helper method for consistent text field styling in dark background forms
  InputDecoration _buildInputDecoration(String label, {String? prefixText}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      filled: true,
      fillColor: Colors.white,
      prefixText: prefixText,
      prefixStyle: const TextStyle(color: Colors.black),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _primaryColor, width: 2),
      ),
    );
  }

  void _showItemDetailsDialog(String itemName, String itemImage) {
    _priceController.clear();
    _quantityController.clear();
    _itemNameController.clear();
    _billAmountController.clear();
    _selectedBillType = null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Add ${widget.category} Expense'),
          content: SingleChildScrollView(
            child: _buildDialogContent(itemName, itemImage),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () => _saveTransaction(itemName, itemImage),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor, // Deep Teal Button
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

  Widget _buildDialogContent(String itemName, String itemImage) {
    switch (widget.category) {
      case 'Books':
        return _buildBookDialog();
      case 'Electronics':
      case 'Cosmetics':
        return _buildGenericItemDialog(itemName, itemImage);
      case 'Bill Payments':
        // This case should ideally not be reached as Bill Payments uses a full page form
        return _buildBillPaymentDialog();
      default:
        return _buildDefaultItemDialog(itemName, itemImage);
    }
  }

  Widget _buildDefaultItemDialog(String itemName, String itemImage) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
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
          decoration: _buildInputDecoration('Price', prefixText: '₹'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          decoration: _buildInputDecoration('Quantity'),
        ),
      ],
    );
  }

  Widget _buildGenericItemDialog(String itemName, String itemImage) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
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
          controller: _itemNameController,
          decoration: _buildInputDecoration('Enter Item Name/Brand'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: _buildInputDecoration('Price', prefixText: '₹'),
        ),
      ],
    );
  }

  Widget _buildBookDialog() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _itemNameController,
          decoration: _buildInputDecoration('Enter Book Title'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: _buildInputDecoration('Price', prefixText: '₹'),
        ),
      ],
    );
  }

  Widget _buildBillPaymentDialog() {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedBillType,
              decoration: _buildInputDecoration('Select Bill Type'),
              items: ['Electricity', 'Water', 'Phone', 'Internet', 'Rent'].map((
                String value,
              ) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedBillType = newValue;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _billAmountController,
              keyboardType: TextInputType.number,
              decoration: _buildInputDecoration('Bill Amount', prefixText: '₹'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> itemsList = _items[widget.category] ?? [];
    final bool isBillsPage = widget.category == 'Bill Payments';
    final bool isMedicinesPage = widget.category == 'Medicines';
    final bool isMembershipsPage = widget.category == 'Memberships';

    // Build methods for specific full-page forms (Bills, Medicines, Memberships)
    Widget _buildFormScaffold(Widget formWidget) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            widget.category,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: _primaryColor, // Deep Teal
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_gradientStartColor, _gradientEndColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: formWidget,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (isBillsPage) {
      return _buildFormScaffold(
        _BillPaymentForm(firestoreService: _firestoreService),
      );
    }

    if (isMedicinesPage) {
      return _buildFormScaffold(
        _MedicalExpenseForm(firestoreService: _firestoreService),
      );
    }

    if (isMembershipsPage) {
      return _buildFormScaffold(
        _MembershipExpenseForm(firestoreService: _firestoreService),
      );
    }

    // For all other categories, display the themed grid
    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent to allow body gradient
      appBar: AppBar(
        title: Text(
          widget.category,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: _primaryColor, // Deep Teal
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradientStartColor, _gradientEndColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            childAspectRatio: 0.8,
          ),
          itemCount: itemsList.length,
          itemBuilder: (context, index) {
            final item = itemsList[index];
            return _buildItemGridCard(context, item);
          },
        ),
      ),
    );
  }

  Widget _buildItemGridCard(BuildContext context, Map<String, dynamic> item) {
    return InkWell(
      onTap: () => _showItemDetailsDialog(item['name'], item['image']),
      child: Card(
        color: _cardColor, // White card background
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
                  child: Image.asset(
                    item['image'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 50),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['name']!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Black text for contrast
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Specific Form Widgets (Themed) ---

class _MembershipExpenseForm extends StatefulWidget {
  final FirestoreService firestoreService;
  const _MembershipExpenseForm({required this.firestoreService});

  @override
  State<_MembershipExpenseForm> createState() => _MembershipExpenseFormState();
}

class _MembershipExpenseFormState extends State<_MembershipExpenseForm> {
  final List<String> _membershipTypes = [
    'Gym',
    'Library',
    'Streaming Service',
    'Club',
    'Magazine',
    'Other',
  ];
  String? _selectedMembership;
  final TextEditingController _amountController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // Helper method for consistent text field styling in form cards
  InputDecoration _buildInputDecoration(String label, {String? prefixText}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      filled: true,
      fillColor: Colors.white,
      prefixText: prefixText,
      prefixStyle: const TextStyle(color: Colors.black),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _primaryColor, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Log a new Membership Expense',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          value: _selectedMembership,
          decoration: _buildInputDecoration('Select Membership'),
          items: _membershipTypes
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: (val) {
            setState(() {
              _selectedMembership = val;
            });
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.black),
          decoration: _buildInputDecoration(
            'Membership Amount',
            prefixText: '₹',
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _isSaving
              ? null
              : () async {
                  final amount = double.tryParse(_amountController.text);
                  if (_selectedMembership == null ||
                      amount == null ||
                      amount <= 0) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please select a membership and enter a valid amount.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _isSaving = true;
                  });
                  try {
                    await widget.firestoreService.addTransaction(
                      description: 'Membership: $_selectedMembership',
                      category: 'Memberships',
                      amount: amount,
                    );
                    if (mounted) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Membership expense saved!'),
                        ),
                      );
                      _amountController.clear();
                      setState(() {
                        _selectedMembership = null;
                      });
                    }
                  } catch (e) {
                    if (mounted) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save: $e'),
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
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor, // Deep Teal Button
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          ),
          child: _isSaving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Add Membership Expense',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}

class _BillPaymentForm extends StatefulWidget {
  final FirestoreService firestoreService;
  const _BillPaymentForm({required this.firestoreService});

  @override
  State<_BillPaymentForm> createState() => _BillPaymentFormState();
}

class _BillPaymentFormState extends State<_BillPaymentForm> {
  final List<String> _billTypes = [
    'Electricity',
    'Water',
    'Phone',
    'Internet',
    'Rent',
  ];
  String? _selectedBillType;
  final TextEditingController _billAmountController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _billAmountController.dispose();
    super.dispose();
  }

  // Helper method for consistent text field styling in form cards
  InputDecoration _buildInputDecoration(String label, {String? prefixText}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      filled: true,
      fillColor: Colors.white,
      prefixText: prefixText,
      prefixStyle: const TextStyle(color: Colors.black),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _primaryColor, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Log a new Bill Payment',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          value: _selectedBillType,
          decoration: _buildInputDecoration('Select Bill Type'),
          items: _billTypes
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: (val) {
            setState(() {
              _selectedBillType = val;
            });
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _billAmountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.black),
          decoration: _buildInputDecoration('Bill Amount', prefixText: '₹'),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _isSaving
              ? null
              : () async {
                  final billAmount = double.tryParse(
                    _billAmountController.text,
                  );
                  if (_selectedBillType == null ||
                      billAmount == null ||
                      billAmount <= 0) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enter a valid bill amount and select a bill type.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _isSaving = true;
                  });
                  try {
                    await widget.firestoreService.addTransaction(
                      description: 'Bill Payment: $_selectedBillType',
                      category: 'Bill Payments',
                      amount: billAmount,
                    );
                    if (mounted) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bill payment saved!')),
                      );
                      _billAmountController.clear();
                      setState(() {
                        _selectedBillType = null;
                      });
                    }
                  } catch (e) {
                    if (mounted) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save: $e'),
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
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor, // Deep Teal Button
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          ),
          child: _isSaving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Add Bill Payment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}

class _MedicalExpenseForm extends StatefulWidget {
  final FirestoreService firestoreService;
  const _MedicalExpenseForm({required this.firestoreService});

  @override
  State<_MedicalExpenseForm> createState() => _MedicalExpenseFormState();
}

class _MedicalExpenseFormState extends State<_MedicalExpenseForm> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _hospitalController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  // Helper method for consistent text field styling in form cards
  InputDecoration _buildInputDecoration(String label, {String? prefixText}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      filled: true,
      fillColor: Colors.white,
      prefixText: prefixText,
      prefixStyle: const TextStyle(color: Colors.black),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _primaryColor, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Log a new Medical Expense',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.black),
          decoration: _buildInputDecoration('Bill Amount', prefixText: '₹'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _hospitalController,
          style: const TextStyle(color: Colors.black),
          decoration: _buildInputDecoration('Hospital/Clinic'),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _isSaving
              ? null
              : () async {
                  final amount = double.tryParse(_amountController.text);
                  final hospital = _hospitalController.text.trim();
                  if (amount == null || amount <= 0 || hospital.isEmpty) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter valid details.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _isSaving = true;
                  });
                  try {
                    await widget.firestoreService.addTransaction(
                      description: 'Medical Bill: $hospital',
                      category: 'Medicines',
                      amount: amount,
                    );
                    if (mounted) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Medical expense saved!')),
                      );
                      _amountController.clear();
                      _hospitalController.clear();
                    }
                  } catch (e) {
                    if (mounted) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save: $e'),
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
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor, // Deep Teal Button
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          ),
          child: _isSaving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Add Medical Expense',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}
