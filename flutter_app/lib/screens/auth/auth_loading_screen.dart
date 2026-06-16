// lib/screens/auth/auth_loading_screen.dart

import 'package:flutter/material.dart';
import '../../theme/palette.dart';
import '../../theme/app_text_styles.dart';

class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/SWK_home.png', height: 180),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Palette.sky),
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'กำลังโหลด...',
              style: AppTextStyles.body(18,
                  color: Palette.sky, weight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'กรุณารอสักครู่',
              style: AppTextStyles.body(14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
