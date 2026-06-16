import 'package:flutter/material.dart';
import '../theme/palette.dart';
import '../theme/app_text_styles.dart';

/// Sticky bottom button container used across activity screens.
/// Sits at the bottom of a Column, above the safe area.
class StickyBottomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final Color? color;
  final bool isLoading;

  const StickyBottomButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Palette.cream,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color ?? Palette.sky,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: AppTextStyles.heading(20, color: Colors.white),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
