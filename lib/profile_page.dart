import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'spending_report_page.dart'; // Import the spending report page
import 'notifications_page.dart'; // Import the notifications page
import 'financial_setup_page.dart'; // Import the new Financial Setup page

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
          const SnackBar(content: Text('Profile picture updated successfully!')),
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
                    onChanged: (bool value) {
                      setStateInDialog(() => _userData?['receiveSuggestions'] = value);
                      _updateSuggestionsPreference(value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Theme Mode (Dark/Light)'),
                    value: themeProvider.themeMode == ThemeMode.dark,
                    onChanged: (bool value) => themeProvider.toggleTheme(),
                  ),
                  ListTile(
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.arrow_forward_ios),
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
                  child: const Text('Close'),
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
      _fetchUserProfileData(); // Refresh after setup
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF6B5B95),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: _showSettingsDialog),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: _showAvatarSelectionDialog,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _userData?['profilePictureUrl'] != null &&
                                    _userData!['profilePictureUrl'].startsWith('assets/')
                                ? AssetImage(_userData!['profilePictureUrl']) as ImageProvider
                                : (_userData?['profilePictureUrl'] != null
                                    ? NetworkImage(_userData!['profilePictureUrl'])
                                    : null),
                            child: _userData?['profilePictureUrl'] == null
                                ? const Icon(Icons.person, size: 70, color: Colors.grey)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B5B95),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(Icons.edit, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Name: ${_userData?['name'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Email: ${_user?.email ?? 'N/A'}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Suggestions: ${_userData?['receiveSuggestions'] == true ? 'On' : 'Off'}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),

                  // Button for financial setup
                  ElevatedButton.icon(
                    onPressed: _openFinancialSetup,
                    icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
                    label: const Text(
                      'Set Income & Savings Goal',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B5B95),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: _viewSpendingReport,
                    icon: const Icon(Icons.bar_chart, color: Colors.white),
                    label: const Text('View Spending Report', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B5B95),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: _viewNotifications,
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    label: const Text('Notifications', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B5B95),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text('Sign Out', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
