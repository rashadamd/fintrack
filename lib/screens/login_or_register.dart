import 'package:flutter/material.dart';
import 'package:fintrack/screens/login_screen.dart';
import 'package:fintrack/screens/register_screen.dart';

class LoginOrRegisterScreen extends StatefulWidget {
  const LoginOrRegisterScreen({super.key});

  @override
  State<LoginOrRegisterScreen> createState() => _LoginOrRegisterScreenState();
}

class _LoginOrRegisterScreenState extends State<LoginOrRegisterScreen> {
  // Initially, show the login screen
  bool showLoginScreen = true;

  void toggleScreens() {
    setState(() {
      showLoginScreen = !showLoginScreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginScreen) {
      return LoginScreen(onNavigateToRegister: toggleScreens);
    } else {
      return RegisterScreen(onNavigateToLogin: toggleScreens);
    }
  }
}