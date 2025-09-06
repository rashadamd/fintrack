import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryAccent = Color(0xFF00BFA5);
    const Color darkBackground = Color(0xFF1C1C23);

    return Scaffold(
      backgroundColor: darkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.track_changes_rounded,
              size: 100,
              color: primaryAccent,
            ),
            const SizedBox(height: 20),
            Text(
              'FinTrack',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}