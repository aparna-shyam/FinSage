import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'spending_report_page.dart';
import 'notifications_page.dart';
import 'financial_setup_page.dart';

// Updated color constants to match dashboard_page.dart
const Color _primaryColor = Color(0xFF008080); // Deep Teal
const Color _secondaryColor = Color(0xFFB76E79); // Rose Gold
const Color _gradientStartColor = Color(0xFF2C3E50); // Dark Blue-Purple
const Color _gradientEndColor = Color(0xFF4CA1AF); // Lighter Blue-Teal
const Color _cardColor = Color(0xFFFFFFFF); // Pure White

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  final List<String> _avatarPaths = [
    'assets/avatars/avatar1.jpeg',
    'assets/avatars/avatar2.jpeg',
    'assets/avatars/avatar3.jpeg',
    'assets/avatars/avatar4.jpeg',
    'assets/avatars/avatar5.jpeg',
    'assets/avatars/avatar6.jpeg',
  ];

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _fetchUserProfileData();
  }

  Future<void> _fetchUserProfileData() async {
    if (_user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .get();
        if (userDoc.exists) {
          if (mounted) {
            setState(() {
              _userData = userDoc.data() as Map<String, dynamic>;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) setState(() => _isLoading = false);
        }
      } catch (e) {
        debugPrint('Error fetching user data: $e');
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      debugPrint('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to sign out. Please try again.')),
      );
    }
  }

  Future<void> _updateProfilePicture(String url) async {
    if (mounted) setState(() => _isLoading = true);

    try {
      if (_user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({'profilePictureUrl': url});
        if (mounted) _userData?['profilePictureUrl'] = url;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating profile picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile picture.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAvatarSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a Profile Picture'),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _avatarPaths.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _updateProfilePicture(_avatarPaths[index]);
                    Navigator.of(context).pop();
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage(_avatarPaths[index]),
                  ),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateSuggestionsPreference(bool value) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({'receiveSuggestions': value});
      if (mounted) _userData?['receiveSuggestions'] = value;
    } catch (e) {
      debugPrint('Error updating preference: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSettingsDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: const Text('Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Receive Financial Suggestions'),
                    value: _userData?['receiveSuggestions'] ?? false,
                    activeColor: _primaryColor,
                    onChanged: (bool value) {
                      setStateInDialog(
                        () => _userData?['receiveSuggestions'] = value,
                      );
                      _updateSuggestionsPreference(value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Theme Mode (Dark/Light)'),
                    value: themeProvider.themeMode == ThemeMode.dark,
                    activeColor: _primaryColor,
                    onChanged: (bool value) => themeProvider.toggleTheme(),
                  ),
                  ListTile(
                    title: const Text('Change Password'),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: _primaryColor,
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(context, '/change-password');
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Close', style: TextStyle(color: _primaryColor)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _viewSpendingReport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SpendingReportPage()),
    );
  }

  void _viewNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsPage()),
    );
  }

  void _openFinancialSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FinancialSetupPage()),
    ).then((_) {
      _fetchUserProfileData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: _primaryColor,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradientStartColor, _gradientEndColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Picture Section
                    GestureDetector(
                      onTap: _showAvatarSelectionDialog,
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[200],
                                backgroundImage:
                                    _userData?['profilePictureUrl'] != null &&
                                        _userData!['profilePictureUrl']
                                            .startsWith('assets/')
                                    ? AssetImage(
                                            _userData!['profilePictureUrl'],
                                          )
                                          as ImageProvider
                                    : (_userData?['profilePictureUrl'] != null
                                          ? NetworkImage(
                                              _userData!['profilePictureUrl'],
                                            )
                                          : null),
                                child: _userData?['profilePictureUrl'] == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 70,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _secondaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // User Info Card
                    Card(
                      color: _cardColor,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              Icons.person,
                              'Name',
                              _userData?['name'] ?? 'N/A',
                            ),
                            const Divider(height: 20),
                            _buildInfoRow(
                              Icons.email,
                              'Email',
                              _user?.email ?? 'N/A',
                            ),
                            const Divider(height: 20),
                            _buildInfoRow(
                              Icons.notifications_active,
                              'Suggestions',
                              _userData?['receiveSuggestions'] == true
                                  ? 'On'
                                  : 'Off',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons
                    _buildActionButton(
                      icon: Icons.account_balance_wallet,
                      label: 'Set Income & Savings Goal',
                      color: _primaryColor,
                      onPressed: _openFinancialSetup,
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      icon: Icons.bar_chart,
                      label: 'View Spending Report',
                      color: _primaryColor,
                      onPressed: _viewSpendingReport,
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      icon: Icons.logout,
                      label: 'Sign Out',
                      color: Colors.red[700]!,
                      onPressed: _signOut,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: _primaryColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
    );
  }
}
