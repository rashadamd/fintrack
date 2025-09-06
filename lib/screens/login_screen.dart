import 'package:flutter/material.dart';
import 'package:fintrack/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onNavigateToRegister;
  const LoginScreen({super.key, required this.onNavigateToRegister});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  void _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isNotEmpty && password.isNotEmpty) {
      showDialog(context: context, builder: (context) => const Center(child: CircularProgressIndicator()));

      final userCredential = await _authService.signInWithEmailAndPassword(email, password);

      Navigator.of(context).pop();

      if (userCredential == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed. Please check your credentials.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryAccent = Color(0xFF00BFA5);
    const Color darkBackground = Color(0xFF1C1C23);
    const Color inputBackground = Color(0xFF2A2A35);
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
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Log in to your account to continue.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 48),

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

                // Login Button
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),

                // Navigate to Register
                TextButton(
                  onPressed: widget.onNavigateToRegister,
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      children: const <TextSpan>[
                        TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Register',
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

  // Helper method to create styled InputDecoration for TextFormFields
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