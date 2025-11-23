import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_page.dart';

// Define the Primary/Accent color: Deep Teal
const Color _primaryColor = Color(0xFF008080);
// Define the Secondary color: Rose Gold
const Color _secondaryColor = Color(0xFFB76E79);
// Gradient colors from insights_page.dart
const Color _gradientStartColor = Color(0xFF2C3E50); // Dark Blue-Purple
const Color _gradientEndColor = Color(0xFF4CA1AF); // Lighter Blue-Teal
const Color _cardColor = Color(0xFFFFFFFF); // Pure White

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<bool> _reauthenticate(String currentPassword) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return false;
    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);
      return true;
    } on FirebaseAuthException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _changePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No user logged in.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _loading = false);
      return;
    }

    final currentPass = _currentPasswordController.text.trim();
    final newPass = _passwordController.text.trim();

    try {
      await user.updatePassword(newPass);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        final reauthOk = await _reauthenticate(currentPass);
        if (!reauthOk) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reauthentication failed. Enter current password.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _loading = false);
          return;
        }
        await user.updatePassword(newPass);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Failed to update password.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _loading = false);
        return;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      setState(() => _loading = false);
      return;
    }

    // If successful, show dialog
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text(
          'Password updated successfully. Use the new password next time you sign in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: _primaryColor)),
          ),
        ],
      ),
    );

    // Navigate to Dashboard and clear stack
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardPage()),
      (route) => false,
    );
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Required for gradient body
      appBar: AppBar(
        title: const Text(
          'Change Password',
          style: TextStyle(color: Colors.white), // White title text
        ),
        backgroundColor: _primaryColor, // Deep Teal AppBar
        elevation: 0, // Remove shadow for a flatter look
        iconTheme: const IconThemeData(color: Colors.white), // White back arrow
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Apply the same gradient background as the InsightsPage
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradientStartColor, _gradientEndColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            // Card for content to contrast with gradient
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                color: _cardColor, // White card background
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title/Description
                        const Text(
                          'Update your password securely.',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You must enter your current password for verification.',
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        // Current Password Field
                        _buildThemedTextFormField(
                          controller: _currentPasswordController,
                          labelText: 'Current Password',
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Enter current password'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        // New Password Field
                        _buildThemedTextFormField(
                          controller: _passwordController,
                          labelText: 'New Password (min 6 characters)',
                          validator: (v) {
                            if (v == null || v.length < 6)
                              return 'Password must be at least 6 characters long';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Confirm New Password Field
                        _buildThemedTextFormField(
                          controller: _confirmPasswordController,
                          labelText: 'Confirm New Password',
                          validator: (v) => (v != _passwordController.text)
                              ? 'Passwords do not match'
                              : null,
                        ),
                        const SizedBox(height: 32),
                        // Update Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _secondaryColor, // Rose Gold button
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 4,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Update Password',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to apply consistent styling to text fields
  Widget _buildThemedTextFormField({
    required TextEditingController controller,
    required String labelText,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: _primaryColor), // Deep Teal label
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: _primaryColor,
        ), // Deep Teal icon
        fillColor: Colors.grey.shade50, // Slightly off-white background
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primaryColor.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primaryColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: _secondaryColor,
            width: 2.0,
          ), // Rose Gold focus border
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2.0),
        ),
      ),
      obscureText: true,
      validator: validator,
    );
  }
}
