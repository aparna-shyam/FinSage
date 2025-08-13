import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Checkbox state
  bool _receiveSuggestions = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF9BCD9B),
        title: const Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Name',
                keyboardType: TextInputType.name,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _ageController,
                label: 'Age',
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                obscureText: true,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                obscureText: true,
              ),
              SizedBox(height: 16),

              // New Checkbox option
              CheckboxListTile(
                title: Text(
                  'Would you like to receive suggestions on managing your finances properly?',
                  style: TextStyle(fontSize: 14),
                ),
                value: _receiveSuggestions,
                activeColor: Color(0xFF9BCD9B),
                onChanged: (bool? value) {
                  setState(() {
                    _receiveSuggestions = value ?? false;
                  });
                },
              ),

              SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF9BCD9B),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _receiveSuggestions
                              ? 'Processing Sign Up with suggestions enabled...'
                              : 'Processing Sign Up...',
                        ),
                      ),
                    );
                  }
                },
                child: Text('Sign Up', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (label == 'Confirm Password' && value != _passwordController.text) {
          return 'Passwords do not match';
        }
        if (label == 'Age') {
          final ageNum = int.tryParse(value);
          if (ageNum == null || ageNum <= 0) {
            return 'Please enter a valid age';
          }
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
