import 'package:flutter/material.dart';
import 'package:fintrack/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onNavigateToLogin;
  const RegisterScreen({super.key, required this.onNavigateToLogin});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  void _register() async {
    final name = _nameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;

    if (name.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
      showDialog(context: context, builder: (context) => const Center(child: CircularProgressIndicator()));

      final userCredential = await _authService.signUpWithEmailAndPassword(email, password, name);

      Navigator.of(context).pop();

      if (userCredential == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration failed. The email might already be in use.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryAccent = Color(0xFF00BFA5);
    const Color darkBackground = Color(0xFF1C1C23);
    const Color primaryText = Color(0xFFEAEAEB);

    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.track_changes_rounded, size: 80, color: primaryAccent),
                const SizedBox(height: 32),
                Text(
                  'Create Your Account',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Get started with FinTrack today!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 48),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: primaryText),
                  decoration: _buildInputDecoration(label: 'Name', icon: Icons.person_rounded),
                ),
                const SizedBox(height: 20),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: primaryText),
                  decoration: _buildInputDecoration(label: 'Email', icon: Icons.email_rounded),
                ),
                const SizedBox(height: 20),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: primaryText),
                  decoration: _buildInputDecoration(label: 'Password', icon: Icons.lock_rounded),
                ),
                const SizedBox(height: 32),

                // Register Button
                ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),

                // Navigate to Login
                TextButton(
                  onPressed: widget.onNavigateToLogin,
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      children: const <TextSpan>[
                        TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Login',
                          style: TextStyle(
                            color: primaryAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String label, required IconData icon}) {
    const Color inputBackground = Color(0xFF2A2A35);
    const Color primaryText = Color(0xFFEAEAEB);
    const Color primaryAccent = Color(0xFF00BFA5);

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[400]),
      prefixIcon: Icon(icon, color: Colors.grey[400]),
      filled: true,
      fillColor: inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryAccent),
      ),
    );
  }
}