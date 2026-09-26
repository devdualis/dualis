import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Shown at startup while [AuthController.restoreSession] runs.
///
/// Displays the full Dualis brand logo (vertical variant with tagline) and a
/// [CircularProgressIndicator] beneath it. The GoRouter redirect keeps the app
/// here as long as [AuthState.isLoading] is true, then routes to /home or
/// /onboarding once the session check resolves.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.brandBgWhite,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image(
              image: AssetImage('lib/assets/brand/dualis_logo_vertical.png'),
              width: 200,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              color: AppColors.clinicalTeal,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
