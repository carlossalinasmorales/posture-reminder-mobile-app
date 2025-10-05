import 'package:flutter/material.dart';
import '../../../../theme/app_styles.dart';

class TextFieldCustom extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const TextFieldCustom({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: kBodyTextStyle,
      decoration: kTextFieldDecoration.copyWith(
        labelText: label,
        prefixIcon: Icon(icon, color: kPrimaryColor),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}
