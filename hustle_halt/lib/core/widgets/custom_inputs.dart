import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: color ?? AppTheme.textPrimary,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textPrimary),
              )
            : Text(text),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppTheme.accent,
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
            )
          : Text(text),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final bool obscureText;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
      ),
    );
  }
}
