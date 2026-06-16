import 'package:flutter/material.dart';

class SWKTextField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final Widget? suffix;

  const SWKTextField({
    super.key,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.onChanged,
    this.obscureText = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      obscureText: obscureText,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white, // ✅ ใช้สีพื้นขาวมาตรฐาน
        hintText: hint,
        hintStyle: const TextStyle(
          color: Colors.black54,
          fontWeight: FontWeight.w600,
        ),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
