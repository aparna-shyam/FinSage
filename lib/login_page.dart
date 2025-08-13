import 'package:flutter/material.dart';
import 'forgotpass.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF9BCD9B),
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                obscureText: true,
              ),

              // Forgot Password link (centered)
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ForgotPassPage()),
                    );
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Color(0xFF9BCD9B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Logging in...')));
                  }
                },
                child: Text('Login', style: TextStyle(fontSize: 18)),
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
